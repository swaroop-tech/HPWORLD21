provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA4JZPK2WVYQWGGQFI"
  secret_key = "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"
}

#my vpc

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

#my public subnet

resource "aws_subnet" "publicsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "pub.air"
  }
}

#my private subnet

resource "aws_subnet" "privatesub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "pri.vate"
  }
}

#my security group

resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysg"
  }
}

#my internet get way

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

#my elastic ip

resource "aws_eip" "myeip" {
  vpc      = true
}

#nat get way

resource "aws_nat_gateway" "mynatgetway" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.publicsub.id

  tags = {
    Name = "gw NAT"
  }
}

#public route table

resource "aws_route_table" "mypubroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "mypubroute"
  }
}

#private route table

resource "aws_route_table" "privateroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynatgetway.id
  }

  tags = {
    Name = "example"
  }
}

#public route table association

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.publicsub.id
  route_table_id = aws_route_table.mypubroute.id
}

#private route table association

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.privatesub.id
  route_table_id = aws_route_table.privateroute.id
}

#key pair

resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHLjDQzFTdJUMfYPA2cEaR3RTZa7g83w36qZhMjx505Zg8Lh30kV3zSKgwb7Pin/QW0gpWGABc/MTq8tEFVtxxyfeYjsUkBYafePxzuPw0gmOzKC4eRRCFZ5NqDWW2MXh9wPME8LiiK5NAHLtOyklIzbSn8TBzl9LYdiJYPS0bJmUfdSn8bEe23FJekCr4FVZycyOmr4WuZw2M/n/P61c5pyEYxTCNXXlPxpxtTFd9gYx+m4lqwQxqn9ITzlB3dZljReYBOSM69iDYkmz21PS4PTc5i3ZD1wRrakIgmkhw+/XjZCrj1867LjYHBPlMXMw1/KufiWPDUoOwWVAagzqPnI+MQzL8fOWBk6mSKrCnufVo+tPmorlmHK7Yu9llN+8rR7bGzNCdkIFmjbiwHBq/lCAHHxjY3jcwkaliwydIF2jvtryUxzYEON+xgUHD+E4WtJXVR+noAXAUw5/TTF/1MDs6gy2CS82ZyuMwY2IDMwoOx5tZ4YfynLdnf/Id0ec= ec2-user@ip-172-31-17-154.ec2.internal"
}

#instance

resource "aws_instance" "web" {
  ami           = "ami-016eb5d644c333ccb"
  instance_type = "t2.micro"
  key_name  = "mykey"
  subnet_id = aws_subnet.publicsub.id
  vpc_security_group_ids = [aws_security_group.mysg.id]
  tags = {
    Name = "HelloWorld"
  }
}

#attach eip

resource "aws_eip" "lb" {
  instance = aws_instance.web.id
  vpc      = true
}

#data base server

resource "aws_instance" "dev" {
  ami           = "ami-016eb5d644c333ccb"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.privatesub.id
  vpc_security_group_ids = [aws_security_group.mysg.id]

  tags = {
    Name = "HelloWorld"
  }
}
