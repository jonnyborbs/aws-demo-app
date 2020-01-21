#init the backend
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "jschulman"

    workspaces {
      name = "tfe-demo-app"

    }
  }
}

# Specify the provider and access details
provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "terraform_demo_app_elb"
  description = "Created by Terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_demo_app_asg"
  description = "Created by Terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "terraform-demo-app"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
}

resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    type = "ssh"
    user = "ubuntu"
    host = self.public_ip
    private_key = var.private_key
  }

  instance_type = "t2.micro"
  iam_instance_profile = "EC2AccessSNS"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${data.aws_ami.ubuntu.id}"

  # The name of our SSH keypair we created above.
  key_name = "${var.key_pair_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.default.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt install nginx curl git -y",
      "/usr/bin/git clone https://github.com/vaficionado/tf-demo-application /tmp/tf-demo-application",
      "/bin/rm -rf /etc/nginx/conf.d/",
      "/bin/rm -rf /usr/share/nginx/html/",
      "/usr/bin/curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -",
      "sudo /usr/bin/apt install nodejs -y",
      "/usr/bin/npx @angular/cli analytics off",
      "sudo /usr/bin/npm install -g @angular/cli",
      "cd /tmp/tf-demo-application &&  /usr/bin/npm install",
      "/usr/bin/ng build --prod",
      "sudo /bin/cp -R /tmp/tf-demo-application/dist/cmbu-demo-application/* /usr/share/nginx/html/",
      "sudo /bin/sed -i \"s@root /var/www/html@root /usr/share/nginx/html@\" /etc/nginx/sites-available/default",
      "sudo /bin/systemctl restart nginx",
      "sudo ufw allow http",
      "sudo apt install python3-pip -y",
      "/usr/bin/pip3 install awscli --upgrade --user",
      "~/.local/bin/aws sns publish --target-arn ${module.notify-slack.this_slack_topic_arn} --region ${var.aws_region} --message \"server provisioned at ip ${aws_instance.web.public_ip}\"",
    ]
  }
  tags = {
    AppName = "TFDemoApp"
    AppOwner = "Jon"
    CostCenter = "TFE-PM-0001"
    Name = "Clarity TF Demo App"
  }
}

module "notify-slack" {
  source  = "app.terraform.io/jschulman/notify-slack/aws"
  version = "2.0.0"
  sns_topic_name = "${var.slack_topic_name}"
  slack_webhook_url = "${var.slack_webhook_url}"
  slack_channel     = "jms-notifications"
  slack_username    = "jms-tfe-slack"
}
