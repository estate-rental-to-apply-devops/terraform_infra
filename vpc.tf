# 1. The Core VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "gitops-estate-vpc"
  }
}

# 2. Internet Gateway (To give public subnets internet access)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "gitops-estate-igw"
  }
}

# 3. Public Subnets (AZ 1 & AZ 2) - For ALB and NAT Gateway
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "gitops-estate-public-eu-west-1a"
    "kubernetes.io/role/elb" = "1" # Required later for AWS Load Balancer Controller
    "kubernetes.io/cluster/gitops-estate-cluster" = "shared"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "gitops-estate-public-eu-west-1b"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/gitops-estate-cluster" = "shared"
  }
}

# 4. Private Subnets (AZ 1 & AZ 2) - For EKS Worker Nodes
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name                              = "gitops-estate-private-eu-west-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/gitops-estate-cluster" = "shared"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name                              = "gitops-estate-private-eu-west-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/gitops-estate-cluster" = "shared"
  }
}

# 5. Elastic IP for the NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "gitops-estate-nat-eip"
  }
}

# 6. Single NAT Gateway (Placed in public_1 to save learning costs)
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "gitops-estate-nat-gw"
  }

}