# Terraform Block - Specifies the provider and version requirements for Terraform
terraform {
  required_version = ">= 1.10" # Specifies the required Terraform version (1.10 or higher)
  # Required Providers Section - Defines the providers to be used for the configuration
  required_providers {

    # AWS provider configuration - This tells Terraform to use the AWS provider and specifies the version.
    aws = {
      source  = "hashicorp/aws" # Specifies the source of the AWS provider from HashiCorp
      version = "~> 5.0"        # Specifies the provider version as 5.x (compatible with your configuration)
    }

    # TLS provider configuration - This tells Terraform to use the TLS provider to generate a key pair.
    tls = {
      source  = "hashicorp/tls" # Specifies the source for the TLS provider (used for generating keys)
      version = "~> 4.0"        # Add a version constraint for tls provider
    }

    # Null provider configuration - This tells Terraform to use the null provider if needed.
    null = {
      source  = "hashicorp/null" # Add null provider if used
      version = "~> 3.0"         # Add a version constraint for null provider
    }

    # Local provider configuration - This tells Terraform to use the local provider if needed.
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
}

# Check if AWS credentials file exists in the specified folder
locals {
  aws_credentials_file = "${path.module}/.aws/credentials"      # Path to the AWS credentials file in the specified folder
  credentials_exists   = fileexists(local.aws_credentials_file) # Checks if the file exists
}

# Global Variables Section - Defines variables that will be used throughout the configuration
variable "region" {
  description = "AWS region" # The AWS region where resources will be deployed (e.g., us-east-1)
  type        = string       # String type for the region variable
  default     = "us-east-1"  # Default value for the region variable (you can override this in the Terraform plan)
}

variable "instance_type" {
  description = "EC2 instance type" # The EC2 instance type to deploy (e.g., t2.micro)
  type        = string              # String type for the instance type
  default     = "t3.micro"          # Default instance type for the EC2 instance
}

variable "ami_id" {
  description = "AMI ID for EC2 instance" # The AMI ID used to launch the EC2 instance
  type        = string                    # String type for the AMI ID
  default     = "ami-0c55b159cbfafe1f0"   # Default Ubuntu AMI (you may want to update this to the latest AMI)
}

# If AWS credentials file does not exist, prompt for AWS access and secret keys
variable "aws_access_key" {
  description = "AWS Access Key ID" # Description for the AWS Access Key variable
  type        = string              # Defines the type as a string for the AWS Access Key
  sensitive   = true                # Marks the variable as sensitive, so it will not be displayed in output
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key" # Description for the AWS Secret Access Key variable
  type        = string                  # Defines the type as a string for the AWS Secret Access Key
  sensitive   = true                    # Marks the variable as sensitive, so it will not be displayed in output
}

# Provider Configuration - Specifies the AWS provider and the region where resources will be deployed
provider "aws" {
  region     = var.region         # The AWS region for all resources defined in this configuration (taken from the variable `region`)
  access_key = var.aws_access_key # AWS Access Key ID, provided via Terraform variable
  secret_key = var.aws_secret_key # AWS Secret Access Key, provided via Terraform variable
}

# Resource: VPC - Creates a new VPC for the EC2 instance with CIDR block 10.0.0.0/16
resource "aws_vpc" "wireguard_vpc" {
  cidr_block           = "10.0.0.0/16" # CIDR block for the VPC, allows up to 65,536 IP addresses
  enable_dns_support   = true          # Enable DNS support for instances in the VPC
  enable_dns_hostnames = true          # Allow instances in the VPC to resolve public DNS names

  tags = {
    Name = "WireGuard-VPC" # Tag the VPC with the name "WireGuard-VPC"
  }
}

# Resource: Subnet - Creates a subnet within the VPC for EC2 instances
resource "aws_subnet" "wireguard_subnet" {
  vpc_id            = aws_vpc.wireguard_vpc.id # Subnet is created in the above VPC
  cidr_block        = "10.0.0.0/24"            # CIDR block for the subnet, allowing up to 256 IP addresses
  availability_zone = "us-east-1a"             # Subnet will be created in availability zone "us-east-1a"

  tags = {
    Name = "WireGuard-Subnet" # Tag the subnet with the name "WireGuard-Subnet"
  }
}

# Resource: Internet Gateway - Creates an Internet Gateway for the VPC to allow public internet access
resource "aws_internet_gateway" "wireguard_igw" {
  vpc_id = aws_vpc.wireguard_vpc.id # Attach the internet gateway to the VPC

  tags = {
    Name = "WireGuard-IGW" # Tag the Internet Gateway with the name "WireGuard-IGW"
  }
}

# Resource: Route Table - Creates a route table for the subnet with a route to the internet
resource "aws_route_table" "wireguard_route_table" {
  vpc_id = aws_vpc.wireguard_vpc.id # Attach the route table to the VPC

  # Default route to the internet via the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"                           # Route all traffic (0.0.0.0/0) to the internet
    gateway_id = aws_internet_gateway.wireguard_igw.id # Use the created Internet Gateway for routing
  }

  tags = {
    Name = "WireGuard-RouteTable" # Tag the route table with the name "WireGuard-RouteTable"
  }
}

# Resource: Route Table Association - Associates the route table with the subnet
resource "aws_route_table_association" "wireguard_subnet_route_association" {
  subnet_id      = aws_subnet.wireguard_subnet.id           # Associate the subnet with the route table
  route_table_id = aws_route_table.wireguard_route_table.id # The route table to associate with the subnet
}

