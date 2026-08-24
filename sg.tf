# 로드밸런서 보안 그룹
# 리소스 정의 - 인그레스 - 아웃그래스
# 테라폼 리솟스며에는 하이픈 보단 _ 사용 추천
resource "aws_security_group" "alb_sg" {
  name          = "terraform-qbank-alb_sg"
  description   = "qbank-alb_sg"
  vpc_id        = module.vpc.vpc_id

  ingress {
    to_port         = 80
    from_port       = 80
    protocol        = "tcp"
    description     = "allow http"
    cidr_blocks     = ["0.0.0.0/0"] 
  } 

  ingress {
    to_port         = 443
    from_port       = 443
    protocol        = "tcp"
    description     = "allow https"
    cidr_blocks     = ["0.0.0.0/0"] 
  } 

  egress {
    to_port         = 0
    from_port       = 0
    protocol        = -1
    description     = "allw in to out"
    cidr_blocks     = ["0.0.0.0/0"] 
  }
}

# ===================
# Front - ec2
# ===================
resource "aws_security_group" "front_sg" {
  name          = "${var.project}-ec2_sg"
  description   = "${var.project}-ec2_sg"
  vpc_id        = module.vpc.vpc_id

  ingress {
    from_port           = 80
    to_port             = 80
    protocol            = "tcp"
    security_groups     = [aws_security_group.alb_sg.id]
    description         = "allow to alb"
  } 
  ingress {
    from_port           = 443
    to_port             = 443
    protocol            = "tcp"
    security_groups     = [aws_security_group.alb_sg.id]
    description         = "allow to alb"
  }
  ingress {
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"
    cidr_blocks         = [var.my_public_ip]
    description         = "allow me"
  } 

  ingress {
    from_port           = 22
    to_port             = 22
    protocol            = "tcp"
    cidr_blocks         = ["10.100.0.0/24"]
    description         = "allow on-pre backup server"
  } 

  ingress {
    from_port           = 9100
    to_port             = 9100
    protocol            = "tcp"
    security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "node exporter"
  } 

  # icmp용 --> 추후 주석처리 가능. 
  ingress {
    from_port           = -1
    to_port             = -1
    protocol            = "icmp"
    cidr_blocks         = ["10.100.0.0/24"]
    #security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "allow icmp from vpn clients"
  } 

  ingress {
    from_port           = -1
    to_port             = -1
    protocol            = "icmp"
    cidr_blocks         = ["10.0.0.0/16"]
    #security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "allow icmp from internal server"
  } 
  
  
  egress {
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
    description         = "allow internal to out"
  }
}
# ===================
# was - lambda
# ===================
resource "aws_security_group" "was_sg" {
  name          = "${var.project}-was_sg"
  description   = "${var.project}-was_sg"
  vpc_id        = module.vpc.vpc_id

  
  egress {
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
    description         = "allow internal to out"
  }
}

# ===================
# DB - rds
# ===================
resource "aws_security_group" "rds_sg" {
  name      = "${var.project}-rds_sg"
  vpc_id    = module.vpc.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    security_groups = [aws_security_group.was_sg.id]
    description     = "allow web"
  }
  egress {
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
    description         = "allow internal to out"
  }
}
# ======================================
# Monitoring - ec2
# ======================================
resource "aws_security_group" "monitor_sg" {
  name      = "${var.project}-moni_ec2_sg"
  vpc_id    = module.vpc.vpc_id

  ingress {
    from_port       = 22  
    to_port         = 22
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = [var.my_public_ip]  # 보안그룹 적을 땐 security_groups
    description     = "allow me ssh"
  }
  
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = [var.my_public_ip]
    description     = "grafana"
  }

  ingress {
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = ["10.0.0.0/16"] # 내부 서버가 loki로 보내고자 할 때 
    description     = "grafana-loki-promtail setting. allow loki from front web servers."
  }
  
  ingress {
    from_port       = 9090  
    to_port         = 9090
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = [var.my_public_ip]
    description     = "allow prometheus"    # 내 ip로 해놓는게 맞나? --> oo. web 콘솔 접속용
  }
  # icmp용 --> 추후 주석처리 가능. 
  ingress {
    from_port           = -1
    to_port             = -1
    protocol            = "icmp"
    cidr_blocks         = ["10.100.0.0/24"]
    #security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "allow icmp from vpn clients"
  } 
  
  egress {
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
    description         = "allow internal to out"
  }
}


