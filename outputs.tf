output "elb_dns" {
	value = ["${aws_elb.sunil_elb.dns_name}"]
}
