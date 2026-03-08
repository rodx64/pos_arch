output "instance_id" { 
    value = aws_instance.bastion.id 
}

output "bastion_sg_id" {
  value = aws_security_group.app_sg.id
}
