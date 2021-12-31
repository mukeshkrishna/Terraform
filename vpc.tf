provider "aws" {
    region = var.region
}

variable vpc_cidr_block {}
variable private_subnet_cidr_blocks {}
variable public_subnet_cidr_blocks {}
variable region {}
data "aws_availability_zones" "available" {}


module "myapp-vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "2.64.0"

    name = "myapp-vpc"
    cidr = var.vpc_cidr_block
    private_subnets = var.private_subnet_cidr_blocks
    public_subnets = var.public_subnet_cidr_blocks
    # aws_availability_zones.available.names are exposed in outputs.tf file in vpc module
    azs = data.aws_availability_zones.available.names 
    
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_dns_hostnames = true
    /*
    tags are used to refernece the resource manually and programatically
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared" -- to make eks know about the subnets
    for public subnets "kubernetes.io/role/elb" = 1  -- this tells EKS that this is public subnet where it need to create the ELB instances
    for private subnets "kubernetes.io/role/internal-elb" = 1 - this tells EKS that this is private subnet and this is k8s interal service need to be created
    
    myapp-eks-cluster -- EKS cluster name, we can even parameterize it but keeping it hardcoded
    */ 
    tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    }

    public_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/elb" = 1 
    }

    private_subnet_tags = {
        "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
        "kubernetes.io/role/internal-elb" = 1 
    }

}
