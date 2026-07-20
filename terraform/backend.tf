terraform {
  backend "s3" {
    bucket         = "devops-lab-tfstate-522921482434"
    key            = "global/s3/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "devops-lab-state-lock"
    encrypt        = true
  }
}
