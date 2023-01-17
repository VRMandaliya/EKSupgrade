resource "aws_iam_role" "ssm_ec2_role" {
  name               = "ssm-ec2-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "ssm-ec2-role"
  }
}

resource "aws_iam_instance_profile" "ssm_ec2_profile" {
  name = "ssm-ec2-role"
  role = aws_iam_role.ssm_ec2_role.id
}

resource "aws_iam_policy_attachment" "ssm_attach2" {
  name       = "ssm-attachment"
  roles      = [aws_iam_role.ssm_ec2_role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_policy" "clean_me_dump_s3" {
  name   = "clean-me-dump-s3"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DumpWrite",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::clean-me-dump/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "aws-metricbeat" {
  name   = "aws-metricbeat"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "sqs:ReceiveMessage"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "sqs:ChangeMessageVisibility",
            "Resource": "arn:aws:sqs:us-east-1:123456789012:test-fb-ks"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "sqs:DeleteMessage",
            "Resource": "arn:aws:sqs:us-east-1:123456789012:test-fb-ks"
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole",
                "sqs:ListQueues",
                "tag:GetResources",
                "ec2:DescribeInstances",
                "cloudwatch:GetMetricData",
                "ec2:DescribeRegions",
                "iam:ListAccountAliases",
                "sts:GetCallerIdentity",
                "cloudwatch:ListMetrics"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "clean_me_vault_s3" {
  name   = "clean-me-vault-s3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListAllMyBuckets",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::clean-me-vault",
        "arn:aws:s3:::clean-me-vault/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy" "clean_me_e2e_s3" {
  name   = "clean-me-e2e-app-s3"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::clean-me-e2e",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "users/*"
                }
            }
        },
        {
            "Sid": "AllowAllS3ActionsInUserFolder",
            "Effect": "Allow",
            "Action": [
                "s3:*Object*"
            ],
            "Resource": [
                "arn:aws:s3:::clean-me-e2e/users/*"
            ]
        },
        {
            "Sid": "AllowModelCopy",
            "Effect": "Allow",
            "Action": [
                "s3:*Object*"
            ],
            "Resource": [
                "arn:aws:s3:::models-eu-west-1/Clean_models/*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "clean_me_staging_s3" {
  name   = "clean-me-staging-app-s3"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::clean-me-staging",
            "Condition": {
                "StringLike": {
                    "s3:prefix": "users/*"
                }
            }
        },
        {
            "Sid": "AllowAllS3ActionsInUserFolder",
            "Effect": "Allow",
            "Action": [
                "s3:*Object*"
            ],
            "Resource": [
                "arn:aws:s3:::clean-me-staging/users/*"
            ]
        },
        {
            "Sid": "AllowModelCopy",
            "Effect": "Allow",
            "Action": [
                "s3:*Object*"
            ],
            "Resource": [
                "arn:aws:s3:::models-eu-west-1/Clean_models/*"
            ]
        }
    ]
}
EOF
}
