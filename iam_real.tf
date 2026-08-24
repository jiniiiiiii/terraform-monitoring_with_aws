# ==========================================
# [0] 공통 신뢰 정책 (Assume Role Policy)
# ==========================================
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
  
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
  
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ==========================================
# [1] EC2 IAM role & policy
# role -> policy생성(있으면) -> attech_policy
# ==========================================
# (1) s3 read ok 역할 생성
resource "aws_iam_role" "ec2_read_s3_role" {
  name          = "ec2-s3-read-role"

  # 신뢰 정책 연결
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  # 권한 경계 설정 (*role에만 부착 가능*)
  permissions_boundary = var.boundary_role
}

#(2) role에 policy 연결 - 관리형.ver
resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role          = aws_iam_role.ec2_read_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

#(3) 인스턴스 프로파일 생성 -> ec2의 경우 만들어줘야함. 
resource "aws_iam_instance_profile" "ec2-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_read_s3_role.name
}


# ==========================================
# [3] Lambda IAM role & policy - ssm, s3
# role -> policy생성(있으면) -> attech_policy
# ==========================================
# (1) role 생성
resource "aws_iam_role" "lambda_rds_work_role" {
  name               = "lambda_rds_work_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  permissions_boundary = var.boundary_role
}


# -------------------------------------------
# s3 관련
# -------------------------------------------
#(2) policy 생성 혹은 attech
# s3 읽기
resource "aws_iam_role_policy_attachment" "lambda_s3_readonly" {
  role   = aws_iam_role.lambda_rds_work_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# CloudWatch Logs 기록을 위한 Lambda 기본 실행 권한
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role    = aws_iam_role.lambda_rds_work_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -------------------------------------------
# ssm 관련
# -------------------------------------------
# (2) 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_rds_vpc_okay" {
  role         = aws_iam_role.lambda_rds_work_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# (3) 정책 생성 -> 정책 정의
resource "aws_iam_policy" "lambda_ssm_read_policy" {
  name    = "lambda_ssm_read-policy"
  description = "Allow lambda to read database password from ssm"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaReadDBPasswordFromSSM"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParameterHistory"
        ]
        Resource = "arn:aws:ssm:ap-northeast-3:545738259208:parameter/qbank/*"
      }
    ]
  })
}

#(4) 생성한 정책 부착
resource "aws_iam_role_policy_attachment" "lambda_ssm_attach" {
  role = aws_iam_role.lambda_rds_work_role.name
  policy_arn = aws_iam_policy.lambda_ssm_read_policy.arn
}