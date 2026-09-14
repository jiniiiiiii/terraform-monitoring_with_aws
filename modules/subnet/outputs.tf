output "subnet_id" {
  description = "생성된 서브넷의 ID 값"
  value = aws_subnet.subnet.id
}