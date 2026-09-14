# ==========================================
# 1. Internet Gateway (IGW) & 퍼블릭 라우팅
# ==========================================
resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name    = "${var.project}-igw"
    Project = var.project
  }
}

# 퍼블릭 라우팅 테이블에 IGW 기본 경로(0.0.0.0/0) 연결
resource "aws_route" "pub_default_route" {
  route_table_id         = module.vpc.pub_rt_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}


# ==========================================
# 2. NAT Gateway (NGW) & 프라이빗 라우팅
# ==========================================
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Project = var.project
    Name    = "${var.project}-eip_ngw"
  }
}

resource "aws_nat_gateway" "pub_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = module.subnet_pub_service_a_1.subnet_id  # 새로 만든 퍼블릭 서브넷 ID 연결
  private_ip    = "10.0.1.4"

  tags = {
    Project = var.project
    Name    = "${var.project}-ngw"
  }
}

# 프라이빗 라우팅 테이블에 NAT Gateway 기본 경로(0.0.0.0/0) 연결
resource "aws_route" "pri_default_route" {
  route_table_id         = module.vpc.pri_rt_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.pub_nat_gw.id
}
