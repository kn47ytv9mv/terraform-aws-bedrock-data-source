variable "name" {
  default     = null
  description = "Name of the data source."
}

variable "description" {
  default     = null
  description = "Description of the data source."
}

variable "knowledge_base_id" {
  default     = null
  description = "ID of the knowledge base this data source feeds. Feed this from terraform-aws-bedrock-knowledge-base's id output."
}

variable "bucket_arn" {
  default     = null
  description = "The ARN of the S3 bucket holding the documents. Feed this from terraform-aws-s3."
}

variable "inclusion_prefixes" {
  default     = null
  description = "Key prefix to ingest, as a single-element list. Bedrock accepts at most one. Left null, the whole bucket is ingested, which is rarely what you want on a bucket holding anything else."

  validation {
    condition     = var.inclusion_prefixes == null || length(var.inclusion_prefixes) <= 1
    error_message = "Bedrock accepts at most one inclusion prefix per data source. To ingest a second prefix, add a second data source against the same knowledge base."
  }
}

variable "bucket_owner_account_id" {
  default     = null
  description = "Account ID owning the bucket, when it is not this one."
}

variable "data_deletion_policy" {
  default     = "RETAIN"
  description = "What happens to the embeddings in the vector store when this data source is deleted. 'RETAIN' leaves them; 'DELETE' removes them. Defaults to RETAIN so a terraform destroy does not silently discard an expensive index."

  validation {
    condition     = contains(["RETAIN", "DELETE"], var.data_deletion_policy)
    error_message = "data_deletion_policy must be 'RETAIN' or 'DELETE'."
  }
}

variable "chunking_strategy" {
  default     = "FIXED_SIZE"
  description = "How documents are split before embedding (e.g. 'FIXED_SIZE', 'HIERARCHICAL', 'SEMANTIC', or 'NONE'). 'NONE' treats each file as one chunk, which only works for already-small documents."

  validation {
    condition     = contains(["FIXED_SIZE", "HIERARCHICAL", "SEMANTIC", "NONE"], var.chunking_strategy)
    error_message = "chunking_strategy must be one of 'FIXED_SIZE', 'HIERARCHICAL', 'SEMANTIC' or 'NONE'."
  }
}

variable "max_tokens" {
  default     = 300
  description = "Tokens per chunk, when chunking_strategy is FIXED_SIZE. Smaller chunks retrieve more precisely and carry less surrounding context; larger chunks do the opposite."
}

variable "overlap_percentage" {
  default     = 20
  description = "How much each chunk repeats of the one before it, as a percentage, when chunking_strategy is FIXED_SIZE. Overlap stops an answer being cut in half at a chunk boundary."
}
