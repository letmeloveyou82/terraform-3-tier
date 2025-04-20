module "vpc" {
  source = "./modules/vpc"

  name                      = var.name
  region                    = var.region
  vpc_cidr_block            = var.vpc_cidr_block
  public_subnet_a_cidr      = var.public_subnet_a_cidr
  public_subnet_c_cidr      = var.public_subnet_c_cidr
  private_app_subnet_a_cidr = var.private_app_subnet_a_cidr
  private_app_subnet_c_cidr = var.private_app_subnet_c_cidr
  private_db_subnet_a_cidr  = var.private_db_subnet_a_cidr
  private_db_subnet_c_cidr  = var.private_db_subnet_c_cidr
}

# 2단계: Web Tier의 Security Group + EC2 + ALB 구성

# ✅ Web Tier SG (모듈형 ingress/egress 리소스로 분리)
resource "aws_security_group" "sg_alb_web" {
  name        = "${var.name}-sg-alb-web"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.vpc_main.id

  tags = {
    Name = "${var.name}-sg-alb-web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_alb_web_ingress_http" {
  security_group_id = aws_security_group.sg_alb_web.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "sg_alb_web_egress_all" {
  security_group_id = aws_security_group.sg_alb_web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "sg_ec2_web" {
  name        = "${var.name}-sg-ec2-web"
  description = "Security group for EC2"
  vpc_id      = aws_vpc.vpc_main.id

  tags = {
    Name = "${var.name}-sg-ec2-web"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_ec2_web_ingress_from_alb" {
  security_group_id            = aws_security_group.sg_ec2_web.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_alb_web.id
}

resource "aws_vpc_security_group_egress_rule" "sg_ec2_web_egress_all" {
  security_group_id = aws_security_group.sg_ec2_web.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# EC2 Instance (Web Subnet A)
resource "aws_instance" "web_a" {
  ami                         = "ami-0d5bb3742db8fc264" # Ubuntu 24.04 LTS (서울 리전 기준)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public_a.id
  vpc_security_group_ids      = [aws_security_group.sg_ec2_web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2
              echo "<h1>Deployed via Terraform - A (Ubuntu)</h1>" > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2
              EOF

  tags = {
    Name = "${var.name}-web-ec2-a"
  }
}

# EC2 Instance (Web Subnet C)
resource "aws_instance" "web_c" {
  ami                         = "ami-0d5bb3742db8fc264" # Ubuntu 24.04 LTS (서울 리전 기준)
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public_c.id
  vpc_security_group_ids      = [aws_security_group.sg_ec2_web.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y apache2
              echo "<h1>Deployed via Terraform - C (Ubuntu)</h1>" > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2
              EOF

  tags = {
    Name = "${var.name}-web-ec2-c"
  }
}

# Target Group
resource "aws_lb_target_group" "tg_web" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name}-tg-web"
  }
}

# Target Group Attachment
resource "aws_lb_target_group_attachment" "tg_attach_a" {
  target_group_arn = aws_lb_target_group.tg_web.arn
  target_id        = aws_instance.web_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attach_c" {
  target_group_arn = aws_lb_target_group.tg_web.arn
  target_id        = aws_instance.web_c.id
  port             = 80
}

# Application Load Balancer
resource "aws_lb" "alb_web" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet_public_a.id, aws_subnet.subnet_public_c.id]
  security_groups    = [aws_security_group.sg_alb_web.id]

  tags = {
    Name = "${var.name}-alb-web"
  }
}

# ALB Listener
resource "aws_lb_listener" "alb_listener_web" {
  load_balancer_arn = aws_lb.alb_web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_web.arn
  }
}

# 3단계: App Tier EC2 + Internal ALB 구성
# ✅ App Tier SG
resource "aws_security_group" "sg_alb_app" {
  name        = "${var.name}-sg-alb-app"
  description = "Security group for internal ALB"
  vpc_id      = aws_vpc.vpc_main.id

  tags = {
    Name = "${var.name}-sg-alb-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_alb_app_ingress_http" {
  security_group_id            = aws_security_group.sg_alb_app.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_ec2_web.id
}

resource "aws_vpc_security_group_ingress_rule" "sg_alb_app_ingress_8080" {
  security_group_id            = aws_security_group.sg_alb_app.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_ec2_web.id
}

resource "aws_vpc_security_group_egress_rule" "sg_alb_app_egress_all" {
  security_group_id = aws_security_group.sg_alb_app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "sg_ec2_app" {
  name        = "${var.name}-sg-ec2-app"
  description = "Security group for app EC2"
  vpc_id      = aws_vpc.vpc_main.id

  tags = {
    Name = "${var.name}-sg-ec2-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_ec2_app_ingress_from_alb" {
  security_group_id            = aws_security_group.sg_ec2_app.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_alb_app.id
}

resource "aws_vpc_security_group_egress_rule" "sg_ec2_app_egress_all" {
  security_group_id = aws_security_group.sg_ec2_app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# App EC2 Instances
resource "aws_instance" "app_a" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_private_app_a.id
  vpc_security_group_ids      = [aws_security_group.sg_ec2_app.id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  user_data = file("${path.module}/scripts/nginx_app_a.sh")
  tags = {
    Name = "${var.name}-app-ec2-a"
  }
}

resource "aws_instance" "app_c" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_private_app_c.id
  vpc_security_group_ids      = [aws_security_group.sg_ec2_app.id]
  associate_public_ip_address = false
  key_name                    = var.key_name

  user_data = file("${path.module}/scripts/nginx_app_c.sh")

  tags = {
    Name = "${var.name}-app-ec2-c"
  }
}

# App Target Group
resource "aws_lb_target_group" "tg_app" {
  name        = "${var.name}-tg-app"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc_main.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.name}-tg-app"
  }
}

# App Target Group Attachment
resource "aws_lb_target_group_attachment" "tg_app_attach_a" {
  target_group_arn = aws_lb_target_group.tg_app.arn
  target_id        = aws_instance.app_a.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "tg_app_attach_c" {
  target_group_arn = aws_lb_target_group.tg_app.arn
  target_id        = aws_instance.app_c.id
  port             = 8080
}

# Internal ALB for App Tier
resource "aws_lb" "alb_app" {
  name               = "${var.name}-alb-app"
  internal           = true
  load_balancer_type = "application"
  subnets            = [aws_subnet.subnet_private_app_a.id, aws_subnet.subnet_private_app_c.id]
  security_groups    = [aws_security_group.sg_alb_app.id]

  tags = {
    Name = "${var.name}-alb-app"
  }
}

resource "aws_lb_listener" "alb_listener_app" {
  load_balancer_arn = aws_lb.alb_app.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_app.arn
  }
}

# 4단계 : DB Tier - Multi-AZ RDS 구성

# ✅ DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = [aws_subnet.subnet_private_db_a.id, aws_subnet.subnet_private_db_c.id]

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

# ✅ DB Tier SG
resource "aws_security_group" "sg_db" {
  name        = "${var.name}-sg-db"
  description = "Security group for DB"
  vpc_id      = aws_vpc.vpc_main.id

  tags = {
    Name = "${var.name}-sg-db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_db_ingress_mysql_from_app" {
  security_group_id            = aws_security_group.sg_db.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_ec2_app.id
}

resource "aws_vpc_security_group_egress_rule" "sg_db_egress_all" {
  security_group_id = aws_security_group.sg_db.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}


# ✅ RDS Instance (Multi-AZ)
resource "aws_db_instance" "rds" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "${var.name}_db"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_db.id]
  multi_az               = true
  publicly_accessible    = false
  skip_final_snapshot    = true # 실서비스에서는 false로 해둬야 됨

  tags = {
    Name = "${var.name}-rds"
  }
}
