# modules/vpc/main.tf

# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.name}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}

# Public Subnets
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public-${var.region}a" }
}

resource "aws_subnet" "public_c" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_c_cidr
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public-${var.region}c" }
}

# Public Route Table & Associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.name}-rtb-public" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateways + EIPs
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags   = { Name = "${var.name}-eip-nat-a" }
}

resource "aws_eip" "nat_c" {
  domain = "vpc"
  tags   = { Name = "${var.name}-eip-nat-c" }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "${var.name}-natgw-a" }
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.public_c.id
  tags          = { Name = "${var.name}-natgw-c" }
}

# Private Subnets (App & DB)
resource "aws_subnet" "private_app_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnet_a_cidr
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.name}-private-app-${var.region}a" }
}

resource "aws_subnet" "private_app_c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_subnet_c_cidr
  availability_zone = "${var.region}c"
  tags              = { Name = "${var.name}-private-app-${var.region}c" }
}

resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnet_a_cidr
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.name}-private-db-${var.region}a" }
}

resource "aws_subnet" "private_db_c" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnet_c_cidr
  availability_zone = "${var.region}c"
  tags              = { Name = "${var.name}-private-db-${var.region}c" }
}

# Private App Route Tables + Associations
resource "aws_route_table" "private_app_a" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
  tags = { Name = "${var.name}-rtb-private-app-a" }
}

resource "aws_route_table" "private_app_c" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }
  tags = { Name = "${var.name}-rtb-private-app-c" }
}

resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_app_a.id
  route_table_id = aws_route_table.private_app_a.id
}

resource "aws_route_table_association" "private_app_c" {
  subnet_id      = aws_subnet.private_app_c.id
  route_table_id = aws_route_table.private_app_c.id
}

# Private DB Route Table + Associations
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-rtb-private-db" }
}

resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_c" {
  subnet_id      = aws_subnet.private_db_c.id
  route_table_id = aws_route_table.private_db.id
}
