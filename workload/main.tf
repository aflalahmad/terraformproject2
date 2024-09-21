#create resource group
module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"
  name = var.resource_group
  location = var.location
}

#create virtual network
module "virtualnetwork" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.4.0"
  for_each = var.virtual_network
  address_space      = [each.value.address_space]
  location            = var.location
  name                = each.key
  resource_group_name = module.rg.name
  
  subnets = {
    subnet1 = {
      name = each.value.subnets["subnet1"].name
      address_prefixes = [each.value.subnets["subnet1"].address_prefixes]
      zone = each.value.subnets["subnet1"].zone
    },
     subnet2 = {
      name = each.value.subnets["subnet2"].name
      address_prefixes = [each.value.subnets["subnet2"].address_prefixes]
      zone = each.value.subnets["subnet2"].zone
    },
     subnet3 = {
      name = each.value.subnets["subnet3"].name
      address_prefixes =[ each.value.subnets["subnet3"].address_prefixes]
      zone = each.value.subnets["subnet3"].zone
    }
  }
  depends_on = [ module.rg ]
}

module "networksecuritygroup" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.2.0"
  for_each = toset(var.nsg_name)
  name = each.key
  location = var.location
  resource_group_name = module.rg.name
}


module "publicipaddress" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.1.2"
  for_each = var.public_ip
  name = each.key
  location = var.location
  resource_group_name = module.rg.name
  sku = each.value.sku
  sku_tier = each.value.sku_tier
  allocation_method = each.value.allocation_method

}

# module "loadbalancer" {
#   source  = "Azure/avm-res-network-loadbalancer/azurerm"
#   version = "0.2.2"
#   for_each = var.lb
#   name = each.key
#   location = var.location
#   resource_group_name = module.rg.name
#   sku = each.value.sku
#   sku_tier = each.value.sku_tier
  
# #   frontend_ip_configurations = {
# #     frontend_configuration_1 = {
# #       name = each.value.frontendip["frontendip_config"].name
# #       frontend_private_ip_address_version    = each.value.frontendip["frontendip_config"].frontend_private_ip_address_version
# #       frontend_private_ip_address_allocation = each.value.frontendip["frontendip_config"].frontend_private_ip_address_allocation
# #       zones = each.value.frontendip["frontendip_config"].zones
# #     }
# # }
# }