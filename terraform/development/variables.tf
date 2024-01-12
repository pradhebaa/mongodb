# ---------------------------------------------------------------------------------------------------------------------
# PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "kubernetes_cluster" {
  description = "Kubernetes cluster name needed to fetch AWS specific data sources"
  default     = ""
}

variable "environment" {
  description = "Environment name"
  default     = "development"
}

variable "instance_type" {
  type        = "string"
  description = "AWS EC2 instance type to use for creating cluster nodes"
  default     = "m5a.xlarge"
}

variable "root_vol_size" {
  type        = "string"
  description = "Space (in Gigabytes) to give to the instance root disk"
  default     = "100"
}

# ---------------------------------------------------------------------------------------------------------------------
# Infrastructure related variables
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_size" {
  type        = "string"
  description = "Number of instances in the mongo cluster"
  default     = 3
}

variable "region" {
  type        = "string"
  description = "AWS region"
  default     = "us-west-2"
}

variable "ingress_cidr_blocks" {
  type        = "list"
  description = "CIDR blocks to allow"
  default     = [""]
}

variable "dns_zone" {
  type        = "string"
  description = "DNS zone to register A records"
  default     = ""
}

# Mongodb admin user name and password 
variable "dbAdminUser" {
  type = "string"
  default = "mongoadmin"
}

variable "mongodbExporterUser" {
  type = "string"
  default = "mongoexporter"
}

variable "sg_name" {
    type = "string"
    default = "infrastructure.ssh"
}

variable "k8s_cidr_blocks" {
  type        = "list"
  description = "CIDR blocks to allow for port 9216 JMX"
  default     = [""]
}

