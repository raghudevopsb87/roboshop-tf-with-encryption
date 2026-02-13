resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.env
  }
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet
  tags = {
    Name = "public"
  }
  availability_zone = var.availability_zone_names[0]
}

resource "aws_subnet" "private" {
  count  = length(var.private_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.private_subnets[count.index]
  availability_zone = var.availability_zone_names[count.index]
  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "lb" {
  count  = length(var.lb_subnets)
  vpc_id = aws_vpc.main.id
  cidr_block = var.lb_subnets[count.index]
  availability_zone = var.availability_zone_names[count.index]
  tags = {
    Name = "lb"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "lb" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "lb"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count  = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "lb" {
  count  = length(var.lb_subnets)
  subnet_id      = aws_subnet.lb[count.index].id
  route_table_id = aws_route_table.lb.id
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.env
  }
}

resource "aws_eip" "ngw" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = var.env
  }
}

resource "aws_route" "public-igw" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}

resource "aws_route" "lb-igw" {
  route_table_id            = aws_route_table.lb.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.igw.id
}

resource "aws_route" "private-ngw" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id            = aws_nat_gateway.ngw.id
}

resource "aws_vpc_peering_connection" "peering-to-default-vpc" {
  peer_vpc_id   = aws_vpc.main.id
  vpc_id        = var.default_vpc_id
  auto_accept   = true
}

resource "aws_route" "private-peering" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.default_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peering-to-default-vpc.id
}

resource "aws_route" "default-vpc-peering" {
  route_table_id            = var.default_vpc_rt
  destination_cidr_block    = var.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering-to-default-vpc.id
}


