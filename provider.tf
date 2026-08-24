terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.56"
      }
    }
    required_version = ">=1.2"

    # backend "s3" 는 terraform 블록 안에 들어가야 함 !! 
    backend "s3" {
      bucket      = "terraform-s3-buuuuucket-tfstate-real"   # 이미 생성해 놔야함 !1
      key         = "./terraform.tfstate"
      region      = "ap-northeast-3"
      #region      = var.aws_region    변수명 사용시 오류 남. 꼭 풀네임 적어주기 --> 저장소 연결이 1순위 --> 변수 등 terraform 파일 생성
      encrypt     = true    # 암호화 저장 옵션
      
      #state lock 을 위한 DDB 지정. but 1.15 버전 이상부터는 더 이상 사용ㅇ 권고 x  
      # s3상태 잠금으로 대체 됨. 
      #dynamodb = "terraform-state-lock"
      use_lockfile = true #기본값 false
    }
}

variable "project" {
    type    = string
    default = "terraform"
}

provider "aws" {
    region = "ap-northeast-3"

/* 태그 권한 필요 ==>  iam:TagRole 및 iam:TagPolicy
    default_tags {
    tags = {
      Project = var.project
    }
  }
*/
}

