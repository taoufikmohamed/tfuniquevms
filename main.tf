// Terrafor IAC to provision resources to Azure 
// Variables are stored in tfvars and varialbes_file for deafult values 
//Keyvault used to store sensitives data: username, password and other secrets 
//https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=azure-powershell

# Terraform Block
# Terraform Block
terraform {
  required_version = ">=1.3.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
  //  https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
  // Backend to store current state in a blob storage
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstaat"
    container_name       = "tfstate"
    key                  = "vms.terraform.tfstate"
  }
}


# Provider Block
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    //skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  }
  subscription_id = var.subscription
  tenant_id       = var.tenant
  client_id       = var.client
  client_secret   = var.clientsecret
}

data "azurerm_client_config" "current" {} //data source to access the configuration of the AzureRM provider.

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "tsa" {
  name                     = "${var.prefix}sa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"

  tags = {
    environment = "dev"
  }
}
resource "azurerm_storage_data_lake_gen2_filesystem" "dsys" {
  name               = "tfdatalake"
  storage_account_id = azurerm_storage_account.tsa.id
  /*properties = {
    hello = "aGVsbG8="
  }*/
}
resource "azurerm_key_vault" "tfkvs" {
  name                        = "tfkvs01"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id #"ef80a7c8-e662-4d93-8648-c458911e6f5f"
  #soft_delete_retention_days  = 7
  #purge_protection_enabled    = false

  sku_name = "standard"
}
/*access_policy {
    tenant_id =  "var.tenant"     #service principal tenant id
    object_id =  "var.client      #service principal obj id

    key_permissions = [
      "Get",
    ]
    secret_permissions = [
      "Get",
      "Set",
      "delete"
    ]

    storage_
    permissions = [
      "Get",
    ]
  }
}*/
resource "azurerm_key_vault_access_policy" "principal" {
  key_vault_id = azurerm_key_vault.tfkvs.id
  tenant_id    = data.azurerm_client_config.current.tenant_id #sp tenant id
  object_id    = data.azurerm_client_config.current.object_id ##sp obj id

  key_permissions = [
    "Get", "List", "Encrypt", "Decrypt"
  ]
  secret_permissions = [
    "Get", "Set", "List", "Delete", "Restore", "Backup", "Recover"
  ]
  depends_on = [azurerm_key_vault.tfkvs]
}
resource "azurerm_key_vault_secret" "tfsecu" {
  name  = "tfadmin"
  value = var.secret_value
  depends_on = [
    azurerm_key_vault.tfkvs,
    azurerm_key_vault_access_policy.principal,
  ]
  key_vault_id = azurerm_key_vault.tfkvs.id
}
resource "azurerm_key_vault_secret" "sectenant" {
  name  = "sectenant"
  value = var.sec_tenant
  depends_on = [
    azurerm_key_vault.tfkvs,
    azurerm_key_vault_access_policy.principal,
  ]
  key_vault_id = azurerm_key_vault.tfkvs.id
}
resource "azurerm_key_vault_secret" "secclientsecret" {
  name  = "secclientsecret"
  value = var.client_secret
  depends_on = [
    azurerm_key_vault.tfkvs,
    azurerm_key_vault_access_policy.principal,
  ]
  key_vault_id = azurerm_key_vault.tfkvs.id

}
resource "azurerm_key_vault_secret" "secsub" {
  name         = "secsub"
  value        = var.subscription
  key_vault_id = azurerm_key_vault.tfkvs.id
  depends_on = [
    azurerm_key_vault.tfkvs,
    azurerm_key_vault_access_policy.principal,
  ]
}
resource "azurerm_key_vault_secret" "secclient" {
  name         = "secclient"
  value        = var.client
  key_vault_id = azurerm_key_vault.tfkvs.id
  depends_on = [
    azurerm_key_vault.tfkvs,
    azurerm_key_vault_access_policy.principal,
  ]
}
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "sub" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.vm_map
  name                = "${each.value.name}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sub.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "tfvm" {
  for_each            = var.vm_map
  name                = each.value.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = each.value.size                      //"Standard_F2"
 admin_username      = azurerm_key_vault_secret.tfsecu.name  //username fetched from keyvault (VM username)
  admin_password     = azurerm_key_vault_secret.tfsecu.value // password fetched from keyvault (VM password)
  depends_on = [ azurerm_key_vault.tfkvs, 
  azurerm_key_vault_access_policy.principal,
   ]
    network_interface_ids=[azurerm_network_interface.nic[each.key].id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}



