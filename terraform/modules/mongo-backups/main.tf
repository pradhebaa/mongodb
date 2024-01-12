# create iam role for lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "lambda-mongo-backup-${var.region}-${var.environment}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_snapshot_policy" {
  name        = "lambda-mongo-backup-${var.region}-${var.environment}-lambdaSnapshotPolicy"
  description = "Lambda policy to take snapshot"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:CreateSnapshot",
                "ec2:CreateTags"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}


# creating S3 bucket as the deployment package is more than 10MB
resource "aws_s3_bucket" "mongo_lambda_deployment_pkg_bucket" {
  bucket = "mongo-lambda-backup-${var.region}-${var.environment}"
  acl    = "private"
  region = "${var.region}"
  versioning {
      enabled = true
  }
}

# uploading deployment package to s3
resource "aws_s3_bucket_object" "deploy_pkg" {
  bucket = "${aws_s3_bucket.mongo_lambda_deployment_pkg_bucket.bucket}"
  key    = "lambda_backups.zip"
  source = "lambda_backups.zip"
  depends_on = ["aws_s3_bucket.mongo_lambda_deployment_pkg_bucket"]
}

data "aws_iam_policy" "lamba_vpc_access" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

data "aws_iam_policy" "lamba_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

locals {
  policies_arn = [ "${aws_iam_policy.lambda_snapshot_policy.arn}", "${data.aws_iam_policy.lamba_vpc_access.arn}", "${data.aws_iam_policy.lamba_basic_execution.arn}"]
  name = "mongo-lambda-backup-${var.region}-${var.environment}"
}
# count parameter is not able to compute the number of non-created items in the list ${length(local.policies_arn)}.
# Attach all policies to the lambda role
resource "aws_iam_role_policy_attachment" "lambda_vpc_access_attach" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  count      = 3
  policy_arn = "${local.policies_arn[count.index]}"
}

# Security groups

resource "aws_security_group" "lambda_sg" {
  name        = "${local.name}-sg"
  description = "Allow lambda to access mongo instances"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = [""]
  }
}

# create a lambda function to take backups for mongo
# creation of lambda resource assumes that s3 bucket has already been created and deploymnet package is available
resource "aws_lambda_function" "lambda" {
  depends_on    = ["aws_s3_bucket.mongo_lambda_deployment_pkg_bucket", "aws_s3_bucket_object.deploy_pkg"]
  function_name = "${local.name}"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "lambda_backups.lambda_handler"
  s3_bucket     = "${aws_s3_bucket.mongo_lambda_deployment_pkg_bucket.bucket}"
  s3_key        = "lambda_backups.zip"
  runtime       = "${var.runtime}"
  timeout       = "${var.lambda_timeout}"
  memory_size   = "${var.lamba_memory}"

  environment {
    variables         = {
      hostnames       = "${var.hostnames}"
      region          = "${var.region}"
      env             = "${var.environment}"
      adminusername   = "${var.mongo_username}"
      adminpassword   = "${var.mongo_password}"
      webhookurl      = "${var.webhookurl}"
      timezone        = "${var.timezone}"
    }
  }

  vpc_config {
    subnet_ids = "${var.subnet_ids}"
    security_group_ids = ["${aws_security_group.lambda_sg.id}"]
  }
}

# Fire up lambda function everyday using cloudwatch events
resource "aws_cloudwatch_event_rule" "mongo_snapshot_rule" {
    name = "${local.name}-rule"
    description = "Runs every day to take mongo backup"
    schedule_expression = "${var.cron_schedule}"
}

resource "aws_cloudwatch_event_target" "check_foo_every_five_minutes" {
    rule = "${aws_cloudwatch_event_rule.mongo_snapshot_rule.name}"
    arn = "${aws_lambda_function.lambda.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.mongo_snapshot_rule.arn}"
}
