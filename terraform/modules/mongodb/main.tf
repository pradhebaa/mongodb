# ---------------------------------------------------------------------------------------------------------------------
# DISCOVER AMAZON ACCOUNT ID AND AMI
# ---------------------------------------------------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "selected" {
  name         = "${var.dns_zone}"
}


locals {
  # Get the region compacted name, with no dashes, e.g. "uswest2"
  sregion        = "${replace(data.aws_region.current.name, "-", "")}"
}

# IAM Role
data "aws_iam_policy_document" "r53" {
  statement {
    actions = [
      "route53:GetHostedZone",
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets",
      "route53:ListHostedZones"
      ]
    resources = [
      "arn:aws:route53:::*",
    ]
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

# get infrastructure.ssh security group

data "aws_security_group" "selected" {
  name         = "${var.sg_name}"
  vpc_id       = "${var.vpc_id}"
}


resource "aws_iam_role" "mongo_role" {
  name               = "mongo-${var.environment}-${local.sregion}-InstanceRole"
  assume_role_policy = "${data.aws_iam_policy_document.ec2.json}"
}

resource "aws_iam_role_policy" "mongo_policy" {
  role       = "${aws_iam_role.mongo_role.name}"
  policy     = "${data.aws_iam_policy_document.r53.json}"
}

# IAM profile attached to the Mongo instances
resource "aws_iam_instance_profile" "mongo_profile" {
  name =  "mongo-${var.environment}-${local.sregion}-InstanceProfile"
  role = "${aws_iam_role.mongo_role.name}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY MONGO CLUSTER
# ---------------------------------------------------------------------------------------------------------------------

data "null_data_source" "mongodb_fqdn" {
  count = "${var.cluster_size}"

  inputs = {
    hostname = "mongo-${count.index}-${var.environment}.${var.dns_zone}"
  }
}


data "null_data_source" "mongodb_name" {
  count = "${var.cluster_size}"

  inputs = {
    hostname = "mongo-${count.index}-${var.environment}.${local.sregion}"
}
}


data "template_file" "mongo_userdata" {
  count = "${var.cluster_size}"

  template = "${file("${path.module}/user-data/userdata.tpl")}"

  vars {
    mongodb_self_name                 = "${element(data.null_data_source.mongodb_fqdn.*.outputs.hostname, count.index)}"
    mongodb_user                      = "${var.dbAdminUser}"
    mongodb_password                  = "${var.dbAdminUserPass}"
    mongodb_all_peers_csv             = "${join(",", formatlist("%s:27017", data.null_data_source.mongodb_fqdn.*.outputs.hostname))}"
    dnsZoneId                         = "${data.aws_route53_zone.selected.id}"
    mongodbExporterUser               = "${var.mongodbExporterUser}"
    mongodbExporterUserPass           = "${var.mongodbExporterUserPass}"
  }
}


resource "aws_launch_configuration" "mongo" {
  count                = "${var.cluster_size}"
  iam_instance_profile = "${aws_iam_instance_profile.mongo_profile.id}"
  image_id             = "${var.mongo_ami}"
  instance_type        = "${var.instance_type}"
  name_prefix          = "${element(data.null_data_source.mongodb_name.*.outputs.hostname, count.index)}"
  security_groups      = ["${aws_security_group.host.id}","${data.aws_security_group.selected.id}"]
  user_data            = "${element(data.template_file.mongo_userdata.*.rendered, count.index)}"
  key_name             = "${var.key_name}"

  root_block_device {
    volume_type = "gp2"
    volume_size = "${var.root_vol_size}"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = ["user_data"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ASGs FOR MONGO CLUSTER
# ---------------------------------------------------------------------------------------------------------------------


resource "aws_autoscaling_group" "mongo" {
  count                     = "${var.cluster_size}"
  name                      = "mongo-${count.index}-${var.environment}.${local.sregion}"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  desired_capacity          = 1
  health_check_type         = "EC2"
  launch_configuration      = "${element(aws_launch_configuration.mongo.*.name, count.index)}"
  vpc_zone_identifier       = ["${element(var.subnet_ids, count.index)}"]

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "mongo-${count.index}-${var.environment}.${local.sregion}"
    propagate_at_launch = true
  }

  tag {
    key                 = "terraform"
    value               = "true"
    propagate_at_launch = true
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
}