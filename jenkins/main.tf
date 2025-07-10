provider "aws" {
  region = "us-east-1"
}

# VPC 생성
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.1.0.0/16"
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id
}

# 퍼블릭 라우팅 테이블
resource "aws_route_table" "jenkins_public" {
  vpc_id = aws_vpc.jenkins_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }
}

# 서브넷 생성 (AZ 명시)
resource "aws_subnet" "jenkins_public" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

# 라우팅 테이블과 서브넷 연결
resource "aws_route_table_association" "jenkins_public_subnet" {
  subnet_id      = aws_subnet.jenkins_public.id
  route_table_id = aws_route_table.jenkins_public.id
}

# 보안 그룹 (SSH 허용)
resource "aws_security_group" "jenkins_ssh" {
  name        = "jenkins-ssh"
  description = "Allow SSH access to Jenkins EC2 instance"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-020cba7c55df1f615"
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.jenkins_public.id
  vpc_security_group_ids      = [aws_security_group.jenkins_ssh.id]
  associate_public_ip_address = true
  key_name                    = "dz07key"

  user_data = <<-EOF
#!/bin/bash
set -e

# Wait for apt locks
sleep 10
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do sleep 1; done
while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do sleep 1; done
while sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do sleep 1; done

# Update and install Java 17
sudo apt-get update -y
sudo apt-get install -y openjdk-17-jdk curl gnupg2 software-properties-common

# Set JAVA_HOME
echo 'JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' | sudo tee -a /etc/environment
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

sleep 10

wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install jenkins -y

# Install Docker
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

# Jenkins 계정 존재 확인 후 docker 권한 부여
until id jenkins >/dev/null 2>&1; do
  echo "Waiting for jenkins user to be created..."
  sleep 1
done
sudo usermod -aG docker jenkins

# 7. Jenkins 서비스 시작 및 부팅 시 자동 실행
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# 8. 포트 열림 확인용 로그
sudo ss -tuln | grep 8080

echo "✅ Jenkins & Docker 설치 완료"


EOF

  tags = {
    Name = "jenkins-server-nyj"
  }
} 