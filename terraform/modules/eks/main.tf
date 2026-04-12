module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = "1.32"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    main = {
      instance_types = ["m7i-flex.large"]
      min_size       = 1
      max_size       = 4
      desired_size   = 1

      labels = {
        Environment = var.environment
        Project     = var.project_name
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"                            = "true"
        "k8s.io/cluster-autoscaler/${var.project_name}-${var.environment}" = "owned"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
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
