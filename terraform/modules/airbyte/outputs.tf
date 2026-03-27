output "s3_source_id" {
  description = "Airbyte S3 source ID"
  value       = airbyte_source.s3.source_id
}

output "postgres_source_id" {
  description = "Airbyte Postgres source ID"
  value       = airbyte_source.postgres.source_id
}


output "s3_destination_id" {
  description = "Airbyte S3 destination ID"
  value       = airbyte_destination.s3.destination_id
}

output "s3_connection_id" {
  description = "Airbyte connection ID for S3 source — used by Airflow to trigger syncs"
  value       = airbyte_connection.s3_to_lake.connection_id
}

output "postgres_connection_id" {
  description = "Airbyte connection ID for Postgres source — used by Airflow to trigger syncs"
  value       = airbyte_connection.postgres_to_lake.connection_id
}
