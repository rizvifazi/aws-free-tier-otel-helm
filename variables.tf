# General
variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "otel-eks-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.31"
}

# Networking
variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs (3 AZs)"
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs (3 AZs)"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
}

# Node groups
variable "ng_general_instance_types" {
  description = "Instance types for general-purpose node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "ng_general_desired" {
  description = "Desired capacity for general node group"
  type        = number
  default     = 2
}

variable "ng_general_min" {
  description = "Min size for general node group"
  type        = number
  default     = 2
}

variable "ng_general_max" {
  description = "Max size for general node group"
  type        = number
  default     = 4
}

variable "ng_small_instance_types" {
  description = "Instance types for smaller node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "ng_small_desired" {
  description = "Desired capacity for small node group"
  type        = number
  default     = 2
}

variable "ng_small_min" {
  description = "Min size for small node group"
  type        = number
  default     = 2
}

variable "ng_small_max" {
  description = "Max size for small node group"
  type        = number
  default     = 4
}

# Helm chart
variable "otel_demo_chart_version" {
  description = "Optional: pin a specific opentelemetry-demo chart version"
  type        = string
  default     = "" # keep empty to use latest
}
