terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  # vai pegar do profile local do aws cli
  profile = "default" #  cat ~/.aws/credentials
}


resource "aws_vpc" "my_first_vpc" {
  cidr_block = "10.0.0.0/16" # 65.536 IPs disponíveis
}

resource "aws_subnet" "my_first_subnet" {
  vpc_id            = aws_vpc.my_first_vpc.id
  cidr_block        = "10.0.1.0/24" # 256 IPs disponíveis
  availability_zone = "us-east-1a"
}

resource "aws_internet_gateway" "my_first_gateway" {
  # Dependência é explicita com a VPC (gateways existem dentro de redes)
  vpc_id = aws_vpc.my_first_vpc.id
}

resource "aws_eip" "my_first_eip" {
  # fiz direto com a instância, mas da pra fazer parecido com o anterior
  instance = aws_instance.my_first_ec2.id
  # ATENÇÃO! Dependência não é explicita (EIPs podem existir sem gateways)
  depends_on = [aws_internet_gateway.my_first_gateway]
}

resource "aws_instance" "my_first_ec2" {
  ami           = "ami-01816d07b1128cd2d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.my_first_subnet.id
}

# exemplo salvando o IP na SM ParameterStore
## Systems Manager -> ParameterStore
resource "aws_ssm_parameter" "my_first_paramstore" {
  name  = "ip"
  type  = "String"
  value = aws_eip.my_first_eip.public_ip
}

output "ip" {
  value = aws_eip.my_first_eip.public_ip
}
