# modules/vpc/variables.tf

variable "name" {
  description = "Prefix for all resource names"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the main VPC"
  type        = string
}

variable "public_subnet_a_cidr" {
  description = "CIDR for public subnet in AZ-a"
  type        = string
}

variable "public_subnet_c_cidr" {
  description = "CIDR for public subnet in AZ-c"
  type        = string
}

variable "private_app_subnet_a_cidr" {
  description = "CIDR for private app subnet in AZ-a"
  type        = string
}

variable "private_app_subnet_c_cidr" {
  description = "CIDR for private app subnet in AZ-c"
  type        = string
}

variable "private_db_subnet_a_cidr" {
  description = "CIDR for private db subnet in AZ-a"
  type        = string
}

variable "private_db_subnet_c_cidr" {
  description = "CIDR for private db subnet in AZ-c"
  type        = string
}
