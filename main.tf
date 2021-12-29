provider "aws"{
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_access_key
} 

variable "aws_region" {
  type        = string
  default     = ""
  description = "aws region"
}

variable "aws_access_key" {
  type        = string
  default     = ""
  description = "Aws Access Key"
}

variable "aws_secret_access_key" {
  type        = string
  default     = ""
  description = "secret access key"
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "vpc_cidr_block"
}

variable "env_prefix" {
  type        = string
  default     = "dev"
  description = "env Prefix"
}

variable "subnet_cidr_block" {
  type        = string
  default     = "10.0.10.0/24"
  description = "subnet_cidr_block"
}

variable "avail_zone" {
  type        = string
  default     = ""
  description = "avail_zone"
}

variable "my_public_ip" {
  type        = string
  description = "my_public_ip"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "instance_type"
}

variable "public_key_location" {
  type        = string
  default     = ""
  description = "public_key_location"
}


resource "aws_vpc" "myapp-vpc"{
  cidr_block = var.vpc_cidr_block
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1"{
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-IGW"{
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-IGW"
  }
}

resource "aws_default_route_table" "main-rt"{
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-IGW.id
  }
  tags = {
    Name: "${var.env_prefix}-rt"
  }
}
/*
Route table association with subnet not required as we are using
default route table. All subnet in the vpc will be associated with the main route table(default)
And Route from target=local and destiantion=vpc_cidr_block will be added by default in all route table ie traffic arising whtihn vpc
so we are adding only the record for traffic arising outside vpc
*/

resource "aws_default_security_group" "default-SG"{
  vpc_id = aws_vpc.myapp-vpc.id
  ingress{
    description = "SSH to Instanct"
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = [var.my_public_ip] 
  }
  ingress{
    description = "SHH to Instanct"
    from_port = "8080"
    to_port = "8080"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress{
    description = "Outbound request allowed to all ports and destination on any protocol"
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]   
    prefix_list_ids = [] 
  }
  tags = {
    Name: "${var.env_prefix}-SG"
  }
}
data "aws_ami" "latest-amazon-image"{
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

output "aws_ami_id" {
  value       = data.aws_ami.latest-amazon-image.id
  description = "To get aws ami id"

}

output "aws_ec2_public_ip"{
  value = aws_instance.myapp-instance.public_ip
}

resource "aws_key_pair" "ssh-key"{
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-instance"{
  ami = data.aws_ami.latest-amazon-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-SG.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  
  user_data = file("external-script.sh")

  tags = {
    Name: "${var.env_prefix}-server"
  }

}


/*
resource "aws_security_group" "myapp-SG"{
  name = "myapp-SG"
  vpc_id = aws_vpc.myapp-vpc.id
  ingress{
    description = "SSH to Instanct"
    from_port = "22"
    to_port = "22"
    protocol = "tcp"
    cidr_blocks = [var.my_public_ip] 
  }
  ingress{
    description = "SHH to Instanct"
    from_port = "8080"
    to_port = "8080"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  egress{
    description = "Outbound request allowed to all ports and destination on any protocol"
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]   
    prefix_list_ids = [] 
  }
  tags = {
    Name: "${var.env_prefix}-SG"
  }
}

resource "aws_route_table" "myapp-rt"{
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-IGW.id
  }
  tags = {
    Name: "${var.env_prefix}-rt"
  }
}
resource "aws_instance" "myapp-instance"{
  ami = data.aws_ami.latest-amazon-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-SG.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name
  
  user_data = <<EOF
              #!/bin/bash
              sudo yum update -y && sudo yum install -y docker
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user
              docker run -it -p 8080:80 --name nginx -d nginx               
              EOF

  tags = {
    Name: "${var.env_prefix}-server"
  }

}

*/

