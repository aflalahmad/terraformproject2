variable "resource_group" {
    type = string
    description  = "this is resource groyp name"
  
}

variable "location" {
  type = string
  description = "this is location"
}

variable "virtual_network" {

type = map(object({
  name = string
  address_space = string
})) 
}

variable "subnet" {
  type = map(object({
    name = string
    address_prefixes = string
    #zone = string
  }))
}

variable "nic" {
  type = map(object({
    name = string
    primary = bool
    ip_configuration = map(object({
      ip_config_name = string
      private_ip_allocation = string 
    }))
  }))
}

variable "nsg_name" {
  type = list(string)
  
}


variable "lb" {
  type = map(object({
     name = string
     frontendip = map(object({
       name = string  
     }))
  })) 
}

variable "keyvault_name" {
  type = string
  
}

variable "keyvault_secret" {
  type = map(object({
    name = string
    value = string
  }))
  
}

variable "VMss" {
  type = map(object({
    name = string
    instances = string
    sku_name = string
  }))
}
