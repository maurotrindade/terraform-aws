terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}

# só vai pegar os metadados
data "aws_secretsmanager_secret" "my_first_secret" {
  arn = "arn:aws:secretsmanager:us-east-1:364155191442:secret:my/first/secret-In9ajk"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.my_first_secret.id
}

provider "aws" {
  region = "us-east-1"
  # vai pegar do profile local do aws cli
  profile = "default" #  cat ~/.aws/credentials
}


resource "aws_vpc" "my_first_vpc" {
  cidr_block = "10.0.0.0/16" # 65.536 IPs disponíveis

  tags = {
    "Name" = "my-first-vpc"
  }
}

resource "aws_subnet" "my_first_subnet" {
  vpc_id            = aws_vpc.my_first_vpc.id
  cidr_block        = "10.0.1.0/24" # 256 IPs disponíveis
  availability_zone = "us-east-1a"

  tags = {
    "Name" = "my-first-subnet"
  }
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
  ami             = "ami-01816d07b1128cd2d"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.my_first_subnet.id
  security_groups = [aws_security_group.my_first_sg.id]
}

# exemplo salvando o IP na SM ParameterStore
## Systems Manager -> ParameterStore
resource "aws_ssm_parameter" "my_first_paramstore" {
  name  = "ip"
  type  = "String"
  value = aws_eip.my_first_eip.public_ip
}

resource "aws_route_table" "my_first_table" {
  vpc_id = aws_vpc.my_first_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_first_gateway.id
  }
}

resource "aws_route_table_association" "table_line" {
  subnet_id      = aws_subnet.my_first_subnet.id
  route_table_id = aws_route_table.my_first_table.id
}

resource "aws_security_group" "my_first_sg" {
  vpc_id = aws_vpc.my_first_vpc.id
  name   = "Allow SSH"
}

resource "aws_vpc_security_group_ingress_rule" "my_first_sg_ingress_rule" {
  security_group_id = aws_security_group.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "my_first_sg_egress_rule" {
  security_group_id = aws_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # -1 = todos os protocolos
}

output "ip" {
  value = aws_eip.my_first_eip.public_ip
}

# output "output_nada_seguro" {
#   value = jsondecode(data.aws_secretsmanager_secret_version.current)["KEY"]
# }
