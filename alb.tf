# [필요]
# 보안 그룹 
# 서브넷 
resource "aws_alb" "public_alb" {
  name                      = "${var.project}-public-alb"
  internal                  = false     # 외부 인터넷에서 접근 가능하게. 외부용이라는 뜻
  load_balancer_type        = "application"
  security_groups           = [aws_security_group.alb_sg.id]
  # vpc_security_groups_ids는 ec2 정의할 때
  
  # **서브넷 id를 넣어야 함. 대역대 넣는거 xxx
  subnets                   = module.vpc.subnet-id_web_pub
}

# 타겟 그룹 정의 
resource "aws_alb_target_group" "pub_alb_tg" {
  name        = "${var.project}-public-tg"
  port        = 80
  protocol    = "HTTP"  # 대문자로 적어주기
  #vpc_id      = aws_vpc.main.id  
  vpc_id      = module.vpc.vpc_id 

## health check 확인
  health_check {
    path      = "/"
    protocol  = "HTTP"
    matcher   = "200"     # 정상 응답 기준. 
    interval  = 30        # 검사 주기
    timeout   = 5         # 타임아웃은 5초
    healthy_threshold   = 2     # 정상 판단 : 
    unhealthy_threshold = 2   # 비정상 판단 : 2회 연속 응답 실패
  }
}

# 리스너 리소스 정의 
resource "aws_alb_listener" "pub_alb_listener" {   # 수신할 포트랑, 프로토콜 종류 정의
  load_balancer_arn = aws_alb.public_alb.arn    # q. .id랑 .arn 뭐가 다른걸까
  port              = "80"
  protocol          = "HTTP"

  default_action {    # 위에 정의한 조건으로 들어왔을 때 수행할 작업
    type              = "forward"   # 그대로 넘김. 다른 곳으로 리다이렉트나 차단 x 
    target_group_arn  = aws_alb_target_group.pub_alb_tg.arn 
  } 
}


# 3단계. ec2를 타겟 그룹에 묶어버리기 ==> ec2 모듈 안으로 이동. 
# 자동으로 관리 되게끔 하기 위해
# 1번 서버 연결
# resource "aws_alb_target_group_attachment" "pub_alb_tg_attach_01" {
#   target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
#   target_id         = module.ec2_web.web-ec2-id
#   port              = 80 
# }
# 2번 서버 연결
# resource "aws_alb_target_group_attachment" "pub_alb_tg_attach_02" {
#   target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
#   target_id         = module.ec2_web_02.web-ec2-id
#   port              = 80 
# }
# # 3번 서버 연결
# resource "aws_alb_target_group_attachment" "pub_alb_tg_attach_03" {
#   target_group_arn  = aws_alb_target_group.pub_alb_tg.arn
#   target_id         = module.ec2_web_03.web-ec2-id
#   port              = 80 
# }
