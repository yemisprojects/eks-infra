

################################################################################
# SONARQUBE
################################################################################
/*
resource "aws_instance" "sonarqube" {

  ami                         = data.aws_ami.pipeline.id
  instance_type               = var.instance_type_sonarqube
  vpc_security_group_ids      = [aws_security_group.sonarqube_sg.id]
  subnet_id                   = module.vpc.public_subnets[1]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  key_name                    = var.ec2_key_name != "" ? var.ec2_key_name : null
  associate_public_ip_address = true
  user_data                   = file("./user_data/install_sonarqube.sh")

  tags = {
    "Name" = "Sonarqube"
  }
}


resource "aws_security_group" "sonarqube_sg" {
  name        = "Sonar Security Group"
  description = "Allow access to sonarqube"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow local ssh and http IP access"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "Allow vpc cidr and jenkins access"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

variable "instance_type_sonarqube" {
  description = "ec2 instance type"
  type        = string
  default     = "t3.large"
}

output "sonarqube_ip" {
  description = "Sonarqube EC2 public IP"
  value       = aws_instance.sonarqube.public_ip
}
*/
