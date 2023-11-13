
resource "aws_instance" "test" {
  ami           = data.aws_ami.my_lab_ami.id
  instance_type = "t3.micro"
  tags = {
    "Name" = "test-Server"
  }
}

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30.0"
    }
  }

  # backend "s3" {
  #   bucket = "eks-infra-tfstate-644802181882"
  #   key    = "prod/eks-cluster/terraform.tfstate"
  #   region = "us-east-1"

  #   dynamodb_table = "prod-eks-cluster"
  # }

}

provider "aws" {
  region = "us-east-1"
}


data "aws_ami" "my_lab_ami" {
  most_recent = true #this is key to filtering for the right image, so only 1 image is returned
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*x86_64-gp2"] #this is key to filtering for the right image
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  # filter {
  #   name   = "owner-alias"
  #   values = ["amazon"]
  # }

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
