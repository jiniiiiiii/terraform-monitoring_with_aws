# data 정의
data "aws_ami" "amazon_linux" {
  most_recent           = true
  owners                =["137112412989"] 

  filter {
    name        = "name"
    values      = ["al2023-ami-2023.12.20260611.0-kernel-6.*-x86_64"] 
  } 
}

# 설정 파일 변수
locals {
  common_setting = file("${path.root}/modules/user_data/common.sh")
  prometheus_setting = file("${path.root}/modules/user_data/grafana/prometheus_setting.yml")
  loki_config = file("${path.root}/modules/user_data/loki/loki-config.yml")
  s_pri_key = file("${path.root}/modules/user_data/key/s_pri.key")
  c_pub_key = file("${path.root}/modules/user_data/key/c_pub.key")
  named_conf = file("${path.root}/modules/user_data/dns/named.conf")
}
# ===============================================================
# EC2 
# ===============================================================
resource "aws_instance" "ec2" {
  ami               = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type

  # * IAM 인스턴스 profile 연결
  iam_instance_profile = var.ec2-profile   # string 타입은 name 알아서 지정되기 때문에 .name 붙일 필요 없음 

  #네트워크 정의
  subnet_id                  = var.subnet_id  #단일 값으로 넘겨 받았음. 
  vpc_security_group_ids     = var.security_group_id  # 리스트 형식 변수는 .id xx 
    # 이미 main.tf에서 리스트 형태로 넘겨줌. --> security_group_id   = [aws_security_group.front-sg.id]

  # private_ip static 설정
  private_ip = var.private_ip

  #key
  key_name             = "${var.project}-key"

  # public ip 할당 ? 
  associate_public_ip_address = var.pub_ip_associate_bool #var.pub_ip_associate_bool #true
  
  # 람다가 먼저 선언되어야 하므로 의존성 추가 --> 변수로 적어놨으므로 알아서 될 듯 ? 
  #depends_on = [ var.api-lambda-url ]

  # 쉘 스크립트 :user_data
  #  변수 쓸거면 \이나 `<<'FIN'` 으로 해줘야함. 안 그러면 테라폼 변수인 줄 알고, 맘대로 지워버릴 수 있음? 
  #user_data = <<EOF
  #user_data = templatefile("${path.module}/user_data.nginx.tpl", {
  /*
  -  ${path.root} user_data가 같은 위치에 있는게 아니므로 root 이용
  */
  
  # 목적지/소스 설정 해제 . defualt = true
  source_dest_check = var.source_dest_check_bool

  user_data = templatefile(
    "${path.root}/modules/user_data/${var.user_data_file}", # 파일명을 변수로 동적으로 가져옴. 
    {
      # 파일명에 따라서 알아서 변수 주입. 즉, tpl에 해당 변수가 없어도 ㄱㅊ
      lambda_url = var.api-lambda-url   # user_data안에 입력할 변수 
      server_name = var.instance_name
      common_setting = templatefile("${path.root}/modules/user_data/common.sh", {
        promtail_config = file("${path.root}/modules/user_data/promtail-config/${var.promtail_conf}")
      })
      prometheus_setting = local.prometheus_setting
      loki_config = local.loki_config
      s_pri_key = local.s_pri_key
      c_pub_key = local.c_pub_key
      promtail_conf = var.promtail_conf
      named_conf = local.named_conf

    # 대시보드 파일 관련 --> 나중에 s3로 관리할 수도 있음. 근데 이미 용량이 커서;; s3로 업로드
    # dashboard_web_json = file("${path.root}/userdata/grafana/dashboard-web.json")
    # dashboard_all_json = file("${path.root}/userdata/grafana/dashboard-all.json")
    }  
    )
  
  # user_data 변경 시 인스턴스 부수고 재생성
  user_data_replace_on_change = true

  tags = {
    Name        = var.instance_name
    Project     = var.project
    environment = var.environment
  }
}


# ===============================================================
# TG 자동 연결
# ===============================================================
resource "aws_alb_target_group_attachment" "pub_alb_tg_attach" {
  # target_group_arn이 입력되었을 때만 연결 리소스를 생성
  count = var.associate_alb ? 1:0   #공백이 아니고, 1부터 0까지의 수로 시작할 때
  
  #target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
  target_group_arn  = var.target_group_arn
  #target_id         = module.ec2_web_03.web-ec2-id
  target_id         = aws_instance.ec2.id # 모듈 내부에서 본인 인스턴스 ID 지정
  port              = 80 
}

