# Outputs File
#
# Expose the outputs you want your users to see after a successful 
# `terraform apply` or `terraform output` command. You can add your own text 
# and include any data from the state file. Outputs are sorted alphabetically;
# use an underscore _ to move things to the bottom. 
output "resource_group_id" {
  description = "Resource Group ID"
  # Attribute Reference
  value = azurerm_resource_group.rg.id
}
output "resource_group_name" {
  description = "Resource Group name"
  # Argument Reference
  value = azurerm_resource_group.rg.name
}
output "kv_id" {
  value = azurerm_key_vault.tfkvs.id
}
output "vault_uri" {
  value = azurerm_key_vault.tfkvs.vault_uri
}

/*
output "secret_value" {
  value     = data.azurerm_key_vault_secret.tfsecret.value
  sensitive = true
}*/

