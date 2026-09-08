resource "aws_lambda_function" "backend_lambda" {
  function_name = "terraform-backend-api"
  role          = aws_iam_role.lambda_rds_work_role.arn

  # source를 가져올 s3 지정 
  s3_bucket = "aws-saa-qbank.was-cicd"
  s3_key = "lambda_function.zip"        # S3 내부에 저장된 실제 백엔드 파일 경로(파일명 포함)

  # 핸들러 및 런타임 지정 
  handler = "lambda_function.lambda_handler"     #파일명.함수명 으로 하라는데 ?local_server.py의 lambda_handler 함수
  runtime = "python3.11"

  # 람다 환경 설정
  timeout = 30

  # 삭제할 때 계속 문제 발생해서 아싸리 의존성 박아놔보자. 효과가 있을지? --> 근데 없는 듯 한데.. 
  # depends_on = [ 
  #   aws_security_group.was_sg,
  #   module.vpc.subnet-id_pri,
  #   aws_iam_role_policy_attachment.lambda_rds_vpc_okay,
  #   aws_iam_role_policy_attachment.lambda_s3_readonly,
  #   aws_iam_role_policy_attachment.lambda_basic_execution,
  #   aws_iam_role_policy_attachment.lambda_ssm_attach
  # ]

  environment {
    # 필요한 환경 변수 추가
    variables = {
        ENV                 = "dev"
        DB_HOST             = module.ec2_db.private_ip   # EC2 DB private IP 사용
        #DB_HOST             = aws_db_instance.db-instance.address   # rds 사용할 때 --> # 주소값을 사용해야하므로 address로 받아오기
        DB_USER             = var.db_username
        DB_NAME             = var.db_name
        DB_PASSWORD_SSM_KEY = aws_ssm_parameter.ssm_db_password.name
    }
  }
  
  # vpc 설정
  vpc_config {
    subnet_ids = module.vpc.subnet-id_pri
    security_group_ids = [ aws_security_group.was_sg.id ]
  }


  tags = {
    Project = "terraform"
  }
}

resource "aws_lambda_function_url" "api-lambda-url" {
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url.html
  function_name = aws_lambda_function.backend_lambda.function_name
  authorization_type = "NONE" # NO authorization 일 때  --> 일단 테스트니까 이렇게
  #authorization_type = "AWS_IAM" # IAM 으로 인증 ? 
  #invoke_mode = "RESPONSE_STREAM" # 조금씩 쪼개서 스트리밍(Streaming) 형식으로 클라이언트에게 전달하는 기능. ex)gpt 타이핑 효과 
                  # 일반적인 환경이라면 생략 or BUFFERED 쓰는게 훨씬 나음.
  invoke_mode = "BUFFERED"
  depends_on = [ aws_alb.public_alb ]

  cors {  # 이것도 뭔지 잘 ㅋ 일단 공식 문서에 있는거 따라 씀
    allow_credentials = true
    allow_origins = ["http://${aws_alb.public_alb.dns_name}"] # 변수 ? 사용해서 DNS이름을 자동으로 참조하도록함. -> 의존성 에러 방지. 그리고 사실 이렇게 적으면 알아서 먼저 만든다고 함. 
    allow_methods = ["GET", "POST"]
    allow_headers = ["date", "keep-alive"]   # allow 헤더랑 expose 헤더 차이가 뭐지 ? --> allow : 들어오는 녀석 감시
    expose_headers = ["keep-alive", "date"] # 나가는 녀석 감시 
    max_age = 86400
  }  
}

# authorization_type이 NONE일 때 누구나 호출할 수 있도록 권한 부여 --> 테스트용이니까. 하고 나서 권한 조이기
# 
resource "aws_lambda_permission" "allow_public_url" {
  statement_id = "FunctionURLAllowPublicAccess-v2"
  action = "lambda:InvokeFunctionUrl"
  function_name = aws_lambda_function.backend_lambda.function_name
  principal = "*"
  function_url_auth_type = "NONE"

  depends_on = [aws_lambda_function_url.api-lambda-url]
}

# ㅇ이걸 aws 에서 2025년 10월부터 같이ㅣ 쓰도록함. 근데 테라폼이 지금 인식을 못함. 
# 이건 어떤 블로그에서 있길래 Invoke Function도 추가해봄
# https://oneuptime.com/blog/post/2026-02-23-create-lambda-function-urls-in-terraform/view
# For internal services or service-to-service communication, use IAM 해야한다는데.. 일단 IAM은 Pass 해본다. 
# 근데 이거가 오류래.. 특히 85.. An argument named "invoked_via_function_url" is not expected here.
# 이게 지금 테라폼에서 인식 못하는 리소스인가본데... 하 ~~~ 
# resource "aws_lambda_permission" "allow_public_invoke" {
#   statement_id             = "FunctionURLInvoke"
#   action                   = "lambda:InvokeFunction"
#   function_name            = aws_lambda_function.backend_lambda.function_name
#   principal                = "*"
#   invoked_via_function_url = true     #특히 여기
# }

# provider 버전 올려주니까 된다.... 공식문서 잘 보기.. ai 새키 믿기 전에 공식 문서 한번 찾아보기!!! 
resource "aws_lambda_permission" "public_access" {
  statement_id             = "FunctionURLInvokeAllowPublicAccess"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.backend_lambda.function_name
  principal                = "*"
  invoked_via_function_url = true
}