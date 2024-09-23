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
  
  depends_on = [ module.rg ]
}

module "subnet" {
  source = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"

  virtual_network = {
    resource_id = module.virtualnetwork["workloadVNet"].resource_id
  }
   for_each = var.subnet
  name             = each.value.name
  address_prefixes =  [each.value.address_prefixes]
  depends_on = [module.virtualnetwork]
}


module "networksecuritygroup" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.2.0"
  for_each = toset(var.nsg_name)
  name = each.key
  location = var.location
  resource_group_name = module.rg.name
  depends_on = [ module.rg ]
}


# module "publicipaddress" {
#   source  = "Azure/avm-res-network-publicipaddress/azurerm"
#   version = "0.1.2"
#   for_each = var.public_ip
#   name = each.key
#   location = var.location
#   resource_group_name = module.rg.name
#   sku = each.value.sku
#   sku_tier = each.value.sku_tier
#   allocation_method = each.value.allocation_method

# }

module "loadbalancer" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.2.2"
  for_each = var.lb
  name = each.key
  location = var.location
  resource_group_name = module.rg.name
  sku = each.value.sku
  sku_tier = each.value.sku_tier
  frontend_ip_configurations = {
    frontend_ip = {
      name = each.value.frontendip["frontendip_config"].name
      #subnet_id = module.subnet["subnet1"].resource_id
      subnet_id = module.subnet.subnet1_id
      private_ip_address = each.value.frontendip["frontendip_config"].private_ip_address
      private_ip_address_allocation = each.value.frontendip["frontendip_config"].private_ip_address_allocation
    }
  }
  depends_on = [ module.subnet ]
  
}