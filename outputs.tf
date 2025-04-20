# 1단계 : VPC + Subnet + Routing Table + IGW + NAT Gateway 구성
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public Subnet IDs"
}

output "private_app_subnet_ids" {
  value       = module.vpc.private_app_subnet_ids
  description = "Private App Subnet IDs"
}

output "private_db_subnet_ids" {
  value       = module.vpc.private_db_subnet_ids
  description = "Private DB Subnet IDs"
}

output "public_route_table_id" {
  value       = module.vpc.public_route_table_id
  description = "Public Route Table ID"
}

output "nat_gateway_ids" {
  value       = module.vpc.nat_gateway_ids
  description = "NAT Gateway IDs"
}

output "eip_nat_ips" {
  value       = module.vpc.eip_nat_ips
  description = "Public IPs for NAT Gateways"
}

# 2단계: Web Tier의 Security Group + EC2 + ALB 구성

output "alb_dns_name" {
  value       = aws_lb.alb_web.dns_name
  description = "Public DNS name of the web ALB"
}

output "web_instance_ids" {
  value       = [aws_instance.web_a.id, aws_instance.web_c.id]
  description = "Instance IDs of web tier EC2 instances"
}

# 3단계: App Tier EC2 + Internal ALB 구성
output "app_alb_dns_name" {
  value       = aws_lb.alb_app.dns_name
  description = "Internal DNS name of App Tier ALB"
}

output "app_instance_ids" {
  value       = [aws_instance.app_a.id, aws_instance.app_c.id]
  description = "EC2 instance IDs for App Tier"
}

# 4단계 : DB Tier - Multi-AZ RDS 구성
output "rds_endpoint" {
  description = "RDS 엔드포인트 (읽기/쓰기)"
  value       = aws_db_instance.rds.endpoint
}

output "rds_identifier" {
  description = "RDS 인스턴스 이름"
  value       = aws_db_instance.rds.id
}

