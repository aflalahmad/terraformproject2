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
  subnets = map(object({
    name = string
    address_prefixes = string
    zone = string 
  }))
})) 
}

variable "nsg_name" {
  type = list(string)
  
}

variable "public_ip" {
  type = map(object({
    name =string
    sku = string
    allocation_method = string
    sku_tier = string
  }))
  
}

# variable "lb" {
#   type = map(object({
#      name = string
#      sku = string
#      sku_tier  =string
#      edge_zone = string
#      frontendip = map(object({
#        name = string
#         frontend_private_ip_address_version = string
#            frontend_private_ip_address_allocation = string
#            zones = list(string)
#      }))
     

#   }))
  
# }
