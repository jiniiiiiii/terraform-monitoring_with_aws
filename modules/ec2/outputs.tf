output "web-ec2-id" {
  value = aws_instance.ec2.id
}

# public ip 출력
output "public_ip" {
  description = "생성한 ec2의 퍼블릭 ip"
  value       = aws_instance.ec2.public_ip
}

# vpn eni
output "vpn_eni_id" {
  value = aws_instance.ec2.primary_network_interface_id
}

# private ip 출력
output "private_ip" {
  description = "생성한 ec2의 프라이빗 ip"
  value       = aws_instance.ec2.private_ip
}