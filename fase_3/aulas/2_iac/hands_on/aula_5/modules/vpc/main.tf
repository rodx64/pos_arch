resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(var.common_tags, { Name = var.name })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.name}-igw" })
}

# Cria subnets públicas mapeadas por AZ
resource "aws_subnet" "public" {
  for_each = { for idx, az in toset(var.azs) : az => idx }

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = var.public_subnet_cidrs[length(var.public_subnet_cidrs) > 0 ? each.value : 0] != null ? var.public_subnet_cidrs[each.value] : cidrsubnet(var.cidr_block, 8, each.value)
  map_public_ip_on_launch = true
  tags = merge(var.common_tags, {
    Name = "${var.name}-public-${each.key}"
    Tier = "public"
  })
}

# Tabela de rotas pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.common_tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
