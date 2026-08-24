# =============================
# VPC
# =============================
resource "aws_vpc" "main" {
  cidr_block            = var.vpc_cidr_block
  enable_dns_hostnames  = true

  tags = {
    Name        = "${var.project}-vpc-main"
    Project     = var.project
    environment = var.environment
  }
}
# 네임서버 세팅 --> user_data 안 각 코드에 마지막 줄에 resolvectl 쓰는게.. 
# resource "aws_vpc_dhcp_options" "internal" {
#   domain_name = "dev.internal"
#   domain_name_servers = [var.dns_server_pri_ip]
#   depends_on = [  ]
  
# }

# resource "aws_vpc_dhcp_options_association" "internal" {
#   vpc_id = aws_vpc.main.id
#   dhcp_options_id = aws_vpc_dhcp_options.internal.id
#   depends_on = [  ]
# }




# =============================
# igw
# =============================
resource "aws_internet_gateway" "igw" {
  vpc_id        = aws_vpc.main.id

  tags = {
    Name            = "${var.project}-igw"
    Project         = var.project
  }
}
# =============================
# NAT gateway --> public . EIP도 필요함. 
# =============================
resource "aws_nat_gateway" "pub_nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public-a-1.id
  private_ip = "10.0.1.4"

  # 의존성은 뭐지? 인터넷 게이트웨이 위해서 추천한다고? 
  # --> igw 만들고 나서 nat 만들도록 설정
  depends_on = [ aws_internet_gateway.igw ]


  tags = {
    Project = var.project
    Name    = "${var.project}-ngw"
  }
}

# eip_nat
resource "aws_eip" "nat_eip" {
  domain = "vpc"    # vpc 환경에서 사용하도록 지정

  tags = {
    Project = var.project
    Name    = "${var.project}-eip_ngw"
  }
}

# =============================
# 서브넷
# =============================
# ----------- 퍼블릭 -----------
resource "aws_subnet" "public-a-1" {
  vpc_id            = aws_vpc.main.id
  #cidr_block        = var.pub-a-1
  cidr_block        = var.subnet_cidr_blocks["pub-a-1"] # map 사용했기 때문에 key로 이름 지정해주면 됨. 
  availability_zone = local.zone-a
  tags = {
    Name            = "${var.project}-pub-a-1"
    Project         = var.project
  }
}

resource "aws_subnet" "public-c-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_blocks["pub-c-1"]
  availability_zone = local.zone-c

  tags = {
    Name            = "${var.project}-pub-c-1"
    Project         = var.project
  }
}

resource "aws_subnet" "public-c-2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_blocks["pub-c-2"]
  availability_zone = local.zone-c

  tags = {
    Name            = "${var.project}-pub-c-2"
    Project         = var.project
  }
}

# ----------- 프라이빗 -----------
resource "aws_subnet" "private-a-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_blocks["pri-a-1"]
  availability_zone = local.zone-a

  tags = {
    Name            = "${var.project}-pri-a-1"
    Project         = var.project
  }
}


resource "aws_subnet" "private-c-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidr_blocks["pri-c-1"]
  availability_zone = local.zone-c

  tags = {
    Name            = "${var.project}-pri-c-1"
    Project         = var.project
  }
}

