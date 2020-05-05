output "bastion" {
  value = aws_instance.bastion
}

output "bootstrap" {
  value = aws_instance.bootstrap
}

output "masters" {
  value = [for i in aws_instance.masters : i]
}

output "workers" {
  value = [for i in aws_instance.workers : i]
}