# Resource: AWS Key Pair - Creates a key pair in AWS using the public key from the locally generated ED25519 private key
resource "aws_key_pair" "wireguard_key" {
  key_name   = "wireguard-ed25519-key-pair"                     # Name for the SSH key pair that will be created in AWS
  public_key = tls_private_key.wireguard_key.public_key_openssh # Use the public key from the generated key pair
}

# Resource: AWS Security Group - Creates a security group to allow specific inbound traffic (SSH and WireGuard)
resource "aws_security_group" "wireguard_sg" {
  vpc_id      = aws_vpc.wireguard_vpc.id                  # Security group is created within the defined VPC
  name        = "wireguard-security-group"                # Name of the security group to be created in AWS
  description = "Allow inbound SSH and WireGuard traffic" # Description of what the security group does

  # Ingress rule for SSH access (port 22) from any IP address (0.0.0.0/0)
  ingress {
    from_port   = 22            # Port 22 for SSH access
    to_port     = 22            # Allow inbound traffic on port 22 (SSH)
    protocol    = "tcp"         # Use TCP protocol for SSH
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH access from any IP address (0.0.0.0/0)
  }

  # Ingress rule for WireGuard traffic (UDP port 51820)
  ingress {
    from_port   = 51820         # Port 51820 for WireGuard VPN traffic
    to_port     = 51820         # Allow inbound traffic on port 51820 (WireGuard)
    protocol    = "udp"         # Use UDP protocol for WireGuard
    cidr_blocks = ["0.0.0.0/0"] # Allow WireGuard traffic from any IP address (0.0.0.0/0)
  }

  # Egress rule to allow all outbound traffic (for general communication)
  egress {
    from_port   = 0             # Allow all outbound traffic
    to_port     = 0             # Allow all outbound traffic
    protocol    = "-1"          # Allow all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to any destination
  }

  tags = {
    Name = "WireGuard-SG" # Tag the security group with the name "WireGuard-SG"
  }
}

# Resource: EC2 Instance - Creates the EC2 instance for the WireGuard VPN setup
resource "aws_instance" "wireguard_instance" {
  ami             = var.ami_id                             # Use the specified AMI ID for the instance (e.g., Ubuntu AMI)
  instance_type   = var.instance_type                      # Use the specified instance type (e.g., t2.micro)
  key_name        = aws_key_pair.wireguard_key.key_name    # Use the generated key pair for SSH access
  subnet_id       = aws_subnet.wireguard_subnet.id         # Place the instance in the created subnet
  security_groups = [aws_security_group.wireguard_sg.name] # Attach the security group to the EC2 instance

  # User data to automatically install and configure WireGuard VPN
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install curl -y
              curl https://raw.githubusercontent.com/complexorganizations/wireguard-manager/main/wireguard-manager.sh --create-dirs -o /usr/local/bin/wireguard-manager.sh
              chmod +x /usr/local/bin/wireguard-manager.sh
              bash /usr/local/bin/wireguard-manager.sh --install
              EOF

  associate_public_ip_address = true # Automatically assigns a public IP to the EC2 instance

  tags = {
    Name = "WireGuard-EC2" # Tag the EC2 instance with the name "WireGuard-EC2"
  }
}

# Resource: AWS Elastic IP - Allocates a static Elastic IP (public IP) for the EC2 instance
resource "aws_eip" "wireguard_eip" {
  instance = aws_instance.wireguard_instance.id # Associates the Elastic IP with the EC2 instance
}

# Resource: TLS Private Key - Generates an ED25519 private key
resource "tls_private_key" "wireguard_key" {
  algorithm = "ED25519" # Generate an ED25519 key pair
  # Optionally, you can specify a passphrase for the private key
  # passphrase = "some-secure-passphrase"
}

# Outputs Section - Defines the outputs that Terraform will display after `terraform apply`
output "ec2_public_ip" {
  description = "The public IP address of the WireGuard EC2 instance"
  value       = aws_instance.wireguard_instance.public_ip # Output the public IP of the EC2 instance
}

output "ec2_private_ip" {
  description = "The private IP address of the WireGuard EC2 instance"
  value       = aws_instance.wireguard_instance.private_ip # Output the private IP of the EC2 instance
}

output "ec2_instance_id" {
  description = "The ID of the WireGuard EC2 instance"
  value       = aws_instance.wireguard_instance.id # Output the EC2 instance ID
}

output "elastic_ip" {
  description = "The Elastic IP address associated with the WireGuard EC2 instance"
  value       = aws_eip.wireguard_eip.public_ip # Output the Elastic IP
}

# Resource to display the message about the credentials
output "credentials_check" {
  description = "Check if the AWS credentials file exists"
  value       = local.credentials_exists ? "Credentials file found" : "Credentials file not found. Please set AWS credentials."
}

# Save the private key to a file locally using the 'file' resource
resource "local_file" "wireguard_private_key" {
  content  = tls_private_key.wireguard_key.private_key_pem
  filename = "~/.ssh/wireguard_private_key.pem"
}

# Output the key pair name for reference
output "key_pair_name" {
  value = aws_key_pair.wireguard_key.key_name
}

# Output the private key path
output "private_key_path" {
  value = "~/.ssh/wireguard_private_key.pem"
}
