# terraform-aws-bedrock-data-source

Terraform module for a Bedrock knowledge base data source: the S3 bucket a
knowledge base ingests from, and the rules for splitting documents before
they are embedded.

## Cost

The resource carries no charge. Ingestion does. Every sync embeds the
documents that changed, billed per token by the model the knowledge base
is configured with.

Three things drive that. How much is ingested, which is why pointing a
data source at a whole bucket when one prefix was meant can embed a great
deal more than intended. How often it is re-synced, since a sync
re-embeds changed files and frequent syncs over a large corpus are the
usual surprise. And chunk size with overlap, because overlap duplicates
text and duplicated text is embedded twice, so raising the overlap raises
both the ingest bill and the stored footprint.

Smaller chunks retrieve more precisely and carry less surrounding context;
larger chunks do the opposite. The defaults are a reasonable starting
point rather than a universal answer, and should be tuned against
retrieval quality. Current rates are on AWS's
[Bedrock pricing](https://aws.amazon.com/bedrock/pricing/) page.

## Design

Embeddings are retained by default if the data source is deleted, because
rebuilding them costs real money and discarding them should be an explicit
choice.

### One inclusion prefix

Bedrock accepts at most one inclusion prefix per data source. The module
validates this so the failure is a clear message at plan time rather than
a provider error. Ingesting a second prefix means a second data source
against the same knowledge base.

### Creating this does not ingest anything

A data source has to be synced before its documents appear in the index,
and starting a sync is an API call rather than a Terraform resource. Run
it after the apply, or on a schedule.

Chunking changes are likewise not retroactive. Adjusting `max_tokens`
after ingestion leaves the existing vectors built the old way; a full
re-sync is what makes the change real.

### Tagging

The `aws_bedrockagent_data_source` resource accepts no tags, so this
module takes no `tags` variable. A consumer wanting account-wide tagging
should set `default_tags` on the provider.

## Usage

```hcl
module "documents" {
  source = "kn47ytv9mv/bedrock-data-source/aws"

  name              = "handbook"
  knowledge_base_id = module.knowledge_base.id
  bucket_arn        = module.documents_bucket.arn

  inclusion_prefixes = ["handbook/"]
}
```

Or directly from this repository:

```hcl
module "documents" {
  source = "github.com/kn47ytv9mv/terraform-aws-bedrock-data-source"

  name              = "handbook"
  knowledge_base_id = module.knowledge_base.id
  bucket_arn        = module.documents_bucket.arn
}
```

With larger chunks and embeddings deleted on teardown:

```hcl
module "documents" {
  source = "kn47ytv9mv/bedrock-data-source/aws"

  name              = "handbook"
  knowledge_base_id = module.knowledge_base.id
  bucket_arn        = module.documents_bucket.arn

  max_tokens         = 1000
  overlap_percentage = 10

  data_deletion_policy = "DELETE"
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.2 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the data source. | `null` | no |
| description | Description of the data source. | `null` | no |
| knowledge_base_id | ID of the knowledge base this data source feeds. | `null` | no |
| bucket_arn | The ARN of the S3 bucket holding the documents. | `null` | no |
| inclusion_prefixes | Key prefix to ingest, as a single-element list. | `null` | no |
| bucket_owner_account_id | Account ID owning the bucket, when it is not this one. | `null` | no |
| data_deletion_policy | `RETAIN` or `DELETE` the embeddings when the data source goes. | `"RETAIN"` | no |
| chunking_strategy | `FIXED_SIZE`, `HIERARCHICAL`, `SEMANTIC` or `NONE`. | `"FIXED_SIZE"` | no |
| max_tokens | Tokens per chunk, for `FIXED_SIZE`. | `300` | no |
| overlap_percentage | How much each chunk repeats of the previous one, for `FIXED_SIZE`. | `20` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the data source. |
| name | The name of the data source. |
| knowledge_base_id | The ID of the knowledge base this data source feeds. |

## License

MIT — see [LICENSE.md](LICENSE.md).
