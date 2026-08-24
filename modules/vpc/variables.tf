/*
이번에 똑같은 인프라를 싱가포르 리전에 하나 더 만들어주세요. 
--> 일일이 주소를 고쳐야 함. 
*/

# 리소스 명명 규칙 : "${var.project}-resourceName"

variable "aws_region" {
    description = "aws 기본 리전"
    type        = string
    default     = "ap-northeast-3"  //설정 값을 적어 줌. 
}



# 네트워크 변수
variable "vpc_cidr_block" {
    description = "vpc 기본 네트워크 대역"
    type        = string
}

locals {
  zone-a = "${var.aws_region}a"
  zone-c = "${var.aws_region}c"
}

variable "subnet_cidr_blocks" {
  type = map(string)
}

# dns 인스턴스 변수
# variable "dns_server_pri_ip" {
#   description = "dns서버의 프라이빗 ip"
#   type = string
# }


# =============================
# tag 변수
# =============================

variable "project" {
    type    = string
    default = "terraform"
  
}

variable "environment" {
  type          = string
  default       = "dev"
}
