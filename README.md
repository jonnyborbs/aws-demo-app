# AWS based TFE Demo App
![readmes rule](https://miro.medium.com/max/400/0*u-blKjOt-B15Uy80.jpg)

This demo template will:
- Create a VPC
- Create a subnet
- Create an internet gateway
- Create a security group
- Configure VPC and subnet routing to allow port 80/22 inbound
- Create a Lambda function and SNS subscription/topic for Slack notifications
- Provision a simple Ubuntu EC2 instance (using AMI filtering) which leverages a preexisting keypair, remote-exec provisioners and the awscli to send SNS notifications which are ultimately routed to Slack
- Install and configure a compiled Angular/Clarity based demo application
- Provision a load balancer in front of the EC2 instance and return the URL
- Notify Slack with the instance IP and hostname
- And add some emojuseses 😀💜
- Now trying from VSC
