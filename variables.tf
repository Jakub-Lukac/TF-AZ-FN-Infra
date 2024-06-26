variable "env_client_id" {
  type = string
}

variable "env_client_secret" {
  type = string
}

variable "env_tenant_id" {
  type = string
}

variable "env_subscription_id" {
  type = string
}


variable "application_name" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "fn_keyvault_name" {
  type = string
}

variable "eventhub_enabled" {
  type = bool
}

variable "fn_eventhub_namespace_name" {
  type = string
}

variable "fn_eventhub_name" {
  type = string
}

variable "fn_eventhub_policy_name" {
  type = string
}