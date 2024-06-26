#------------------------------------------------------
# PART 1 : Register application with required permissions for Azure Function
#------------------------------------------------------

data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  application_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing   = true
}

resource "azuread_application" "app" {
  display_name     = "${var.application_name}-${var.environment_name}"
  sign_in_audience = "AzureADMyOrg"

  required_resource_access {
    resource_app_id = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph # "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    # These following API Application permissions need to have admin consent granted for current tenant

    resource_access {
      id   = "5b567255-7703-4780-807c-7be8301ae99b" #Group.Read.All
      type = "Role"
    }

    resource_access {
      id   = "98830695-27a2-44f7-8c18-0c3ebc9698f6" #GroupMember.Read.All
      type = "Role"
    }

    resource_access {
      id   = "df021288-bdef-4463-88db-98f22de89214" #User.Read.All
      type = "Role"
    }
  }
}

resource "azuread_service_principal" "app_principal" {
  application_id = azuread_application.app.application_id
}

resource "azuread_application_password" "app_secret" {
  application_object_id = azuread_application.app.object_id
  display_name          = "Secret for UserChecker app"
}


#------------------------------------------------------
# PART 2 : Create Azure Key Vault for credentials
#------------------------------------------------------


data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_group_location

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_key_vault" "fnkv" {
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  name                = var.fn_keyvault_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  lifecycle {
    ignore_changes = [tags]
  }
}

# access policy for terraform app
resource "azurerm_key_vault_access_policy" "akv_tf_policy" {
  key_vault_id = azurerm_key_vault.fnkv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Set",
    "Get",
    "List",
    "Delete",
    "Purge",
  ]
}

resource "azurerm_key_vault_secret" "app_conf_app_id" {
  name         = "conf-app-id"
  value        = azuread_application.app.application_id
  key_vault_id = azurerm_key_vault.fnkv.id

  # value is directly depended, which is well-known to terraform
  # however access policy is not directly depended code-wise
  # but access policy has to be created, only afterwards the secret can be created
  depends_on = [azurerm_key_vault_access_policy.akv_tf_policy]
}

resource "azurerm_key_vault_secret" "app_conf_app_secret" {
  name         = "conf-app-secret"
  value        = azuread_application_password.app_secret.value
  key_vault_id = azurerm_key_vault.fnkv.id

  depends_on = [azurerm_key_vault_access_policy.akv_tf_policy]
}

resource "azurerm_key_vault_secret" "app_conf_tenant_id" {
  name         = "conf-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.fnkv.id

  depends_on = [azurerm_key_vault_access_policy.akv_tf_policy]
}

#------------------------------------------------------
# PART 3 : Create Event Hub Namespace + key vault secrets
#------------------------------------------------------

# namespace - logical container for grouping multiple event hubs

resource "azurerm_eventhub_namespace" "ehns" {
  count                    = var.eventhub_enabled ? 1 : 0
  name                     = var.fn_eventhub_namespace_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  sku                      = "Standard"
  capacity                 = 2
  auto_inflate_enabled     = true
  maximum_throughput_units = 4

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_eventhub" "eh" {
  count = var.eventhub_enabled ? 1 : 0
  name = var.fn_eventhub_name
  namespace_name = azurerm_eventhub_namespace.ehns[0].name
  resource_group_name = azurerm_resource_group.main.name
  partition_count = 16
  message_retention = 1
}

resource "azurerm_eventhub_authorization_rule" "ehpolicy" {
  count = var.eventhub_enabled ? 1 : 0
  name = var.fn_eventhub_policy_name
  namespace_name = azurerm_eventhub_namespace.ehns[0].name
  eventhub_name = azurerm_eventhub.eh[0].name
  resource_group_name = azurerm_resource_group.main.name
  listen = true
  send = true
  manage = false
}

resource "azurerm_key_vault_secret" "app_conf_hubconnection" {
  name = "conf-hub-connection"
  value = var.eventhub_enabled ? azurerm_eventhub_authorization_rule.ehpolicy[0].primary_connection_string : ""
  key_vault_id = azurerm_key_vault.fnkv.id

  depends_on = [ azurerm_key_vault_access_policy.akv_tf_policy ]
}

resource "azurerm_key_vault_secret" "app_conf_hubname" {
  name = "conf-hub-name"
  value = var.eventhub_enabled ? azurerm_eventhub.eh[0].name : ""
  key_vault_id = azurerm_key_vault.fnkv.id

  depends_on = [ azurerm_key_vault_access_policy.akv_tf_policy ]
}
