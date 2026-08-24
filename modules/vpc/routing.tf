# ============= pub rt ===========
resource "aws_route_table" "pub-rt" {
    vpc_id              = aws_vpc.main.id
    
    # route리소스는 새로운 라우팅 경로가 추가되면서 오류를 일으킴. 독립적으로 뺀다. 
    # route {
    #     cidr_block = "0.0.0.0/0"
    #     gateway_id = aws_internet_gateway.igw.id
    # } 
    # # vpn 클라이언트 네트워크 --> 근데 이렇게 하는 것보다 main.tf에서 선언하는게 훨씬 간단
    # output "pub_rt_id"로 value = aws_route_table.pub-rt.id 를 뺀다. 
    # route {
    #     cidr_block = "10.100.0.0/24"
    #     network_interface_id = vpn인스턴스.primary_network_interface_id
    # }
  
    tags = {
      Name      = "${var.project}-pub-rt"
    }
}

resource "aws_route" "pub_default_route" {
    route_table_id         = aws_route_table.pub-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "pub-a-association" {
    subnet_id           = aws_subnet.public-a-1.id
    route_table_id   = aws_route_table.pub-rt.id  
}
resource "aws_route_table_association" "pub-c-association" {
    for_each = {
        pub_c_1 = aws_subnet.public-c-1.id
        pub_c_2 = aws_subnet.public-c-2.id
    }
    subnet_id          = each.value
    route_table_id   = aws_route_table.pub-rt.id  
}


# ============= pri rt ===========
resource "aws_route_table" "pri-rt" {
    vpc_id              = aws_vpc.main.id

    # nat gw를 위한 라우팅 경로 생성 --> 독립적인 resource로 분리
    # route {
    #     cidr_block = "0.0.0.0/0"
    #     nat_gateway_id = aws_nat_gateway.pub_nat_gw.id
    # }

    tags = {
      Name      = "${var.project}-pri-rt"
    }
}
resource "aws_route" "pri_default_route" {
    route_table_id         = aws_route_table.pri-rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.pub_nat_gw.id
}

resource "aws_route_table_association" "pri-a-association" {
    subnet_id           = aws_subnet.private-a-1.id
    route_table_id   = aws_route_table.pri-rt.id  
}
resource "aws_route_table_association" "pri-c-association" {
    subnet_id           = aws_subnet.private-c-1.id
    route_table_id   = aws_route_table.pri-rt.id  
}