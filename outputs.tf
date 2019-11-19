output "address" {
  value = "${aws_elb.web.dns_name}"
}

output "slack-arn" {
  value = "${module.notify-slack.this_slack_topic_arn}"
}

output "new output {
  value = "1234"
}"