provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "replica"
  region = length(trimspace(var.replication_region)) > 0 ? var.replication_region : var.aws_region

  default_tags {
    tags = var.tags
  }
}
