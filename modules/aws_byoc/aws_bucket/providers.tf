provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Vendor    = "zilliz-byoc"
    }
  }
}
