output "s3_source_id" {
  description = "Airbyte S3 source connector ID"
  value       = airbyte_source_s3.s3.source_id
}

output "postgres_source_id" {
  description = "Airbyte Postgres source connector ID"
  value       = airbyte_source_postgres.postgres.source_id
}

output "s3_destination_id" {
  description = "Airbyte S3 destination connector ID"
  value       = airbyte_destination_s3.s3.destination_id
}

output "s3_connection_id" {
  description = "Airbyte S3 to data lake connection ID"
  value       = airbyte_connection.s3_to_lake.connection_id
}

output "postgres_connection_id" {
  description = "Airbyte Postgres to data lake connection ID"
  value       = airbyte_connection.postgres_to_lake.connection_id
}