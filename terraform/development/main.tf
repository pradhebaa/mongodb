terraform {
  required_version = ">= 0.11.8"

  backend "s3" {
    bucket = "terraform-state"
    region = "us-east-1"
    key    = "mongodb-clusters/development"

    dynamodb_table = "terraform-state-locks"
  }
}

provider "aws" {
  version = "~> 1.2"
  region = "${var.region}"
}

locals {
  # Get the region compacted name, with no dashes, e.q. "uswest2"
  sregion = "${replace(data.aws_region.current.name, "-", "")}"

  # List of availability zones where Mongodb nodes should be created
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  ssh_key_name = "mongo-${var.environment}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DISCOVER EXISTING VPC, SUBNETS, AMIs
# ---------------------------------------------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_vpc" "by_kops" {
  tags {
    KubernetesCluster = "${var.kubernetes_cluster}"
  }
}

data "aws_subnet" "private" {
  count = "${length(local.availability_zones)}"

  vpc_id = "${data.aws_vpc.by_kops.id}"

  tags {
    Name = "tf-private-${element(local.availability_zones, count.index)}"
  }
}

data "aws_ami" "mongo_ami" {
  most_recent = true

  filter {
    name   = "tag:environment/${var.environment}"
    values = ["*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "name"
    values = ["mongo*"]
  }
 }

resource "random_string" "dbAdminUserPass" {
  length = 16
  special = false
}

resource "random_string" "mongodbExporterUserPass" {
  length = 16
  special = false
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE MONGO CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

module "mongo_cluster" {

  source                    = "../modules/mongodb"
  key_name                  = "${var.key_name}"
  vpc_id                    = "${data.aws_vpc.by_kops.id}"
  mongo_ami                 = "${data.aws_ami.mongo_ami.id}" 
  instance_type             = "${var.instance_type}"
  root_vol_size             = "${var.root_vol_size}"
  subnet_ids                = ["${data.aws_subnet.private.*.id}"]
  environment               = "${var.environment}"
  ingress_cidr_blocks       = "${var.ingress_cidr_blocks }"
  cluster_size              = "${var.cluster_size}"
  dns_zone                  = "${var.dns_zone}"
  dbAdminUser               = "${var.dbAdminUser}"
  dbAdminUserPass           = "${random_string.dbAdminUserPass.result}"
  mongodbExporterUser       = "${var.mongodbExporterUser}"
  mongodbExporterUserPass   = "${random_string.mongodbExporterUserPass.result}"
  region                    = "${var.region}"
  sg_name                   = "${var.sg_name}"
}