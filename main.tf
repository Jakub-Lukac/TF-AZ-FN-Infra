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

