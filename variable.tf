variable "region" {
  description = "The AWS region where resources will be created."
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  default     = "my-eks-cluster"
}

variable "tags" {
  description = "A map of tags to apply to all AWS resources created."
  type        = map(string)
  default     = {
    Environment = "dev"
    Project     = "my-project"
  }
}
