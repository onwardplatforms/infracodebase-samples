#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

#------------------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

#------------------------------------------------------------------------------
# Public Subnets
#------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#------------------------------------------------------------------------------
# NAT Gateway (only created when EC2 is in private subnet)
#------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.ec2_public_access ? 0 : 1
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.ec2_public_access ? 0 : 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# Private Subnets
#------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  }
}

resource "aws_route_table" "private" {
  count  = var.ec2_public_access ? 0 : 1
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count = var.ec2_public_access ? 0 : 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}

#------------------------------------------------------------------------------
# Security Group for Backend VM
#------------------------------------------------------------------------------

resource "aws_security_group" "backend" {
  name        = "${local.name_prefix}-backend-sg"
  description = "Security group for backend VM"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic (needed for SSM and general connectivity)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${local.name_prefix}-backend-sg"
  }
}

#------------------------------------------------------------------------------
# IAM Role for SSM
#------------------------------------------------------------------------------

resource "aws_iam_role" "ssm" {
  name = "${local.name_prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${local.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm.name

  tags = {
    Name = "${local.name_prefix}-ssm-profile"
  }
}

#------------------------------------------------------------------------------
# EC2 Instance (Backend VM)
#------------------------------------------------------------------------------

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro" # Free tier eligible
  subnet_id              = var.ec2_public_access ? aws_subnet.public[0].id : aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  # No SSH key - use SSM Session Manager instead
  associate_public_ip_address = var.ec2_public_access

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30 # AL2023 minimum requirement
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name               = "${local.name_prefix}-backend-root"
      infracodebase_demo = var.demo_id
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 required
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${local.name_prefix}-backend"
  }
}

#------------------------------------------------------------------------------
# RDS PostgreSQL (Optional)
#------------------------------------------------------------------------------

resource "random_password" "rds" {
  count = var.create_rds ? 1 : 0

  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "main" {
  count = var.create_rds ? 1 : 0

  name        = "${local.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${local.name_prefix}"
  subnet_ids  = aws_subnet.private[*].id

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  count = var.create_rds ? 1 : 0

  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "PostgreSQL from backend"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_db_instance" "main" {
  count = var.create_rds ? 1 : 0

  identifier = "${local.name_prefix}-postgres"

  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro" # Smallest available, free tier eligible
  allocated_storage    = 20            # Minimum for gp2/gp3
  storage_type         = "gp2"
  storage_encrypted    = true
  skip_final_snapshot  = true # Easy destroy
  deletion_protection  = false
  publicly_accessible  = false
  multi_az             = false # Single AZ for cost savings

  db_name  = "demoapp"
  username = "dbadmin"
  password = random_password.rds[0].result

  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]

  # Performance insights disabled to reduce costs
  performance_insights_enabled = false

  # Backup disabled for demo
  backup_retention_period = 0

  tags = {
    Name = "${local.name_prefix}-postgres"
  }
}
