#####################
# terraform and provider config
#####################

terraform {
  required_version = ">= 1.1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 3.3.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "0.1.1"
    }
  }
}

provider "azurerm" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  features {}
}

provider "azapi" {
  client_id       = var.client_id
  environment     = var.environment
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

#####################
# Resources
#####################

resource "azurerm_resource_group" "resource-group" {
  name     = "resource-group"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "Log-Analytics-Workspace" {
  name                = "Log-Analytics-Workspace"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource-group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azapi_resource" "Logs-Ingest" {
  provider  = azapi
  type      = "Microsoft.OperationalInsights/workspaces/dataSources@2020-08-01"
  name      = "Logs-Ingest"
  parent_id = azurerm_log_analytics_workspace.Log-Analytics-Workspace.id

  body = jsonencode({
    properties = {
      customLogName = "IngestLogs_CL"
      description = "Data Source to ingest /var/log/messages"
      inputs = [{
        location = {
          fileSystemLocations = {
            linuxFileTypeLogPaths = ["/var/log/messages"],
          }
        },
        recordDelimiter = {
          regexDelimiter = {
            pattern = "\\n",
            matchIndex = 0,
            numberdGroup = null
          }
        }
        }
      ],
      extractions = [
        {
          extractionName = "TimeGenerated",
          extractionType = "DateTime",
          extractionProperties = {
            dateTimeExtraction = {
              regex = null,
              joinStringRegex = null
            }
          }
        }
      ]
    }
    kind = "CustomLog"
  })
}