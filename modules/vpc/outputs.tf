# =============================
# 1. VPC ID (서브넷, 보안그룹 등에서 필수 참조)
# =============================
output "vpc_id" {
  value = aws_vpc.main.id
}

# =============================
# 2. 라우팅 테이블 ID (서브넷 모듈에 넘겨줄 때 필수)
# =============================
output "pub_rt_id" {
  value = aws_route_table.pub-rt.id
}

output "pri_rt_id" {
  value = aws_route_table.pri-rt.id
}


