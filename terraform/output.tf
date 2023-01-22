#############################################################################
# Outputs
#############################################################################

# Job definition ARN
output "job_definition_arn" {
  value = aws_batch_job_definition.BatchJobDefinition.arn
}

# Job queue ARN
output "job_queue_arn" {
  value = aws_batch_job_queue.BatchJobQueue.arn
}