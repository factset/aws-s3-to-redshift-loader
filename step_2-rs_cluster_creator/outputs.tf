output "rs_cluster_dns_name" {
  description = "DNS name of the Redshift cluster"
  value       = aws_redshift_cluster.rs_cluster.dns_name
}

output "security_group_ids"{
  description = "IDs of the Redshift security group"
  value       = [aws_default_security_group.rs_security_group.id]
}
