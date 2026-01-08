mock_provider "aws" {}

run "network_plan" {
  command = plan

  variables {
    compute_mode = "none"
  }

  assert {
    condition     = length(module.network.public_subnet_ids) == 2
    error_message = "expected two public subnets"
  }

  assert {
    condition     = length(module.network.private_subnet_ids) == 2
    error_message = "expected two private subnets"
  }
}
