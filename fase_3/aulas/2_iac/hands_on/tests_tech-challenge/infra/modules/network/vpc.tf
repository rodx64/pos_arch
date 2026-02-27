resource "aws_vpc" "this" {
  cidr_block = var.cidr

  tags = merge(var.tags, {
    Name = var.name
  })
}
