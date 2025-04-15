# 1단계 : VPC + Subnet + Routing Table + IGW + NAT Gateway 구성
variable "name" {
  description = "Prefix used for naming AWS resources"
  type        = string
}

variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
}

variable "public_subnet_c_cidr" {
  description = "CIDR block for public subnet C"
  type        = string
}

variable "private_app_subnet_a_cidr" {
  description = "CIDR block for private app subnet A"
  type        = string
}

variable "private_app_subnet_c_cidr" {
  description = "CIDR block for private app subnet C"
  type        = string
}

variable "private_db_subnet_a_cidr" {
  description = "CIDR block for private db subnet A"
  type        = string
}

variable "private_db_subnet_c_cidr" {
  description = "CIDR block for private db subnet C"
  type        = string
}

# 2단계: Web Tier의 Security Group + EC2 + ALB 구성

variable "ami_id" {
  description = "AMI ID for Ubuntu EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for web tier"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Key pair name for EC2 instance SSH access"
  type        = string
}

# 4단계 : DB Tier - Multi-AZ RDS 구성
# RDS 접속용 정보
variable "db_username" {
  description = "Master username for RDS"
  type        = string
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}
