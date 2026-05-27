output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "sonarqube_public_ip" {
  value = aws_instance.sonarqube.public_ip
}

output "ecr_repository_url" {
  value = aws_ecr_repository.django_app.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}