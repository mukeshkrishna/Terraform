resource "aws_subnet" "myapp-subnet-1"{
  vpc_id = var.vpc_id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-IGW"{
  vpc_id = var.vpc_id
  tags = {
    Name: "${var.env_prefix}-IGW"
  }
}


/*
Route table association with subnet not required as we are using
default route table. All subnet in the vpc will be associated with the main route table(default)
And Route from target=local and destiantion=vpc_cidr_block will be added by default in all route table ie traffic arising whtihn vpc
so we are adding only the record for traffic arising outside vpc
*/
resource "aws_default_route_table" "main-rt"{
  default_route_table_id = var.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-IGW.id
  }
  tags = {
    Name: "${var.env_prefix}-rt"
  }
}

/*

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
*/