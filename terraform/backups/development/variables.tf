variable "region" {
  type        = "string"
  description = "AWS region"
  default     = "us-west-2"
}

variable "environment" {
  type        = "string"
  description = "Deployment environment: dev or staging or production"
  default = "development"
}

variable "runtime" {
  type        = "string"
  description = "Lambda runtime"
  default     = "python3.7"
}

variable "mongo_username" {
  type        = "string"
  description = "Mongo username"
}

variable "mongo_password" {
  type        = "string"
  description = "Mongo password"
}

variable "webhookurl" {
  type        = "string"
  description = "slack webhook to post messages"
}

variable "timezone" {
  type        = "string"
  description = "timezone for timestamp"
  default     = "US/Pacific"
}

variable "hostnames" {
  type        = "string"
  description = "mongo hostnames"
  default     = "mongo-0-development mongo-1-development mongo-2-development"
}

variable "kubernetes_cluster" {
  description = "Kubernetes cluster name needed to fetch AWS specific data sources"
  default     = ""
}