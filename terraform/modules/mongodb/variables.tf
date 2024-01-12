# Variables

# Instance related variable
variable "key_name" {
  type        = "string"
  description = "Key name for AWS EC2 instance"
}

variable "instance_type" {
  type        = "string"
  description = "AWS EC2 instance type to use for creating cluster nodes"
}

variable "mongo_ami" {
  type        = "string"
  description = "Mongo ami id"
}

variable "root_vol_size" {
  type        = "string"
  description = "Space (in Gigabytes) to give to the instance root disk"
  default     = "24"
}

# Infrastructure related variables
variable "vpc_id" {
  type        = "string"
  description = "VPC ID of something we connect to somewhere"
}

variable "cluster_size" {
  type        = "string"
  description = "Number of instances in the mongo cluster"
}

variable "environment" {
  type        = "string"
  description = "Environment/production tier"
}

variable "subnet_ids" {
  type        = "list"
  description = "List of private subnet IDs Mongo launches in"
}

variable "region" {
  type        = "string"
  description = "AWS region"
}

variable "ingress_cidr_blocks" {
  type        = "list"
  description = "CIDR blocks to allow ( instance ingress)"
}

variable "dns_zone" {
  type        = "string"
  description = "DNS zone to register A records"
}

variable "dbAdminUser" {
    type = "string"
}

variable "dbAdminUserPass" {
    type = "string"
}

variable "mongodbExporterUser" {
    type = "string"
}

variable "mongodbExporterUserPass" {
    type = "string"
}

variable "k8s_cidr_blocks" {
    type = "string"
}


provider "aws" {
  version = "~> 1.2"
  region  = "${var.region}"
}

variable "sg_name" {
    type = "string"
}
