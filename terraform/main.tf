module "vpc" {
  source = "./modules/vpc"

  aws_region   = var.aws_region
  project_name = var.project_name
  environment  = var.environment
}

module "eks" {
  source = "./modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}

import {
  to = aws_eks_access_entry.admin
  id = "dev-platform-dev:arn:aws:iam::375976227140:user/terraform-admin"
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::375976227140:user/terraform-admin"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::375976227140:user/terraform-admin"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

module "rds" {
  source          = "./modules/rds"
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
}
