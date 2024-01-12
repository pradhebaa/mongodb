terraform {
  required_version = ">= 0.11.8"

  backend "s3" {
    bucket = "terraform-backup-bucket"
    region = "us-west-2"
    key    = "mongodb-clusters/backups/uswest2.development"
  }
}

provider "aws" {
  version = "~> 1.2"
  region = "${var.region}"
}

locals {
  # List of availability zones where Mongodb nodes are created
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

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

module "mongo_snapshot" {
  source = "../../modules/backups"
  environment = "${var.environment}"
  hostnames = "${var.hostnames}"
  mongo_password = "${var.mongo_password}"
  mongo_username = "${var.mongo_username}"
  region = "${var.region}"
  runtime = "${var.runtime}"
  subnet_ids = ["${data.aws_subnet.private.*.id}"]
  timezone = "${var.timezone}"
  vpc_id = "${data.aws_vpc.by_kops.id}"
  webhookurl = "${var.webhookurl}"
}