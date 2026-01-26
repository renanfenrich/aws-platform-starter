mock_provider "aws" {}

run "dns_disabled" {
  command = plan

  variables {
    name_prefix = "test"
    tags = {
      Project     = "test"
      Environment = "test"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
    enable_dns = false
  }

  assert {
    condition     = length(aws_route53_record.primary_a) == 0
    error_message = "expected no primary A record when enable_dns is false"
  }

  assert {
    condition     = length(aws_route53_record.primary_aaaa) == 0
    error_message = "expected no primary AAAA record when enable_dns is false"
  }

  assert {
    condition     = length(aws_route53_record.www_a) == 0
    error_message = "expected no www A record when enable_dns is false"
  }

  assert {
    condition     = length(aws_route53_record.www_aaaa) == 0
    error_message = "expected no www AAAA record when enable_dns is false"
  }
}

run "dns_enabled_apex_with_www" {
  command = plan

  variables {
    name_prefix      = "test"
    enable_dns       = true
    hosted_zone_id   = "Z1234567890"
    domain_name      = "example.com"
    record_name      = ""
    create_www_alias = true
    create_aaaa      = true
    alb_dns_name     = "dualstack.test-alb-123456.us-east-1.elb.amazonaws.com"
    alb_zone_id      = "Z35SXDOTRQ7X7K"
    tags = {
      Project     = "test"
      Environment = "test"
      Service     = "test"
      Owner       = "test"
      CostCenter  = "test"
      ManagedBy   = "Terraform"
      Repository  = "aws-platform-starter"
    }
  }

  assert {
    condition     = length(aws_route53_record.primary_a) == 1
    error_message = "expected primary A record when enable_dns is true"
  }

  assert {
    condition     = aws_route53_record.primary_a[0].name == "example.com"
    error_message = "expected apex record name to match domain"
  }

  assert {
    condition     = aws_route53_record.primary_a[0].alias[0].name == "dualstack.test-alb-123456.us-east-1.elb.amazonaws.com"
    error_message = "expected alias target to match ALB DNS name"
  }

  assert {
    condition     = aws_route53_record.primary_a[0].alias[0].zone_id == "Z35SXDOTRQ7X7K"
    error_message = "expected alias target zone ID to match ALB zone ID"
  }

  assert {
    condition     = length(aws_route53_record.primary_aaaa) == 1
    error_message = "expected primary AAAA record when create_aaaa is true"
  }

  assert {
    condition     = aws_route53_record.primary_aaaa[0].name == "example.com"
    error_message = "expected apex AAAA record name to match domain"
  }

  assert {
    condition     = length(aws_route53_record.www_a) == 1
    error_message = "expected www A record when create_www_alias is true"
  }

  assert {
    condition     = aws_route53_record.www_a[0].name == "www.example.com"
    error_message = "expected www record name to match domain"
  }

  assert {
    condition     = length(aws_route53_record.www_aaaa) == 1
    error_message = "expected www AAAA record when create_aaaa is true"
  }

  assert {
    condition     = output.dns_fqdn == "example.com"
    error_message = "expected dns_fqdn output to resolve to the apex"
  }
}
