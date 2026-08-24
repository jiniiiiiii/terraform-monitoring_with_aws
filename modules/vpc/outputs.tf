# =============================
# VPC_id
# =============================
output "vpc_id" {   # 밖에서 참조할 값은 vpc_id로 써야 함. 
  value = aws_vpc.main.id
}

# =============================
# subnet_id
# =============================
/*서브넷 모듈화 방법
1. 리스트 형식이용
-> 사용시 subnet_id = module.vpc.subnet_ids[0] 이렇게 쓰면 됨. 

2. 혹은 개별 outputs 일일히 생성 
-> 모듈화 시키기 전처럼 이름으로 접근 가능

=> 저는 리스트 형식 채택
*/ 

# alb 용 서브넷
output "subnet-id_web_pub" {
  value = [ 
    aws_subnet.public-a-1.id,
    aws_subnet.public-c-1.id
  ]

  # 의존성 추가 --> rt연결 완료될 때까지 출력 x. 혹시 모를 네트워크 에러 예방
  depends_on = [  
    aws_route_table_association.pub-a-association,
    aws_route_table_association.pub-c-association
  ]
}

# 일반용 퍼블릭 서브넷
output "subnet-id_pub" {
  value = [ 
    aws_subnet.public-a-1.id,
    aws_subnet.public-c-1.id,
    aws_subnet.public-c-2.id
  ]

  # 의존성 추가 --> rt연결 완료될 때까지 출력 x. 혹시 모를 네트워크 에러 예방
  depends_on = [  
    aws_route_table_association.pub-a-association,
    aws_route_table_association.pub-c-association
  ]
}

output "subnet-id_pri" {
  value = [ 
    aws_subnet.private-a-1.id,
    aws_subnet.private-c-1.id
  ]
}

# vpn 라우팅 추가용 서브넷
output "pub_rt_id" {
  value = aws_route_table.pub-rt.id
}

# =============================
# igw_id & ngw_id
# =============================
output "igw_id" {
  value = aws_internet_gateway.igw.id
}

output "ngw_id" {
  value = aws_nat_gateway.pub_nat_gw.id
}
