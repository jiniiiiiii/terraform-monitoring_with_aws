# 터미널에 출력할 값
output "ec2-pub-ip" {
  description = "value"
  #value = aws_instance.web-ec2.public_ip 
  value = {
    web_01 = module.ec2_web.public_ip
    #web_02 = module.ec2_web_02.public_ip
    web_03 = module.ec2_web_03.public_ip
    monitor = module.ec2_mornitoring.public_ip
    internal_dns = module.ec2_internal_dns.public_ip
    vpn = module.ec2_vpn_wireguard.public_ip
    db  = module.ec2_db.public_ip
  }
}



# 이름 문제인가? 
# output "function_url" {
#   description = "The Lambda Function URL"
#   value       = aws_lambda_function_url.backend_lambda.function_url
# }

# 얘도 이름 문제인가...  -> 문법 오류
# alb는 dns_name 속성을 사용함. 
# │ This object has no argument, nested block, or exported attribute named "elb_dns_name".
output "alb_url" {
  description = "URL of load balancer"
  value       = "http://${aws_alb.public_alb.dns_name}/"
}


output "monitor_url" {
  description = "URL of MONITOR URL"
  value       = "http://${module.ec2_mornitoring.public_ip}:3000"
}