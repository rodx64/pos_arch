resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = local.internet_cidr
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = var.enable_nat ? length(var.private_subnets) : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = local.internet_cidr
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}

resource "aws_route_table_association" "private" {
  count = var.enable_nat ? length(var.private_subnets) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
