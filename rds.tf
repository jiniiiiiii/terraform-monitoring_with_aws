/*
resource "aws_db_instance" "db-instance" {
    allocated_storage       = 20
    engine                  = "mysql"
    engine_version          = "8.0"
    instance_class          = "db.t3.micro"
    db_name                 = var.db_name
    username                = var.db_username
    password                = var.db_password
    db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
    vpc_security_group_ids  = [aws_security_group.rds_sg.id]
    skip_final_snapshot     = true      #1. 삭제할 때 백업 스냅샷 생성을 생략하고 바로 지워버림
}

# =============================
# # db용 서브넷 그룹
# =============================
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.project}-db-subnet_group"
  description = "rds subnetgroup"

  # 서브넷을 묶어 줌
  subnet_ids = module.vpc.subnet-id_pri
  tags = {
    Name      = "${var.project}-db-subnet_group"
    Project   = var.project
  }
}
*/
