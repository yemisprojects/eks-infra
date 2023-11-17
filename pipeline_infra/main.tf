module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                    = var.vpc_name
  cidr                    = var.vpc_cidr
  azs                     = slice(data.aws_availability_zones.available.names, 0, 2)
  map_public_ip_on_launch = true
  public_subnets          = var.vpc_public_subnets
  enable_nat_gateway      = false

  public_subnet_tags = {
    "Type" = "public_subnet"
  }

}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.pipeline.id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.ec2_key_name != "" ? var.ec2_key_name : null
  associate_public_ip_address = true
  user_data                   = file("./user_data/install_jenkins.sh")
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    "Name" = "jenkins-server"
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "Jenkins Security Group"
  description = "Allow access to jenkins"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow github webhook access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["185.199.108.0/22", "192.30.252.0/22", "140.82.112.0/20", "143.55.64.0/20"]
  }

  ingress {
    description = "Allow sonarcloud webhook access" #yet to get sonarcloud IP address range
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow vpc cidr and sonarqube access"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow local IP ssh & http access"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


data "aws_ami" "pipeline" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy*19"]
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
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

}

data "http" "myip" {
  url = "https://api.ipify.org/"
}

data "aws_availability_zones" "available" {}

resource "aws_iam_role" "ec2" {
  name = "ec2-jenkins-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.ec2.name
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-ssm-jenkins-role"
  role = aws_iam_role.ec2.name

}
