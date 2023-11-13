output "jenkins_2_ip" {
  description = "Jenkins EC2 public IP"
  value       = aws_instance.jenkins_2.public_ip
}

output "sonarqube_ip" {
  description = "Sonarqube EC2 public IP"
  value       = aws_instance.sonarqube.public_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