# ======================================
# internal_DNS - ec2
# ======================================
resource "aws_security_group" "internal_dns_sg" {
  name      = "${var.project}-internal_dns_sg"
  vpc_id    = module.vpc.vpc_id

  ingress {
    from_port       = 22  
    to_port         = 22
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = [var.my_public_ip]  # 보안그룹 적을 땐 security_groups
    description     = "allow me ssh"
  }
  ingress {
    from_port       = 53  
    to_port         = 53
    protocol        = "udp"
    #security_groups   = [aws_security_group.front_sg.id, aws_security_group.monitor_sg.id, aws_security_group.rds_sg.id, aws_security_group.was_sg.id] #--> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = ["10.0.0.0/16"]
    description     = "allow internal server via UDP"
  }
  # DNS는 기본적으로 UDP를 쓰지만, 512바이트를 초과하거나 특정 쿼리의 경우 TCP 53으로 대체됨. -> 오류 방지를 위해 TCP도 열ㅇ어주기
  ingress {
    from_port       = 53  
    to_port         = 53
    protocol        = "tcp"
    #security_groups   = [aws_security_group.front_sg.id, aws_security_group.monitor_sg.id, aws_security_group.rds_sg.id, aws_security_group.was_sg.id] #--> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = ["10.0.0.0/16"]  # 보안그룹 적을 땐 security_groups사용. 
    description     = "allow internal server via TCP"
  }
  ingress {
    from_port           = 9100
    to_port             = 9100
    protocol            = "tcp"
    security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "node exporter"
  } 
  # icmp용 --> 추후 주석처리 가능. 
  ingress {
    from_port           = -1
    to_port             = -1
    protocol            = "icmp"
    cidr_blocks         = ["10.100.0.0/24"]
    #security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "allow icmp from vpn clients"
  } 
  egress {
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
    description         = "allow internal to out"
  }
}


# ======================================
# VPN - ec2
# ======================================
resource "aws_security_group" "vpn_sg" {
  name      = "${var.project}-vpn_sg"
  vpc_id    = module.vpc.vpc_id

  # 내부 서브들이 vpn을 통해 통신 가능하게 하도록
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "allow routing traffic from VPC to VPN clients"
  }

  # vpn 클라이언트도 ssh 접속 허용할거면, VPN 대역을 허용해줘야 함. 
  ingress {
    from_port       = 22  
    to_port         = 22
    protocol        = "tcp"
    #cidr_blocks   = [aws_security_group.ec2_sg.id] --> 보안 그룹을 지정할 때는 security_groups를 사용
    cidr_blocks = [var.my_public_ip]  # 보안그룹 적을 땐 security_groups
    description     = "allow me ssh"
  }

  ingress {
    from_port           = 9100
    to_port             = 9100
    protocol            = "tcp"
    security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "node exporter"
  } 

  # ** vpn 포트 ***
  ingress {
    from_port           = 51820
    to_port             = 51820
    protocol            = "udp"
    cidr_blocks         = [var.my_public_ip]
    #security_groups     = [ aws_security_group.monitor_sg.id ] #모니터링을 위한 규칙 추가
    description         = "node exporter"
  } 
  
  egress {
    from_port           = 0
    to_port             = 0
    protocol            = -1
    cidr_blocks         = ["0.0.0.0/0"]
    description         = "allow internal to out"
  }
}