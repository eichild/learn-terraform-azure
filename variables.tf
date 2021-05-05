variable "location" {}

variable "prefix" {
  type = string
  default = "my"
}

variable "tags" {
  type = map

  default = {
    Environment = "Terraform GS"
    Dept = "Engineering"
  }
}

variable "sku" {
  default = {
    eastus = "16.04-LTS"
    westus2 = "18.04-LTS"
  }
}