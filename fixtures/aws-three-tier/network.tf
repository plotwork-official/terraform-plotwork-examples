# A three-tier web application on AWS. This folder is read as text by the
# examples and never applied: it needs no AWS account.

resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  tags                 = { Name = "shop-vpc" }
}

resource "aws_subnet" "public" {
  for_each          = { a = "10.20.0.0/24", b = "10.20.1.0/24" }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "ap-southeast-2${each.key}"
}

resource "aws_subnet" "private" {
  for_each          = { a = "10.20.10.0/24", b = "10.20.11.0/24" }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "ap-southeast-2${each.key}"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "main" {
  subnet_id     = aws_subnet.public["a"].id
  allocation_id = aws_eip.nat.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}
