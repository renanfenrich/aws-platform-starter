mock_provider "aws" {}

run "bootstrap_plan" {
  command = plan

  variables {
    aws_region        = "us-east-1"
    project_name      = "aws-platform-starter"
    environment       = "dev"
    region_short      = "use1"
    state_bucket_name = "aws-platform-starter-state-dev"
  }

  override_data {
    target = data.aws_iam_policy_document.state_kms
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  assert {
    condition = anytrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.state.rule :
      rule.apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    ])
    error_message = "expected state bucket encryption to use aws:kms"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls && aws_s3_bucket_public_access_block.state.block_public_policy && aws_s3_bucket_public_access_block.state.ignore_public_acls && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    error_message = "expected state bucket public access block to be fully enabled"
  }

  assert {
    condition     = aws_sns_topic.infra_notifications.kms_master_key_id == aws_kms_alias.state.name
    error_message = "expected SNS topic to use KMS encryption"
  }
}
