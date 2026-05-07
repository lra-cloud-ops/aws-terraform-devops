# ☁️ AWS Terraform DevOps Lab

> Infraestructura AWS completa con Terraform, EKS, RDS y CI/CD automatizado

[![CI/CD](https://github.com/Liquenson/aws-terraform-devops/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/Liquenson/aws-terraform-devops/actions/workflows/ci-cd.yml)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=Liquenson_aws-terraform-devops&metric=alert_status)](https://sonarcloud.io/dashboard?id=Liquenson_aws-terraform-devops)
[![Terraform](https://img.shields.io/badge/Terraform-1.9.8-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20VPC-FF9900?logo=amazonaws)](https://aws.amazon.com/)

**Infraestructura AWS de producción completa** desplegada con Terraform, ejecutando una aplicación Python/Flask en Kubernetes (EKS) con base de datos MySQL, CI/CD automático y monitoreo con Prometheus/Grafana.

**En resumen:** Todo lo que necesitas para desplegar una aplicación web escalable en AWS usando Infrastructure as Code.

## ⚡ Arquitectura

Internet → Load Balancer → EKS Cluster (Kubernetes)
↓
Flask App (2-10 pods)
↓
RDS MySQL (Multi-AZ)

**Componentes principales:**
- ✅ **VPC** con subnets públicas/privadas en 3 zonas de disponibilidad
- ✅ **EKS** cluster Kubernetes v1.29 con auto-scaling (1-4 nodos)
- ✅ **RDS MySQL** Multi-AZ con failover automático
- ✅ **ECR** registro privado de imágenes Docker
- ✅ **S3 + DynamoDB** para estado remoto de Terraform
- ✅ **CloudWatch** para logs y métricas

## 🚀 Inicio Rápido

### Requisitos
```bash
# Herramientas necesarias
- Terraform 1.9.8+
- AWS CLI 2.x
- kubectl 1.29+
- Docker 24.x+
- Python 3.11+
```

### Despliegue en 5 pasos

```bash
# 1. Clonar repositorio
git clone https://github.com/Liquenson/aws-terraform-devops.git
cd aws-terraform-devops

# 2. Configurar AWS
aws configure

# 3. Crear backend S3 + DynamoDB
aws s3api create-bucket \
  --bucket tfstate-devops-lab-rliquenson-euw1 \
  --region eu-west-1 \
  --create-bucket-configuration LocationConstraint=eu-west-1

aws dynamodb create-table \
  --table-name devops-lab-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1

# 4. Desplegar infraestructura
cd terraform/
terraform init
terraform plan
terraform apply -auto-approve

# 5. Conectar a EKS
aws eks update-kubeconfig --region eu-west-1 --name dev-cluster
kubectl get nodes
```

## 📊 Stack Tecnológico

### Infraestructura
| Componente | Versión | Uso |
|-----------|---------|-----|
| Terraform | 1.9.8 | Infrastructure as Code |
| AWS VPC | - | Networking (10.0.0.0/16) |
| AWS EKS | 1.29 | Kubernetes gestionado |
| AWS RDS | MySQL | Base de datos Multi-AZ |
| AWS ECR | - | Registro Docker privado |

### Aplicación
| Componente | Versión | Uso |
|-----------|---------|-----|
| Python | 3.11 | Lenguaje de la app |
| Flask | - | Framework web |
| Gunicorn | - | Servidor WSGI |
| Docker | - | Contenedorización |

### DevOps
| Herramienta | Uso |
|------------|-----|
| GitHub Actions | Pipeline CI/CD |
| SonarCloud | Análisis de código |
| Prometheus | Métricas |
| Grafana | Dashboards |

## 🏗️ Estructura del Proyecto

aws-terraform-devops/
├── terraform/              # Configuración Terraform
│   ├── main.tf            # Orquestación de módulos
│   ├── variables.tf       # Variables de entrada
│   └── outputs.tf         # Outputs de infraestructura
│
├── modules/               # Módulos Terraform reutilizables
│   ├── vpc/              # Red virtual
│   ├── eks/              # Cluster Kubernetes
│   ├── rds/              # Base de datos
│   ├── ecr/              # Registro Docker
│   ├── iam/              # Roles y políticas
│   └── cloudwatch/       # Monitoreo
│
├── docker/               # Aplicación Flask
│   ├── Dockerfile        # Multi-stage build
│   └── src/
│       └── app.py        # API REST (3 endpoints)
│
├── kubernetes/           # Manifiestos K8s
│   ├── deployment.yaml   # 2 réplicas + RollingUpdate
│   ├── service.yaml      # LoadBalancer
│   └── hpa.yaml         # Auto-scaling 2-10 pods
│
└── .github/workflows/
└── ci-cd.yml         # Pipeline automatizado

## 🔄 Pipeline CI/CD

Cada push a `main` ejecuta automáticamente:

GitHub Push
↓
┌─────────────────────────────┐
│ 1. Análisis SonarCloud      │ ← Tests + Cobertura + Vulnerabilidades
│ 2. Terraform Validate       │ ← fmt + validate + plan
│ 3. Build Docker             │ ← Multi-stage optimizado
│ 4. Push a ECR               │ ← Registro privado AWS
│ 5. Deploy a EKS (tags)      │ ← Solo con tags v*
└─────────────────────────────┘

**Quality Gates:**
- ✅ Cobertura de tests > 80%
- ✅ Zero vulnerabilidades críticas
- ✅ Terraform plan exitoso
- ✅ Docker build exitoso

## 📱 Aplicación Flask

API REST simple con 3 endpoints:

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/` | GET | Info de la aplicación |
| `/health` | GET | Liveness probe |
| `/ready` | GET | Readiness probe |

**Ejemplo de respuesta:**
```json
{
  "name": "DevOps Lab API",
  "version": "1.0.0",
  "aws_region": "eu-west-1",
  "status": "running"
}
```

## 🔒 Seguridad

### Implementado
✅ **Network** - Subnets privadas, Security Groups restrictivos  
✅ **IAM** - Principio de mínimo privilegio  
✅ **Secrets** - GitHub Secrets (no hardcoded)  
✅ **Containers** - Usuario no-root, imagen minimal  
✅ **Data** - Encriptación en reposo (S3, RDS)  
✅ **Code** - SonarCloud Security Rating A  

### Secretos necesarios (GitHub)

AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
SONAR_TOKEN

## 📈 Monitoreo

### Stack Prometheus + Grafana

```bash
# Instalar stack de monitoreo
cd monitoring/
./install.sh

# Acceder a Prometheus
kubectl port-forward svc/prometheus-server 9090:9090 -n monitoring

# Acceder a Grafana (admin/admin)
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

**Métricas disponibles:**
- CPU/Memoria de pods y nodos
- Request rate de la aplicación
- Latencia de endpoints
- Estado de health checks

## 🎯 Casos de Uso

### Para DevOps Engineers
```bash
# Demostrar IaC con Terraform
# Desplegar app en Kubernetes
# Implementar CI/CD completo
# Configurar auto-scaling
```

### Para Arquitectos Cloud
```bash
# Diseño multi-AZ con alta disponibilidad
# Seguridad por capas (network, IAM, data)
# Monitoreo centralizado
# Disaster recovery con RDS Multi-AZ
```

### Para Equipos de Desarrollo
```bash
# Entorno de desarrollo reproducible
# Pipeline CI/CD automático
# Logs centralizados
# Métricas en tiempo real
```

## 📖 Documentación Adicional

- **Terraform Modules** - Ver `modules/*/README.md`
- **Deployment Guide** - Ver `docs/deployment.md`
- **Troubleshooting** - Ver `docs/troubleshooting.md`

## 🚀 Roadmap

### v1.0.0 (Actual)
- ✅ Infraestructura completa en AWS
- ✅ CI/CD con GitHub Actions
- ✅ Monitoreo con Prometheus/Grafana
- ✅ Auto-scaling configurado

### v2.0.0 (Próximo)
- 🚧 ArgoCD para GitOps
- 🚧 Helm charts mejorados
- 🚧 Terraform modules públicos
- 🚧 Multi-región deployment

## 👨‍💻 Autor

**Liquenson Ruben Alexis**  
*DevOps Engineer | AWS | Terraform | Kubernetes*

- 📧 liquenson.cloud@gmail.com
- 💼 [LinkedIn](https://www.linkedin.com/in/liquenson-ruben-490961269/)
- 🐙 [GitHub](https://github.com/Liquenson)
- 📍 Las Palmas de Gran Canaria, España

## 📄 Licencia

MIT License - Ver [LICENSE](LICENSE) para más detalles.

---

## 🔗 Proyectos Relacionados

- [linux-fleet-manager](https://github.com/Liquenson/linux-fleet-manager) - Automatización Bash para gestión de servidores

---

⭐ **¿Te resulta útil? ¡Dale una estrella!**

**¿Preguntas?** Abre un [issue](https://github.com/Liquenson/aws-terraform-devops/issues) o contáctame por [email](mailto:liquenson.cloud@gmail.com).

