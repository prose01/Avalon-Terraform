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

# Generate random text for a unique name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

# Create resource group
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup-${var.sourceBranchName}"
    location = "${var.location}"

    tags = {
        environment = "Terraform demo01"
        build       = "demo01"
        myterraformgroup = "${var.sourceBranchName}"
    }
}

# Create app service plan
resource "azurerm_app_service_plan" "plandemo" {
    name                = "slotAppServicePlan-${var.sourceBranchName}"
    location            = azurerm_resource_group.myterraformgroup.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
    sku {
        tier = "Standard"
        size = "S1"
    }

    tags = {
        environment = azurerm_resource_group.myterraformgroup.tags.environment
        build       = azurerm_resource_group.myterraformgroup.tags.build
        myterraformgroup = azurerm_resource_group.myterraformgroup.tags.myterraformgroup
    }
}

# Create app service
resource "azurerm_app_service" "servicedemo" {
    name                = "${random_id.randomId.hex}slotAppService-${var.sourceBranchName}"
    location            = azurerm_resource_group.myterraformgroup.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    app_service_plan_id = azurerm_app_service_plan.plandemo.id

    site_config {
        dotnet_framework_version = "v5.0"
        remote_debugging_enabled = true
        remote_debugging_version = "VS2019"
    }

    app_settings = {
        "SOME_KEY" = "some-value"
    }

    # connection_string {
    #     name  = "Database"
    #     type  = "SQLServer"
    #     value = "Server=tcp:demosqlserver.database.windows.net,1433;Initial Catalog=demosqldatabase;Persist Security Info=False;User ID=${var.administrator_login};Password=${var.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    # }

    tags = {
        environment = azurerm_resource_group.myterraformgroup.tags.environment
        build       = azurerm_resource_group.myterraformgroup.tags.build
        myterraformgroup = azurerm_resource_group.myterraformgroup.tags.myterraformgroup
    }
}

# Create app service slot
resource "azurerm_app_service_slot" "slotdemo" {
    name                = "${random_id.randomId.hex}slotAppServiceSlotOne-${var.sourceBranchName}"
    location            = azurerm_resource_group.myterraformgroup.location
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    app_service_plan_id = azurerm_app_service_plan.plandemo.id
    app_service_name    = azurerm_app_service.servicedemo.name

    site_config {
        dotnet_framework_version = "v5.0"
        remote_debugging_enabled = true
        remote_debugging_version = "VS2019"
    }

    tags = {
        environment = azurerm_resource_group.myterraformgroup.tags.environment
        build       = azurerm_resource_group.myterraformgroup.tags.build
        myterraformgroup = azurerm_resource_group.myterraformgroup.tags.myterraformgroup
    }
}

# Create storage account
# resource "azurerm_storage_account" "mystorageaccount" {
#     name                        = "${random_id.randomId.hex}${var.sourceBranchName}"
#     resource_group_name         = azurerm_resource_group.myterraformgroup.name
#     location                    = azurerm_resource_group.myterraformgroup.location
#     account_replication_type    = "${var.storage_replication_type}"
#     account_tier                = "${var.storage_account_tier}"

#     tags = {
#         environment = azurerm_resource_group.myterraformgroup.tags.environment
#         build       = azurerm_resource_group.myterraformgroup.tags.build
#         myterraformgroup = azurerm_resource_group.myterraformgroup.tags.myterraformgroup
#     }
# }

# Create container
# resource "azurerm_storage_container" "mycontainer" {
#   name                 = "mystoragecontainer-${var.sourceBranchName}"
#   storage_account_name = azurerm_storage_account.mystorageaccount.name
# }

# # Create sql server
# resource "azurerm_sql_server" "demosqlserver" {
#   name                         = "msdemosqlserver-${var.sourceBranchName}"
#   resource_group_name          = azurerm_resource_group.myterraformgroup.name
#   location                     = azurerm_resource_group.myterraformgroup.location
#   version                      = "12.0"
#   administrator_login          = "${var.administrator_login}"
#   administrator_login_password = "thisIsDog11"

#   tags = {
#        environment = azurerm_resource_group.myterraformgroup.tags.environment
#        build       = azurerm_resource_group.myterraformgroup.tags.build
#        myterraformgroup = azurerm_resource_group.myterraformgroup.tags.myterraformgroup
#   }
# }

# # Create sql database
# resource "azurerm_sql_database" "demosqldatabase" {
#   name                = "mydemosqldatabase-${var.sourceBranchName}"
#   resource_group_name = azurerm_resource_group.myterraformgroup.name
#   location            = azurerm_resource_group.myterraformgroup.location
#   server_name         = azurerm_sql_server.demosqlserver.name

#   extended_auditing_policy {
#     storage_endpoint                        = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
#     storage_account_access_key              = azurerm_storage_account.mystorageaccount.primary_access_key
#     storage_account_access_key_is_secondary = true
#     retention_in_days                       = 6
#   }

#   tags = {
#        environment = azurerm_resource_group.myterraformgroup.tags.environment
#        build       = azurerm_resource_group.myterraformgroup.tags.build
#        myterraformgroup = azurerm_resource_group.myterraformgroup.tags.myterraformgroup
#   }
# }