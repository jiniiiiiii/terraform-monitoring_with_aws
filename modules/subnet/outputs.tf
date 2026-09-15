output "subnet_id" {
  description = "생성된 서브넷의 ID 값"
  value = aws_subnet.subnet.id
}

output "cidr_block" {
  description = "서브넷 사이다 블록 값"
  value = aws_subnet.subnet.cidr_block
}

output "cidr_blocks" {
  description = "서브넷 사이다 블록 값 (복수형 호환)"
  value = aws_subnet.subnet.cidr_block
}