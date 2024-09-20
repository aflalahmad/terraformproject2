#create resource group
module "resourcegroup" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"
  name = var.resource_group
  location = var.location
}

#create virtual network
module "avm-res-network-virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.4.0"
  for_each = var.virtual_network
  address_space      = [each.value.address_space]
  location            = module.resourcegroup.location
  name                = each.key
  resource_group_name = module.resourcegroup.name
   
}
