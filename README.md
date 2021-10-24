# terraform-aws-wordpress-ecs

Terraform module which deploys Wordpress on AWS using ECS Fargate for compute, RDS for database and an application load balancer.

There are the features and services involved for the stack :
- ECS and Fargate for the containers
- RDS Aurora Serverless for the database
- Route53 for DNS
- Cloudfront as CDN
- ALB and ASG for availability
- Spot for 50% of the containers
- ECS Exec to allow you to connect to your container
- EFS for data persistence
- ACM for SSL certificate management
- KMS for encryption key management
- IAM, SG, CW and VPC (but how could we live without them)
- of course Terraform and Wordpress :)

## Example Usage

```hcl
provider "aws" {
  region  = "us-east-1"
}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  name                 = "wordpress"
  cidr                 = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b"]
  public_subnets       = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets      = ["10.0.2.0/24", "10.0.3.0/24"]
  intra_subnets        = ["10.0.4.0/24", "10.0.5.0/24"]
  database_subnets     = ["10.0.6.0/24", "10.0.7.0/24"]
  enable_nat_gateway   = true
  enable_dns_hostnames = true
}

module "acm" {
  source      = "terraform-aws-modules/acm/aws"
  version     = "~> 3.0"
  domain_name = var.domain_name
  zone_id     = var.route53_zone_id
  subject_alternative_names = [
    "*.${var.domain_name}",
  ]
  wait_for_validation = true
  tags = {
    Name = var.domain_name
  }
}

module "wordpress-ecs" {
  source  = "jbgraindorge/wordpress-fargate/aws"
  version = "1.0.0"
  ecs_service_subnet_ids     = module.vpc.private_subnets
  lb_subnet_ids              = module.vpc.public_subnets
  db_subnet_group_subnet_ids = module.vpc.database_subnets
  domain_name                = "${var.wp_subdomain}.${var.domain_name}"
  cnames                     = ["${var.wp_subdomain}.${var.domain_name}"]
  acm_certificate_arn        = module.acm.acm_certificate_arn
  zone_id                    = var.route53_zone_id
  vpc_id                     = module.vpc.vpc_id
}

```
