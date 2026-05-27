variable "aws_region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID where Terraform should create/read resources"
  default     = "065209282584"
}

variable "project_name" {
  default = "django-devops"
}

variable "key_name" {
  description = "Existing AWS key pair name"
  default     = "my-key"
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  default     = "0.0.0.0/0"
}