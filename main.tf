#===========================
# vpc 호출
#===========================
# is required, but no definition was found. 이면 어떡하지 ? --> 불필요한 변수는 정리하면 됨. 안 쓰는데 적혀있으니까 필요하다고 하는거임. 

module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = var.vpc_cidr_block
  subnet_cidr_blocks = var.subnet_cidr_blocks 
  #dns_server_pri_ip = "10.0.1.53"
} 

#vpn 클라이언트용 라우팅 추가 --> 추후에 pri용도 생성 가능
resource "aws_route" "vpn_client_network" {
  route_table_id = module.vpc.pub_rt_id
  destination_cidr_block = "10.100.0.0/24"
  network_interface_id = module.ec2_vpn_wireguard.vpn_eni_id
}

#===========================
# EC2
#===========================
/* ----- web ---- */
module "ec2_web" {
  source           = "./modules/ec2"

  instance_name    = "${var.project}-web_server_01" # var. 누락되었던 부분 수정
  instance_type    = "t3.micro"
  #ami_id           = "ami-12345678"  # 예시 AMI ID
  
  security_group_id = [aws_security_group.front_sg.id]  # 직접 참조
  #security_group_id = module.security_group.security_group_id # 모듈 사용하는 경우
  subnet_id         = module.vpc.subnet-id_pub[0]
  private_ip        = "10.0.1.10"
  pub_ip_associate_bool = true
  user_data_file    = "web-server.tpl" # /user_data/ 뒤의 파일명만 전달
  source_dest_check_bool = true
  
  ec2-profile       = aws_iam_instance_profile.ec2-profile.name
  api-lambda-url    = aws_lambda_function_url.api-lambda-url.function_url # .function_url로 전달
  target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  associate_alb     = true
  promtail_conf = "promtail_web_config.sh"
}

module "ec2_web_02" {
  source           = "./modules/ec2"

  instance_name    = "${var.project}-web_server_02" # var. 누락되었던 부분 수정
  instance_type    = "t3.micro"
  #ami_id           = "ami-12345678"  # 예시 AMI ID
  
  security_group_id = [aws_security_group.front_sg.id]  # 직접 참조
  #security_group_id = module.security_group.security_group_id # 모듈 사용하는 경우
  subnet_id         = module.vpc.subnet-id_pub[0]
  private_ip        = "10.0.1.11"
  pub_ip_associate_bool = true
  source_dest_check_bool = true
  user_data_file    = "web-server.tpl" # /user_data/ 뒤의 파일명만 전달
  
  ec2-profile       = aws_iam_instance_profile.ec2-profile.name
  api-lambda-url    = aws_lambda_function_url.api-lambda-url.function_url # .function_url로 전달
  target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  associate_alb     = true
  promtail_conf = "promtail_web_config.sh"
}

module "ec2_web_03" {
  source           = "./modules/ec2"

  instance_name    = "${var.project}-web_server_03" # var. 누락되었던 부분 수정
  instance_type    = "t3.micro"
  #ami_id           = "ami-12345678"  # 예시 AMI ID
  
  security_group_id = [aws_security_group.front_sg.id]  # 직접 참조
  #security_group_id = module.security_group.security_group_id # 모듈 사용하는 경우
  subnet_id         = module.vpc.subnet-id_pub[1]
  private_ip        = "10.0.2.10"
  pub_ip_associate_bool = true
  source_dest_check_bool = true
  user_data_file    = "web-server.tpl" # /user_data/ 뒤의 파일명만 전달
  
  ec2-profile       = aws_iam_instance_profile.ec2-profile.name
  api-lambda-url    = aws_lambda_function_url.api-lambda-url.function_url # .function_url로 전달
  target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  associate_alb     = true
  promtail_conf = "promtail_web_config.sh"
}


/* ----- Mornitoring ---- */
module "ec2_mornitoring" {
  source           = "./modules/ec2"

  instance_name    = "${var.project}-monitoring_server" 
  instance_type    = "m7i-flex.large" # 8기가 램
  #ami_id           = "ami-12345678"  # 예시 AMI ID
  
  security_group_id = [aws_security_group.monitor_sg.id]  # 직접 참조
  #security_group_id = module.security_group.security_group_id # 모듈 사용하는 경우
  subnet_id         = module.vpc.subnet-id_pub[1]
  private_ip        = "10.0.2.100"
  pub_ip_associate_bool = true
  source_dest_check_bool = true
  user_data_file    = "monitor-server.tpl" # /user_data/ 뒤의 파일명만 전달
  
  ec2-profile       = aws_iam_instance_profile.ec2-profile.name
  api-lambda-url    = aws_lambda_function_url.api-lambda-url.function_url # .function_url로 전달
  target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  associate_alb     = false   #false 일 경우 생략 가능
  promtail_conf = "promtail_ssh_config.sh"
} 


/* ----- DNS ---- */
module "ec2_internal_dns" {
  source           = "./modules/ec2"

  instance_name    = "${var.project}-internal_dns" 
  instance_type    = "t3.micro" 
  #ami_id           = "ami-12345678"  # 예시 AMI ID
  
  security_group_id = [aws_security_group.internal_dns_sg.id]  # 직접 참조
  #security_group_id = module.security_group.security_group_id # 모듈 사용하는 경우
  subnet_id         = module.vpc.subnet-id_pub[0]
  private_ip        = "10.0.1.53"
  pub_ip_associate_bool = true
  source_dest_check_bool = true
  user_data_file    = "internal-dns-server.tpl" # /user_data/ 뒤의 파일명만 전달
  
  ec2-profile       = aws_iam_instance_profile.ec2-profile.name
  api-lambda-url    = aws_lambda_function_url.api-lambda-url.function_url # .function_url로 전달
  target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  associate_alb     = false   #false 일 경우 생략 가능
  promtail_conf = "promtail_dns_config.sh"
} 


/* -----  VPN - WireGuard ---- */
module "ec2_vpn_wireguard" {
  source           = "./modules/ec2"

  instance_name    = "${var.project}-vpn_wireguard" 
  instance_type    = "t3.micro" # 8기가 램
  #ami_id           = "ami-12345678"  # 예시 AMI ID
  
  security_group_id = [aws_security_group.vpn_sg.id]  # 직접 참조
  #security_group_id = module.security_group.security_group_id # 모듈 사용하는 경우
  subnet_id         = module.vpc.subnet-id_pub[2]
  private_ip        = "10.0.2.200"
  pub_ip_associate_bool = true
  source_dest_check_bool = false
  user_data_file    = "vpn-server.tpl" # /user_data/ 뒤의 파일명만 전달
  
  ec2-profile       = aws_iam_instance_profile.ec2-profile.name
  api-lambda-url    = aws_lambda_function_url.api-lambda-url.function_url # .function_url로 전달
  target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  associate_alb     = false   #false 일 경우 생략 가능
  promtail_conf = "promtail_vpn_config.sh"
} 