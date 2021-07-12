# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used 
terraform {
  backend "azurerm" {
  }
}

# Configure the Azure provider
provider "azurerm" {
    skip_provider_registration = true
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
    features {}
}

# Create resource group
resource "azurerm_resource_group" "avalon-group" {
    name     = "Avalon-ResourceGroup-${var.sourceBranchName}"
    location = "${var.location}"

    tags = {
        Avalon = "${var.sourceBranchName}"
    }
}

# Create app service plan
resource "azurerm_app_service_plan" "avalon-plan" {
    name                = "Avalon-AppServicePlan-${var.sourceBranchName}"
    location            = azurerm_resource_group.avalon-group.location
    resource_group_name = azurerm_resource_group.avalon-group.name
    kind                = "Linux"
    reserved            = true
    
    sku {
        tier = "Standard"
        size = "S1"
    }

    tags = {
        Avalon = azurerm_resource_group.avalon-group.tags.Avalon
    }
}

# Create app service
resource "azurerm_app_service" "avalon" {
    name                = "Avalon-${var.sourceBranchName}"
    location            = azurerm_resource_group.avalon-group.location
    resource_group_name = azurerm_resource_group.avalon-group.name
    app_service_plan_id = azurerm_app_service_plan.avalon-plan.id

    site_config {
        dotnet_framework_version = "v5.0"
        linux_fx_version = "v5.0"
        # remote_debugging_enabled = true
        # remote_debugging_version = "VS2019"
        always_on = "true"
        ftps_state = "FtpsOnly"
        http2_enabled = "true"
        use_32_bit_worker_process = "false"
        min_tls_version = "1.2"
    }

    app_settings = {
        "Mongo_Database" = "Avalon"
        "Auth0_Domain" = "${var.auth0domain}"
        "Auth0_ApiIdentifier" = "${var.auth0apiIdentifier}"
        "Auth0_Claims_nameidentifier" = "${var.auth0claimsnameidentifier}"
        "Auth0_TokenAddress" = "${var.auth0tokenaddress}"
    }

    # connection_string {
    #     name  = "Database"
    #     type  = "SQLServer"
    #     value = "Server=tcp:demosqlserver.database.windows.net,1433;Initial Catalog=demosqldatabase;Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    # }

    https_only = "true"

    identity {
        type = "SystemAssigned"
    }

    logs {
        http_logs {
            file_system {
                retention_in_mb = 30 # in Megabytes
                retention_in_days = 7 # in days
            }
        }
    }

    tags = {       
        Avalon = azurerm_resource_group.avalon-group.tags.Avalon
    }
}

# Create app service slot
resource "azurerm_app_service_slot" "avalon-slot" {
    name                = "Avalon-staging-${var.sourceBranchName}"
    location            = azurerm_resource_group.avalon-group.location
    resource_group_name = azurerm_resource_group.avalon-group.name
    app_service_plan_id = azurerm_app_service_plan.avalon-plan.id
    app_service_name    = azurerm_app_service.avalon.name

    site_config {
        dotnet_framework_version = "v5.0"
        # remote_debugging_enabled = true
        # remote_debugging_version = "VS2019"
        always_on = "true"
        ftps_state = "FtpsOnly"
        http2_enabled = "true"
        use_32_bit_worker_process = "false"
        min_tls_version = "1.2"
    }

    app_settings = {
        "Mongo_Database" = "Avalon"
        "Auth0_Domain" = "${var.auth0domain}"
    }

    # connection_string {
    #     name  = "Mongo_ConnectionString"
    #     type  = "SQLServer"
    #     value = "Server=tcp:demosqlserver.database.windows.net,1433;Initial Catalog=demosqldatabase;Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    # }

    https_only = "true"

    identity {
        type = "SystemAssigned"
    }

    logs {
        http_logs {
            file_system {
                retention_in_mb = 30 # in Megabytes
                retention_in_days = 7 # in days
            }
        }
    }

    tags = {       
        Avalon = azurerm_resource_group.avalon-group.tags.Avalon
    }
}

# # Create application insights. Obs! Not working for Linux!
# resource "azurerm_application_insights" "avalon-insights" {
#  name                = "avalon-insights"
#  location            = azurerm_resource_group.avalon-group.location
#  resource_group_name = azurerm_resource_group.avalon-group.name
#  application_type    = "web"
#  disable_ip_masking  = false
#  retention_in_days   = 30

#  tags = {       
#         Avalon = azurerm_resource_group.avalon-group.tags.Avalon
#     }
# }