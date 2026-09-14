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
