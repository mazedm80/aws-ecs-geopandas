# VPC
resource "aws_vpc" "dbt-redshift-ssm-demo-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-VPC"
    Environment = var.env
  }
}
# Private Subnet for AZ1
resource "aws_subnet" "dbt-redshift-ssm-demo-subnet-private-az1" {
  vpc_id     = aws_vpc.dbt-redshift-ssm-demo-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "DBT-Redshift-SSM-Demo-Subnet-Private-AZ1"
    Environment = var.env
  }
}
# Private Subnet for AZ2
resource "aws_subnet" "dbt-redshift-ssm-demo-subnet-private-az2" {
  vpc_id     = aws_vpc.dbt-redshift-ssm-demo-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "DBT-Redshift-SSM-Demo-Subnet-Private-AZ2"
    Environment = var.env
  }
}
# Public Subnet for AZ3
resource "aws_subnet" "dbt-redshift-ssm-demo-subnet-public-az3" {
  vpc_id     = aws_vpc.dbt-redshift-ssm-demo-vpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "DBT-Redshift-SSM-Demo-Subnet-Public-AZ3"
    Environment = var.env
  }
}
# Internet Gateway
resource "aws_internet_gateway" "dbt-redshift-ssm-demo-igw" {
  vpc_id = aws_vpc.dbt-redshift-ssm-demo-vpc.id

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-IGW"
    Environment = var.env
  }
}
# NAT Gateway
resource "aws_eip" "dbt-redshift-ssm-demo-eip" {
  domain = "vpc"

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-NAT-EIP"
    Environment = var.env
  }
}

resource "aws_nat_gateway" "dbt-redshift-ssm-demo-nat" {
  depends_on = [
    aws_internet_gateway.dbt-redshift-ssm-demo-igw,
    aws_eip.dbt-redshift-ssm-demo-eip
  ]

  allocation_id = aws_eip.dbt-redshift-ssm-demo-eip.id
  subnet_id    = aws_subnet.dbt-redshift-ssm-demo-subnet-public-az3.id

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-NAT"
    Environment = var.env
  }
}
# Public Route Table
resource "aws_route_table" "dbt-redshift-ssm-demo-rt-public" {
  depends_on = [aws_internet_gateway.dbt-redshift-ssm-demo-igw]

  vpc_id = aws_vpc.dbt-redshift-ssm-demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dbt-redshift-ssm-demo-igw.id
  }

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-RT-Public"
    Environment = var.env
  }
}

# Private Route Table
resource "aws_route_table" "dbt-redshift-ssm-demo-rt-private" {
  depends_on = [aws_nat_gateway.dbt-redshift-ssm-demo-nat]

  vpc_id = aws_vpc.dbt-redshift-ssm-demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dbt-redshift-ssm-demo-nat.id
  }

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-RT-Private"
    Environment = var.env
  }
}

# Public Subnet Route Table Association
resource "aws_route_table_association" "dbt-redshift-ssm-demo-rt-public-association" {
  depends_on = [aws_route_table.dbt-redshift-ssm-demo-rt-public]

  subnet_id      = aws_subnet.dbt-redshift-ssm-demo-subnet-public-az3.id
  route_table_id = aws_route_table.dbt-redshift-ssm-demo-rt-public.id
}
# Private Subnet Route Table Association for AZ1
resource "aws_route_table_association" "dbt-redshift-ssm-demo-rt-private-association-az1" {
  depends_on = [aws_route_table.dbt-redshift-ssm-demo-rt-private]

  subnet_id      = aws_subnet.dbt-redshift-ssm-demo-subnet-private-az1.id
  route_table_id = aws_route_table.dbt-redshift-ssm-demo-rt-private.id
}

# Private Subnet Route Table Association for AZ2
resource "aws_route_table_association" "dbt-redshift-ssm-demo-rt-private-association-az2" {
  depends_on = [aws_route_table.dbt-redshift-ssm-demo-rt-private]

  subnet_id      = aws_subnet.dbt-redshift-ssm-demo-subnet-private-az2.id
  route_table_id = aws_route_table.dbt-redshift-ssm-demo-rt-private.id
}

# Security Group
resource "aws_security_group" "dbt-redshift-ssm-demo-sg" {
  depends_on = [ aws_vpc.dbt-redshift-ssm-demo-vpc ]

  name        = "DBT-Redshift-SSM-Demo-SG"
  description = "Security group for DBT Redshift SSM Demo"
  vpc_id     = aws_vpc.dbt-redshift-ssm-demo-vpc.id

  tags = {
    Name        = "DBT-Redshift-SSM-Demo-SG"
    Environment = var.env
  }
}
# Redshift Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "dbt-redshift-ssm-demo-ingress" {
  security_group_id = aws_security_group.dbt-redshift-ssm-demo-sg.id
  ip_protocol       = "tcp"
  from_port         = 5439
  to_port           = 5439
  cidr_ipv4         = "10.0.0.0/16"
  description       = "Allow Redshift access"
}
# EC2 Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "dbt-redshift-ssm-demo-ec2-ingress" {
  security_group_id = aws_security_group.dbt-redshift-ssm-demo-sg.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "10.0.0.0/16"

  description       = "Allow SSH access"
}

variable "env" {
    description = "Deployment environment"
    type = string
}

output "subnet_ids" {
  value = [
    aws_subnet.dbt-redshift-ssm-demo-subnet-private-az1.id,
    aws_subnet.dbt-redshift-ssm-demo-subnet-private-az2.id,
    aws_subnet.dbt-redshift-ssm-demo-subnet-public-az3.id
  ]
}

output "security_group_id" {
  value = aws_security_group.dbt-redshift-ssm-demo-sg.id  
}