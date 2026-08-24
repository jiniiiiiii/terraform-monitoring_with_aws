output "web-ec2-id" {
  #value = aws_instance.web-ec2  #인스턴스ID가 아닌 객체 전체를 출력하는거임. 
  value = aws_instance.ec2.id
}

# public  ip 출력
output "public_ip" {
  description = "생성한 ec2의 퍼블릭 ip"
  value = aws_instance.ec2.public_ip
}

# vpn eni
output "vpn_eni_id" {
  value = aws_instance.ec2.primary_network_interface_id
}