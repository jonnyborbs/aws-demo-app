output "address" {
  value = "${aws_elb.web.dns_name}"
}

output "slack-arn" {
  value = "${module.notify_slack.this_slack_topic_arn}"
}