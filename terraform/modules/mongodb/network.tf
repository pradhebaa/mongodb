# ---------------------------------------------------------------------------------------------------------------------
# SECURITY GROUPS
# ---------------------------------------------------------------------------------------------------------------------
# security group for mongo hosts
resource "aws_security_group" "host" {
  name   = "mongo-${var.environment}-${data.aws_region.current.name}-instanceSG"
  vpc_id = "${var.vpc_id}"

  tags = {
    Environment = "${var.environment}"
    Name        = "mongo-${var.environment}-${data.aws_region.current.name}-instanceSG"
    Role        = "database"
    terraform   = "true"
  }
}

## allow outbound access from cluster
resource "aws_security_group_rule" "host_outbound" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.host.id}"
}

## allow mongo to talk to itself
resource "aws_security_group_rule" "host_mongo_self" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  self              = true
  security_group_id = "${aws_security_group.host.id}"
}

## external mongo access
resource "aws_security_group_rule" "bal_mongo" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  cidr_blocks              = ["${var.ingress_cidr_blocks}"]
  security_group_id        = "${aws_security_group.host.id}"
}

## monitoring
resource "aws_security_group_rule" "monitoring" {
  type                     = "ingress"
  from_port                = 9001
  to_port                  = 9001
  protocol                 = "tcp"
  cidr_blocks              = ["${var.k8s_cidr_blocks}"]
  security_group_id        = "${aws_security_group.host.id}"
}

resource "aws_security_group_rule" "monitoring_node" {
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  cidr_blocks              = ["${var.k8s_cidr_blocks}"]
  security_group_id        = "${aws_security_group.host.id}"
}
