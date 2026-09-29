resource "random_uuid" "resource" {}

resource "aws_bedrockagent_data_source" "resource" {
  name                 = coalesce(var.name, random_uuid.resource.id)
  description          = var.description
  knowledge_base_id    = var.knowledge_base_id
  data_deletion_policy = var.data_deletion_policy

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn              = var.bucket_arn
      inclusion_prefixes      = var.inclusion_prefixes
      bucket_owner_account_id = var.bucket_owner_account_id
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = var.chunking_strategy

      dynamic "fixed_size_chunking_configuration" {
        for_each = var.chunking_strategy == "FIXED_SIZE" ? [1] : []

        content {
          max_tokens         = var.max_tokens
          overlap_percentage = var.overlap_percentage
        }
      }
    }
  }
}

output "id" {
  description = "The ID of the data source."
  value       = aws_bedrockagent_data_source.resource.data_source_id
}

output "name" {
  description = "The name of the data source."
  value       = aws_bedrockagent_data_source.resource.name
}

output "knowledge_base_id" {
  description = "The ID of the knowledge base this data source feeds."
  value       = aws_bedrockagent_data_source.resource.knowledge_base_id
}
