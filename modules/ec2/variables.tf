#===========================
# 리소스 네이밍 관련
#===========================
variable "project" {
  type    = string
  default = "terraform"
}

variable "environment" {
  type    = string
  default = "dev"
}
 
#===========================
# 인스턴스 생성 관련
#===========================
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "instance_name" {
  type = string
}

variable "ec2-profile" {
  type = string
}

variable "security_group_id" {
  type = list(string)
}

variable "subnet_id" {
  type = string
  description = "subnet_id = module.vpc.subnet-id_pub[0]으로 넘겨 받음."
}



# variable "subnet_cidr_blocks" {
#   type = string
# }

variable "user_data_file" {
  type = string
}

variable "private_ip" {
  description = "static private ip"
  type = string
}

variable "pub_ip_associate_bool" {
  description = "associate pub ip true or false"
  type = bool
}

variable "source_dest_check_bool" {
  description = "source_dest_check ture or false"
  type = bool
}

variable "promtail_conf" {
  description = "promtail_conf file name"
  type = string
}

#===========================
# 추가로 필요할 리소스 변수
#===========================
variable "api-lambda-url" {
  type        = string
  default     = ""
  description = "Nginx 템플릿에 주입할 Lambda Function URL"
}

# alb target group
variable "target_group_arn" {
  type = string
  description = "target_group_arn"
  default = ""  #기본 값을 빈 값으로 둬서 연결 안되게 할 수도 있음. 
}

# 타겟그룹을 위한... 참/거짓 판단. 
variable "associate_alb" {
  type        = bool
  default     = false # 기본값은 연결하지 않음
  description = "ALB 타겟 그룹에 연결할지 여부"
}

# DB 설정 변수 (기본값 "" 지정으로 다른 EC2 모듈에서는 선언 생략 가능)
variable "db_username" {
  type        = string
  default     = ""
  description = "DB 사용자 이름"
}

variable "db_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "DB 비밀번호"
}

variable "db_name" {
  type        = string
  default     = ""
  description = "DB 이름"
}


