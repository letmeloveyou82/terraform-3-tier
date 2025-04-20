# modules/vpc/outputs.tf

output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}

output "private_app_subnet_ids" {
  value = [aws_subnet.private_app_a.id, aws_subnet.private_app_c.id]
}

output "private_db_subnet_ids" {
  value = [aws_subnet.private_db_a.id, aws_subnet.private_db_c.id]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "nat_gateway_ids" {
  value = [aws_nat_gateway.nat_a.id, aws_nat_gateway.nat_c.id]
}

output "eip_nat_ips" {
  value = [aws_eip.nat_a.public_ip, aws_eip.nat_c.public_ip]
}
