variable "region" {
  type        = "string"
  description = "AWS region"
}

variable "environment" {
  type        = "string"
  description = "Deployment environment: dev or staging or production"
}

variable "runtime" {
  type        = "string"
  description = "Lambda runtime"
}

variable "hostnames" {
  type        = "string"
  description = "slack webhook to post messages"
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
}

variable "subnet_ids" {
  type        = "list"
  description = "subnet id for lambda function"
}

variable "vpc_id" {
  type        = "string"
  description = "vpc id for lambda function"
}

variable "cron_schedule" {
  type        = "string"
  description = "schedule to run cron job"
}

variable "lambda_timeout" {
  type        = "string"
  description = "Timeout in seconds for lambda"
}

variable "lamba_memory" {
  type        = "string"
  description = "Memory size required for lambda func to run"
}