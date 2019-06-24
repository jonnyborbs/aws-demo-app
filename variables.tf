variable "key_name" {
  description = "The name of the AWS Key Pair"
  default     = "JS-KeyPair"
}

variable "private_key" {
  description = "Private Key"
}
variable "public_key" {
  description = "Public Key"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCCPHvdkwslRQKdo09KrDNZZmCnGD74Q9BkM1lR3BsmqHQaqwU8lj3oSh3cXkj6iOK51Mmbf+PUIvtw9MihTaLRZtRUVSZElzYNPZkYOao6e/fafTXjPiLohV2FxQkQJfi+K4i/YdUiWC5wqyvwD7+l4Z9mHJ0pQ2huCvebjchXujuRR/IDxuKKo9OFGjmedadGtr96gWBR4Yek+Rg4ZvtpT6dJIjgV3knUHX6XA7dCVplgDKQPXddafQ/CI2lqtsQue+RiqcJ7xQ0B9ARpvRDVR0O7JvOiGD9qgvZb8VRFkCjqWmSkEOPJHapBaksY8OPf7t9SXFpEkvkM/9NylIDp"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "AZ to run RDS"
  default     = "us-east-1a"
}