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