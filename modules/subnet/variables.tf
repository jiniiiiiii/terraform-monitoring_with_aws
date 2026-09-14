variable "vpc_id" {
  default = ""
}

variable "cidr_block" {
  default = ""
}

variable "az" {
  default = ""
}
variable "subnet_name" {
  default = ""
}
variable "route_table_id" {
  default = ""
}

# =================================
# tags 
# =================================
variable "project" {
  default = "terraform"
}