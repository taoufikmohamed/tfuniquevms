variable "resource_group_name" {
  description = "The name of your Azure Resource Group."
  default     = ""
}

variable "prefix" {
  description = "This prefix will be included in the name of some resources."
  default     = "tfx"
}
variable "subscription" {
  description = "Subscription Id to be used."
  default     = ""
}
variable "tenant" {
  description = "tenant Id to be used."
  default     = ""
}
variable "client" {
  description = "App Id to be used."
  default     = ""
}
variable "clientsecret" {
  description = "Client secret to be used."
  default     = ""
}
variable "location" {
  type        = string
  description = "The region where the virtual network is created."
  default     = "west Europe"
}
variable "secret_name" {
  type        = string
  description = "Secret in keyvault."
  default     = "tfadmin"
}
variable "secret_value" {
  type        = string
  description = "Value Secret in keyvault."
  default     = "TFSECtfsec01!"
  sensitive   = true
}
variable "secret_valuespdlsec" {
  type        = string
  description = "Value Secret in keyvault."
  default     = ""

}
/*variable "admin_username" {
  type        = string
  description = "Secret in keyvault."
  default     = ""
}
variable "admin_password" {
  type        = string
  description = "Secret in keyvault."
  default     = ""
  sensitive = true
}*/
variable "sec_tenant" {
  type        = string
  description = "Secret in keyvault."
  default     = "deftenant"
  }
variable "client_secret" {
  type        = string
  description = "Secret in keyvault."
  default     = "defclientsecret"
}
variable "vm_map" {
  type = map(object({
    name = string
    size = string
  }))
  default = {
    
    "vm1" = {
      name = "vm1"
      size = "Standard_B1s"
    }
    "vm2" = {
      name = "vm2"
      size = "Standard_B2s"
     }
    
    "vm3" = {
      name = "vm3"
      size = "Standard_B1s"
     }/*
    "vm4" = {
      name = "vm4"
      size = "Standard_B2s"

    }
    */
  }
}
