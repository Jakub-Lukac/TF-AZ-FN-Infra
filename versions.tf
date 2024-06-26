# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.89.0"
    }
  }

  backend "azurerm" {}

  required_version = ">= 1.5.0"
}

provider "random" {
}

provider "azurerm" {
  skip_provider_registration = "true"
  features {}

  client_id       = var.env_client_id
  client_secret   = var.env_client_secret
  tenant_id       = var.env_tenant_id
  subscription_id = var.env_subscription_id
}

provider "azuread" {
  client_id     = var.env_client_id
  client_secret = var.env_client_secret
  tenant_id     = var.env_tenant_id
}