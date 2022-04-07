# terraform-aws-fargate-wordpress

Terraform module which deploys Wordpress on AWS using ECS Fargate for compute, RDS for database and an application load balancer.

There are the features and services involved for the stack :
- ECS and Fargate SPOT for the containers
- RDS Aurora Serverless for the database
- Route53 for DNS (removed as I'm building this in an account without R53)
- Cloudfront as CDN
- ALB and ASG for availability
- Fargate Spot for all containers
- ECS Exec to allow you to connect to your container
- EFS for data persistence
- ACM for SSL certificate management
- KMS for encryption key management
- IAM, SG, CW and VPC (but how could we live without them)
- of course Terraform and Wordpress :)

## PREREQUISITES
- An exisiting Route53 public hosted zone should be present
- You should define those 3 variables

```hcl
variable "domain_name" {
  default = "mydomain.tld"
}
variable "region" {
  default = "eu-west-2"
}
variable "profile" {
  default = "myuser"
}

variable "wp_subdomain" {
  default = "wordpress"
}

variable "cloudfront_acm_certificate_arn" {
  description = "SSL Certificate ARN for Cloudfront - Must be in us-east-1"
  default     = "arn:aws:acm:us-east-1:123456789012:certificate/12abcdef-1234-abcd-abcd-ffff12345678"
}
variable "lb_acm_certificate_arn" {
  description = "SSL Certificate ARN"
  default     = "arn:aws:acm:eu-west-2:123456789012:certificate/12abcdef-1234-abcd-abcd-ffff12345678"
}
```

## Example Usage

```hcl
provider "aws" {
  region  = var.region
  profile = var.profile
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "wordpress"
  cidr                 = "10.0.0.0/16"
  azs                  = ["eu-west-2a", "eu-west-2b"]
  public_subnets       = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets      = ["10.0.2.0/24", "10.0.3.0/24"]
  intra_subnets        = ["10.0.4.0/24", "10.0.5.0/24"]
  database_subnets     = ["10.0.6.0/24", "10.0.7.0/24"]
  enable_nat_gateway   = true
  enable_dns_hostnames = true
}

module "terraform-aws-fargate-wordpress" {
  source                         = "../terraform-aws-fargate-wordpress"
  ecs_service_subnet_ids         = module.vpc.private_subnets
  lb_subnet_ids                  = module.vpc.public_subnets
  db_subnet_group_subnet_ids     = module.vpc.database_subnets
  domain_name                    = "${var.wp_subdomain}.${var.domain_name}"
  cnames                         = ["${var.wp_subdomain}.${var.domain_name}"]
  acm_certificate_arn            = var.lb_acm_certificate_arn
  lb_acm_certificate_arn         = var.lb_acm_certificate_arn
  cloudfront_acm_certificate_arn = var.cloudfront_acm_certificate_arn
  vpc_id                         = module.vpc.vpc_id
}

```

TODO :
- Manage multiple wordpress deployments using same resources (ALB, EFS, ECS cluster etc...)
- Manage other region
- Better handling of region indication
...
