module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.10.0/24", "10.0.20.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = var.tags
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  cluster_name = var.cluster_name
  subnets = module.vpc.private_subnets
  vpc_id = module.vpc.vpc_id
  tags = var.tags
  map_roles = {
    "worker" = {
      "arn" = aws_iam_role.worker.arn
      "username" = "worker"
      "groups" = ["system:bootstrappers", "system:nodes"]
    }
  }
  workers_additional_security_group_ids = [aws_security_group.worker.id]
  kubernetes_version = "1.21"
  kubeconfig_aws_authenticator_additional_args = [
    "--role-arn",
    aws_iam_role.eks_cluster.arn,
    "--region",
    var.region
  ]
}

resource "aws_security_group" "worker" {
  name_prefix = "${var.cluster_name}-worker-"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "worker" {
  name = "${var.cluster_name}-worker-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.worker.name
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.cluster_name}-worker-profile"
  role = aws_iam_role.worker.name
}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster.name
}
