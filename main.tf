
resource "aws_s3_bucket" "bucket" {
  bucket        = "some-bucket"
}
resource "aws_sns_topic" "topic" {
  name = "ramTerraformTopic"

  policy = <<POLICY
  {
      "Version":"2012-10-17",
      "Statement":[{
          "Effect": "Allow",
          "Principal": {"Service":"s3.amazonaws.com"},
          "Action": "SNS:Publish",
          "Resource":  "arn:aws:sns:${var.region}:${var.account_id}:ramTerraformTopic",
          "Condition":{
              "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.bucket.arn}"}
          }
      }]
  }
  POLICY
}
provider "aws" {
  region = var.region
}

data archive_file lambda {
  type        = "zip"
  source_file = "index.js"
  output_path = "lambda_function.zip"
}


resource aws_iam_role iam {
  name = "iam_for_lambda_tf"

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

resource aws_iam_policy this {
  name        = "ramTerraformLambdaPolicy"
  description = "Allow to access base resources and trigger transcoder"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SomeVeryDefaultAndOpenActions",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}
module lambda {
    source = "terraform-aws-modules/lambda/aws"

  function_name  = "ramTerraformLambda"
  filename       = data.archive_file.lambda.output_path
  description    = "description should be here"
  handler        = "index.handler"
  runtime        = "nodejs12.x"
  memory_size    = "128"
  concurrency    = "5"
  lambda_timeout = "20"
  log_retention  = "1"
  role_arn       = aws_iam_role.iam.arn

  vpc_config = {
    subnet_ids         = ["sb-q53asdfasdfasdf", "sf-3asdfasdfasdf6"]
    security_group_ids = ["sg-3asdfadsfasdfas"]
  }

  environment = {
    Environment = "test"
  }

  tags = {
    Environment = "test"
  }
}
