packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = ">= 1.2.8"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.2"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# Resolve latest Amazon Linux 2023 AMI via SSM
data "amazon-ami" "al202" {
  name = "al2023-ami-2023.*-kernel-*-x86_64"
  virtualization-type = "hvm"
  architecture = "x86_64"
  root-device-type = "ebs"	
}

owners = ["amazon"]
most_recent = true
region = ap-south-1

source "amazon-ebs" "al2023_ansible" {
  region        = ap-south-1
  ami_name      = "al2023-ansible-${local.timestamp}"
  instance_type = "t2.micro"
  subnet_id = "subnet-0d03288c901f4e073"
  vpc_id = "vpc-039ed8e00ba29561f"
  security_group_id = "sg-00ac682b1eda832b7"
  iam_instance_profile = "Amiashok" 
  communicator = "ssh"
  ssh_username  = "ec2-user"
  source_ami = data.amazon-ami.al202.id
  ssh_interface = "session_manager"
}

build {
  name    = "al2023-ami-with-ansible"
  sources = ["source.amazon-ebs.al2023_ansible"]

  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install python3-pip",
      "sudo pip3 install ansible"
    ]

  provisioner "ansible" {
    playbook_file   = ""
    playbook_dir    = ""
    user            = "ec2-user"
    extra_arguments = ["--extra-vars", "ansible_python_interpreter=/usr/bin/python3", "-t level1-server", "-vvvvv"]
    use_proxy       = false
  }
}

