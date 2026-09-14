resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = var.cidr_block        # 변수로 받음 (EC2의 private_ip와 동일)
  availability_zone = var.az                # 변수로 받음
  
  tags = {
    Name    = "${var.project}-${var.subnet_name}"
    Project = var.project
  }
}
# 라우팅 테이블 연결 껍데기
resource "aws_route_table_association" "association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route_table_id      # 퍼블릭/프라이빗 RT ID 전달받음
}
