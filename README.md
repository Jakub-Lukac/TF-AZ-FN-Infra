# TF-AZ-FN-Infra

## Project Overview

This Azure Function triggers upon receiving events from an Event Hub. It processes each event individually and retrieves the user's Display Name using the Graph API based on the extracted UserID. The Azure Function consists of multiple functions with different triggers (HTTP, EventHub, Timer). The Graph API is implemented as a core component of these functions.

# Terraform Setup

## Terraform service principal Setup

To run this code, you need to get an Azure Subscription ID. Run the az login command to get a list of available subscriptions.

To create a Terraform service principal, go to portal.azure.com open up the cloud power shell, and run the following command:

```text
az ad sp create-for-rbac -n terraform --role="Contributor" --scopes="/subscriptions/{your-subcription-id}"
```

From the command output, note the `appId` value and `password` and store them in var.tf file. Note them as `env_` variables together with subscription_id and tenant_id.

```text
{
  "appId": "b194bcf7-****-****-****-5a8fed8448ff",
  "displayName": "terraform",
  "password": "**************************",
  "tenant": "ab22e0f4-****-****-****-9be459c33fb2"
}
```

```text
variable "env_client_id" {
  type    = string
  default = ""
}

variable "env_client_secret" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type    = string
  default = ""
}

variable "subscription_id" {
  type    = string
  default = ""
}
```

Terraform uses Azure AD Application to run commands. For creating new resources, **terraform** Application needs API Permissions as follows:

```text
Microsoft Graph

  User.ReadWrite.All                        Application
  Group.ReadWrite.All                       Application
```

After adding permissions use the **Grant admin consent** button to commit permissions.
