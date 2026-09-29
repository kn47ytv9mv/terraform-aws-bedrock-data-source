mock_provider "aws" {}

variables {
  knowledge_base_id = "ABCDEFGHIJ"
  bucket_arn        = "arn:aws:s3:::example-documents"
}

run "more_than_one_inclusion_prefix_is_rejected" {
  command = plan

  variables {
    inclusion_prefixes = ["handbook/", "policies/"]
  }

  expect_failures = [var.inclusion_prefixes]
}

run "an_unknown_chunking_strategy_is_rejected" {
  command = plan

  variables {
    chunking_strategy = "MAGIC"
  }

  expect_failures = [var.chunking_strategy]
}

run "an_unknown_deletion_policy_is_rejected" {
  command = plan

  variables {
    data_deletion_policy = "MAYBE"
  }

  expect_failures = [var.data_deletion_policy]
}

run "defaults_chunk_and_retain" {
  command = apply

  assert {
    condition     = aws_bedrockagent_data_source.resource.name == random_uuid.resource.id
    error_message = "With no name given, the data source should use the generated random_uuid."
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.data_deletion_policy == "RETAIN"
    error_message = "Embeddings should be retained by default - a destroy should not silently discard an index that cost money to build."
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.data_source_configuration[0].type == "S3"
    error_message = "The data source should be configured for S3."
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.vector_ingestion_configuration[0].chunking_configuration[0].chunking_strategy == "FIXED_SIZE"
    error_message = "Chunking should default to FIXED_SIZE."
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.vector_ingestion_configuration[0].chunking_configuration[0].fixed_size_chunking_configuration[0].max_tokens == 300
    error_message = "max_tokens should default to 300."
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.vector_ingestion_configuration[0].chunking_configuration[0].fixed_size_chunking_configuration[0].overlap_percentage == 20
    error_message = "overlap_percentage should default to 20 so answers are not cut in half at a chunk boundary."
  }
}

run "explicit_name_overrides_generated_uuid" {
  command = plan

  variables {
    name = "handbook"
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.name == "handbook"
    error_message = "An explicit name should be used instead of the generated UUID."
  }
}

run "an_inclusion_prefix_is_passed_through" {
  command = plan

  variables {
    inclusion_prefixes = ["handbook/"]
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.data_source_configuration[0].s3_configuration[0].inclusion_prefixes == toset(["handbook/"])
    error_message = "The inclusion prefix should be passed through."
  }
}

run "non_fixed_chunking_omits_the_fixed_size_block" {
  command = plan

  variables {
    chunking_strategy = "NONE"
  }

  assert {
    condition     = length(aws_bedrockagent_data_source.resource.vector_ingestion_configuration[0].chunking_configuration[0].fixed_size_chunking_configuration) == 0
    error_message = "The fixed size block is only valid for FIXED_SIZE and must be omitted otherwise."
  }
}

run "chunk_size_can_be_tuned" {
  command = plan

  variables {
    max_tokens         = 1000
    overlap_percentage = 10
  }

  assert {
    condition     = aws_bedrockagent_data_source.resource.vector_ingestion_configuration[0].chunking_configuration[0].fixed_size_chunking_configuration[0].max_tokens == 1000
    error_message = "An explicit max_tokens should be passed through."
  }
}
