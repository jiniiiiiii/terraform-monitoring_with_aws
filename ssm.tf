# iam에 ssm중 /qbank/* 인 것만 권한이 있게끔 설정했으므로, 이름을 통일하게 해줘야함. 
# SSM 생성도 다시 ? 
resource "aws_ssm_parameter" "ssm_db_host" {
  name  = "/qbank/db_host"
  type  = "String"
  value = module.ec2_db.private_ip
}


resource "aws_ssm_parameter" "ssm_db_user" {
  name  = "/qbank/db_user"
  type  = "String"
  value = var.db_username
}

resource "aws_ssm_parameter" "ssm_db_password" {
  name  = "/qbank/db_password"
  type  = "SecureString"
  value = var.db_password
}

resource "aws_ssm_parameter" "ssm_db_name" {
  name  = "/qbank/db_name"
  type  = "String"
  value = var.db_name
}