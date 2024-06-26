output "msgraph" {
  value = azuread_service_principal.msgraph.application_id
}

output "eventhub_enabled" {
  value = var.eventhub_enabled
}