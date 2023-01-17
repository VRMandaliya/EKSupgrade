resource "aws_instance" "ssm-ec2" {
  ami                    = "ami-01efa4023f0f3a042"
  instance_type          = "t2.micro"
  key_name               = "aws_ssh"
  subnet_id              = element(module.vpc.public_subnets, 1)
  vpc_security_group_ids = [data.aws_security_group.default.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_ec2_profile.id
  user_data              = file("./scripts/install-ssm.sh")
  tags = {
    Name = "ssm-ec2"
  }
}

module "android_ios_firebase_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "android-ios-firebase-sg"
  description = "Security group to allow ingress trafic from GCP(firebase) Android & iOS test infra"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = ["100.96.0.0/11", "70.32.128.0/19", "209.85.131.0/27", "108.177.6.0/23", "108.177.18.192/26", "108.177.29.64/27", "108.177.31.160/27", "199.36.156.8/29", "199.36.156.16/28", "34.68.194.64/29", "34.69.234.64/29", "34.73.34.72/29", "34.73.178.72/29", "34.74.10.72/29", "34.136.2.136/29", "34.136.50.136/29", "34.145.234.144/29", "35.192.160.56/29", "35.196.166.80/29", "35.196.169.240/29", "35.203.128.0/28", "35.234.176.160/28", "35.243.2.0/27", "35.245.243.240/29", "199.192.115.0/30", "199.192.115.8/30", "199.192.115.16/29", "185.94.24.0/22"]
  ingress_ipv6_cidr_blocks = ["2001:4860:1008::/48", "2001:4860:1018::/48", "2001:4860:1019::/48", "2001:4860:1020::/48", "2001:4860:1022::/48"]
  ingress_rules            = ["https-443-tcp"]
}
