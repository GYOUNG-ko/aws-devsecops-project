# resource "aws_vpc" "main" {
#   cidr_block = var.vpc_cidr

#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = merge(var.tags, {
#     Name      = var.name
#     Component = "network"
#   })
# }

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.name]
  }
}

# resource "aws_subnet" "public" {
#   count = length(var.public_subnet_ids)

#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = var.public_subnet_ids[count.index]
#   availability_zone       = var.availability_zones[count.index]
#   map_public_ip_on_launch = true

#   tags = merge(var.tags, {
#     Name                     = "${var.name}-public-${count.index + 1}"
#     "kubernetes.io/role/elb" = "1"
#     Component                = "network"
#   })
# }

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

# resource "aws_subnet" "private" {
#   count = length(var.private_subnet_cidrs)

#   vpc_id            = aws_vpc.main.id
#   cidr_block        = var.private_subnet_cidrs[count.index]
#   availability_zone = var.availability_zones[count.index]

#   tags = merge(var.tags, {
#     Name                              = "${var.name}-private-${count.index + 1}"
#     "kubernetes.io/role/internal-elb" = "1"
#     Component                         = "network"
#   })
# }

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

# resource "aws_internet_gateway" "main" {
#   vpc_id = data.aws_vpc.main.id

#   tags = merge(var.tags, {
#     Name      = "${var.name}-igw"
#     Component = "network"
#   })
# }

data "aws_internet_gateway" "main" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.main.id]
  }
}

# resource "aws_route_table" "public" {
#   vpc_id = data.aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.main.id
#   }

#   tags = merge(var.tags, {
#     Name      = "${var.name}-public-rt"
#     Component = "network"
#   })
# }

data "aws_route_table" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  filter {
    name   = "association.subnet-id"
    values = [each.value]
  }
}

# resource "aws_route_table_association" "public" {
#   count = length(data.aws_subnets.public.ids)

#   subnet_id      = data.aws_subnets.public.ids[count.index]
#   route_table_id = aws_route_table.public.id
# }

# NAT Gateway용 고정 Public IP
# NAT 사용 시에만 생성
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"
  tags = merge(var.tags, {
    Name      = "${var.name}-nat-eip"
    Component = "network"
  })
}

# Private Subnet의 인터넷 Outbound를 위한 NAT Gateway
# 비용 절감을 위해 실습 시에만 활성화
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  # NAT Gateway는 Internet Gateway에 연결 가능한 Pubilic에 배치
  subnet_id = data.aws_subnets.public.ids[0]

  # depends_on = [
  #   aws_internet_gateway.main
  # ]
  tags = merge(var.tags, {
    Name      = "${var.name}-nat"
    Component = "network"
  })
}

# resource "aws_route_table" "private" {
#   vpc_id = data.aws_vpc.main.id

#   tags = merge(var.tags, {
#     Name      = "${var.name}-private-rt"
#     Component = "network"
#   })
# }

data "aws_route_table" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  filter {
    name   = "association.subnet-id"
    values = [each.value]
  }
}

locals {
  private_route_table_ids = toset([for route_table in data.aws_route_table.private : route_table.id])
}

# resource "aws_route_table_association" "private" {
#   count = length(data.aws_subnets.private.ids)

#   subnet_id      = data.aws_subnets.private.ids[count.index]
#   route_table_id = aws_route_table.private.id
# }

# Private Subnet의 인터넷 Outbound 경로
# NAT가 활성화된 경우에만 생성
resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.private_route_table_ids : toset([])

  route_table_id = each.value

  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

data "aws_region" "current" {}

# S3 traffic from private subnets can avoid NAT. Gateway endpoints have no hourly charge.
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_gateway_endpoint ? 1 : 0

  vpc_id            = data.aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = sort(tolist(local.private_route_table_ids))

  tags = merge(var.tags, {
    Name      = "${var.name}-s3"
    Component = "network"
  })
}

check "alb_public_subnets_span_two_availability_zones" {
  assert {
    condition     = length(toset([for subnet in data.aws_subnet.public : subnet.availability_zone])) >= 2
    error_message = "An internet-facing ALB requires tagged public subnets in at least two Availability Zones."
  }
}

check "public_subnets_route_to_internet_gateway" {
  assert {
    condition = alltrue([
      for route_table in data.aws_route_table.public : anytrue([
        for route in route_table.routes :
        try(route.cidr_block, "") == "0.0.0.0/0" &&
        try(route.gateway_id, "") == data.aws_internet_gateway.main.id
      ])
    ])
    error_message = "Every ALB public subnet must have a 0.0.0.0/0 route to the VPC Internet Gateway."
  }
}

