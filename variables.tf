# =================================
# vpc
# =================================
variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr_blocks" {
  type = map(string)
  default = {
    pub-a-1 = "10.0.1.0/24"
    pub-c-1 = "10.0.2.0/25"
    pub-c-2 = "10.0.2.128/25"
    pri-a-1 = "10.0.10.0/24"
    pri-c-1 = "10.0.20.0/24"
  }
}


# =================================
# Iam 권한 경계
# =================================
variable "boundary_role" {
    description = "권한 경계 정책"
    type        = string
    default     = "arn:aws:iam::545738259208:policy/terraform-max-boundary"
  
}


variable "environment" {
  type          = string
  default       = "dev"
}

# rds 변수 -> tfvars 이용
variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
  #default = "" 로 정의하는게 아니라 그냥 type 정도만 선언하면 됨. 
  sensitive = true  # 이 옵션 사용하면 비번이 안 가려지고 노출되는걸 막아줌. 
}

variable "db_name" {
  type = string
  default = "terraform_db"
}


variable "my_public_ip" {
  type = string
}