output "ec2_public_ip" {
  description = "public id address"
  value       = aws_instance.dylan-ec2.public_ip
}

output "ec2_instance_id" {
  description = "id of instance"
  value       = aws_instance.dylan-ec2.id
}