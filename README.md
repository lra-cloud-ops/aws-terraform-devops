# AWS Terraform DevOps

Infraestructura AWS de estilo productivo, provisionada con Terraform, ejecutando una aplicación Flask contenedorizada en Amazon EKS con RDS PostgreSQL, automatización CI/CD completa y observabilidad con Prometheus/Grafana.

[![CI/CD](https://github.com/lra-cloud-ops/aws-terraform-devops/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/lra-cloud-ops/aws-terraform-devops/actions/workflows/ci-cd.yml)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=Liquenson_aws-terraform-devops-lab&metric=alert_status)](https://sonarcloud.io/dashboard?id=Liquenson_aws-terraform-devops-lab)
[![Terraform](https://img.shields.io/badge/Terraform-1.9.8-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20VPC-FF9900?logo=amazonaws)](https://aws.amazon.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Resumen

Este repositorio provisiona un entorno AWS completo mediante Infrastructure as Code y despliega una aplicación de ejemplo a través de un pipeline automatizado. Sirve como implementación de referencia para equipos que estandarizan sobre Terraform + EKS + GitHub Actions.

**Capacidades principales:**

| Área | Implementación |
|---|---|
| Aprovisionamiento | Terraform, diseño modular, state remoto en S3 con locking en DynamoDB |
| Cómputo | Amazon EKS, node groups gestionados, HPA (2–10 pods) |
| Datos | Amazon RDS PostgreSQL, encriptación en reposo |
| Registro | Amazon ECR |
| Redes | VPC en 3 AZs, segregación de subnets públicas/privadas |
| CI/CD | GitHub Actions, autenticación AWS vía OIDC |
| Calidad de código | SonarCloud, quality gate obligatorio |
| Observabilidad | Prometheus, Grafana |

---

## Arquitectura

```
Internet → Load Balancer → Cluster EKS
                                │
                          Flask App (2–10 pods, HPA)
                                │
                          RDS PostgreSQL
```

- VPC con subnets públicas y privadas en 3 zonas de disponibilidad (`eu-west-1a/b/c`)
- EKS v1.31, node group gestionado con auto-scaling de 1 a 4 nodos (`t3.small`)
- RDS PostgreSQL 15, instancia `db.t3.micro`, almacenamiento gp3
- ECR para imágenes de contenedores privadas, con lifecycle policy (retiene últimas 10 imágenes)
- S3 + DynamoDB para state remoto y locking de Terraform
- CloudWatch para logs y métricas centralizadas (log group EKS, alarmas de CPU/memoria)

---

## Requisitos

| Herramienta | Versión |
|---|---|
| Terraform | 1.9.8+ |
| AWS CLI | 2.x |
| kubectl | 1.31+ |
| Docker | 24.x+ |
| Python | 3.11+ |

Las credenciales de AWS deben estar configuradas localmente (`aws configure`) con permisos IAM suficientes para provisionar VPC, EKS, RDS, ECR, IAM y CloudWatch.

---

## Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/lra-cloud-ops/aws-terraform-devops.git
cd aws-terraform-devops

# 2. Configurar credenciales AWS
aws configure

# 3. Aprovisionar el backend de Terraform
aws s3api create-bucket \
  --bucket devops-lab-tfstate-522921482434 \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

aws dynamodb create-table \
  --table-name devops-lab-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1

# 4. Aprovisionar infraestructura
cd terraform/
export TF_VAR_db_password="<contraseña-segura>"
terraform init
terraform plan -var-file=../environments/dev/terraform.tfvars
terraform apply -var-file=../environments/dev/terraform.tfvars

# 5. Configurar acceso al cluster
aws eks update-kubeconfig --region eu-west-1 --name dev-cluster
kubectl get nodes
```

---

## Estructura del Repositorio

```
aws-terraform-devops/
├── terraform/               # Módulo raíz: orquestación, backend, variables, outputs
├── environments/            # Variables por entorno (dev, prod)
├── modules/                 # Módulos Terraform reutilizables
│   ├── vpc/
│   ├── eks/
│   ├── rds/
│   ├── ecr/
│   ├── iam/
│   ├── cloudwatch/
│   └── s3_bucket/
├── docker/                  # Aplicación Flask
│   ├── Dockerfile            # Build multi-stage
│   └── src/app.py            # API REST (3 endpoints)
├── kubernetes/               # Manifiestos de Kubernetes
│   ├── deployment.yaml        # RollingUpdate, 2 réplicas
│   ├── service.yaml            # LoadBalancer
│   └── hpa.yaml                  # Auto-scaling 2–10 pods
├── monitoring/               # Scripts de instalación Prometheus/Grafana
└── .github/workflows/
    └── ci-cd.yml             # Definición del pipeline
```

---

## Pipeline CI/CD

Cada push a `main` ejecuta:

```
1. Análisis SonarCloud       – tests unitarios, cobertura, escaneo de vulnerabilidades
2. Terraform validate/plan  – fmt, validate, plan
3. Build de Docker            – multi-stage, imagen mínima
4. Push a ECR
5. Deploy a EKS                – disparado solo por tags (v*)
```

**Quality gates aplicados:**

- Cobertura de tests > 80%
- Cero vulnerabilidades críticas
- `terraform plan` exitoso
- Build de Docker exitoso

> El pipeline ejecuta `terraform plan`, no `apply` — el despliegue real de infraestructura se realiza manualmente.

### Autenticación con AWS

El pipeline se autentica contra AWS vía **OIDC**, sin credenciales de larga duración:

- Proveedor de identidad: `token.actions.githubusercontent.com`
- Rol: `github-actions-terraform-devops`
- Trust policy acotada a `repo:lra-cloud-ops/aws-terraform-devops:*`

**Secrets requeridos en GitHub:**

```
SONAR_TOKEN
TF_VAR_DB_PASSWORD
```

`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` no se utilizan — el acceso se concede en tiempo de ejecución vía `role-to-assume`.

---

## Aplicación

API REST Flask mínima:

| Endpoint | Método | Descripción |
|---|---|---|
| `/` | GET | Metadatos de la aplicación |
| `/health` | GET | Liveness probe |
| `/ready` | GET | Readiness probe |

```json
{
  "name": "DevOps Lab API",
  "version": "1.0.0",
  "aws_region": "eu-west-1",
  "status": "running"
}
```

---

## Seguridad

| Capa | Control |
|---|---|
| Red | Subnets privadas, security groups restrictivos (PostgreSQL 5432 solo dentro de VPC) |
| IAM | Principio de mínimo privilegio, roles dedicados para cluster y nodos EKS |
| Secrets | GitHub Secrets — sin credenciales hardcodeadas |
| Auth CI/CD | Federación OIDC, sin access keys estáticas |
| Contenedores | Usuario no-root, imagen base mínima |
| Datos | Encriptación en reposo (S3 con AES256, RDS) |
| Almacenamiento | Bucket S3 con versionado y bloqueo de acceso público |
| Análisis estático | SonarCloud, Security Rating A |

---

## Observabilidad

```bash
cd monitoring/
./install.sh

kubectl port-forward svc/prometheus-server 9090:9090 -n monitoring
kubectl port-forward svc/grafana 3000:3000 -n monitoring   # admin/admin
```

Métricas: CPU/memoria de pods y nodos (alarmas CloudWatch en 80%/85%), request rate, latencia de endpoints, estado de health checks.

---

## Roadmap

- [x] Infraestructura AWS completa vía Terraform
- [x] CI/CD con GitHub Actions
- [x] Observabilidad con Prometheus/Grafana
- [x] Auto-scaling configurado
- [x] Autenticación OIDC en el pipeline
- [ ] ArgoCD (GitOps)
- [ ] Helm charts endurecidos y publicados
- [ ] Módulos Terraform públicos
- [ ] Despliegue multi-región

---

## Autor

**[Ruben Liquenson](https://www.linkedin.com/in/ruben-liquenson-490961269/)**
DevOps Engineer | Cloud Engineer | AWS | Kubernetes | Terraform | GitOps

- Email: liquenson.cloud@gmail.com
- LinkedIn: [ruben-liquenson](https://www.linkedin.com/in/ruben-liquenson-490961269/)
- GitHub: [@Liquenson](https://github.com/Liquenson)
- Web: [lracloudops.com](https://lracloudops.com/es/)
- Las Palmas de Gran Canaria, Canarias, España

## Licencia

MIT — ver [LICENSE](LICENSE).