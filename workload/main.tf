data "azurerm_client_config" "this" {}

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
  frontend_subnet_resource_id = module.subnet["subnet1"].resource_id
  frontend_ip_configurations = {
   frontend_configuration_1 = {
      name = each.value.frontendip["frontendip_config"].name
      frontend_private_ip_subnet_resource_id = module.subnet["subnet1"].resource_id
    }
  }
  depends_on = [ module.subnet ]
  
}

module "keyvault-vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.9.1"
  name                           = var.keyvault_name
  location                       = var.location
  resource_group_name            = module.rg.name
  tenant_id                      = data.azurerm_client_config.this.tenant_id
  legacy_access_policies_enabled = true
  legacy_access_policies = {
    test = {
      object_id          = data.azurerm_client_config.this.object_id
      tenant_id          = data.azurerm_client_config.this.tenant_id
      secret_permissions = [
        "Get", "List"]
    }
  }
   for_each = var.keyvault_secret
   secrets = {
    test_secret = {
      name = each.value.name
    }
  }
  secrets_value = {
    test_secret = each.value.value
  }
}

module "virtualmachinescaleset" {
  source  = "Azure/avm-res-compute-virtualmachinescaleset/azurerm"
  version = "0.3.0"
  name                        = ""
  resource_group_name         = module.rg.name
  location                    = var.location
  admin_password              = ""
  instances                   = 2
  sku_name                    = module.get_valid_sku_for_deployment_region.sku
  extension_protected_setting = {}
  user_data_base64            = null
  boot_diagnostics = {
    storage_account_uri = "" # Enable boot diagnostics
  }
  admin_ssh_keys = [(
    {
      id         = tls_private_key.example_ssh.id
      public_key = tls_private_key.example_ssh.public_key_openssh
      username   = "azureuser"
    }
  )]
  network_interface = [{
    name                      = "VMSS-NIC"
    network_security_group_id = azurerm_network_security_group.nic.id
    ip_configuration = [{
      name      = "VMSS-IPConfig"
      subnet_id = azurerm_subnet.subnet.id
    }]
  }]
  os_profile = {
    custom_data = base64encode(file("custom-data.yaml"))
    linux_configuration = {
      disable_password_authentication = false
      user_data_base64                = base64encode(file("user-data.sh"))
      admin_username                  = "azureuser"
      admin_ssh_key                   = toset([tls_private_key.example_ssh.id])
    }
  }
  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS-gen2" # Auto guest patching is enabled on this sku.  https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching
    version   = "latest"
  }
  extension = [{
    name                        = "HealthExtension"
    publisher                   = "Microsoft.ManagedServices"
    type                        = "ApplicationHealthLinux"
    type_handler_version        = "1.0"
    auto_upgrade_minor_version  = true
    failure_suppression_enabled = false
    settings                    = "{\"port\":80,\"protocol\":\"http\",\"requestPath\":\"/index.html\"}"
  }]
}