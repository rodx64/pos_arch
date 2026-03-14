resource "aws_eip" "nat" {
  count = var.enable_nat ? length(var.public_subnets) : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat ? length(var.public_subnets) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = var.name
  })
}
