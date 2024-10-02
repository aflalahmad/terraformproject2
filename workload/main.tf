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
    # Backend Address Pool(s)
  
  backend_address_pools = {
    pool1 = {
      name = "myBackendPool"

    }
  }

  
    backend_address_pool_addresses = {
    address1 = {
      
      name                             = "ipconfig1" 
      backend_address_pool_object_name = "pool1"
      ip_address                       = data.azurerm_virtual_machine_scale_set.private_ip_address.instances[0].private_ip_address
      virtual_network_resource_id      = module.virtualnetwork["workloadVNet"].resource_id
      
    },
    address2 = {
      
      name                             = "ipconfig2" 
      backend_address_pool_object_name = "pool1"
      ip_address                       = data.azurerm_virtual_machine_scale_set.private_ip_address.instances[1].private_ip_address
      virtual_network_resource_id      = module.virtualnetwork["workloadVNet"].resource_id
      
    }
    }

  # Health Probe(s)
  lb_probes = {
    tcp1 = {
      name     = "myHealthProbe"
      protocol = "Tcp"
    }
  }

  # Load Balaner rule(s)
  lb_rules = {
    http1 = {
      name                           = "myHTTPRule"
      frontend_ip_configuration_name = "internal_lb_private_ip_1_config"

      backend_address_pool_object_names = ["pool1"]
      protocol                          = "Tcp"
      frontend_port                     = 80
      backend_port                      = 80

      probe_object_name = "tcp1"

      idle_timeout_in_minutes = 15
      enable_tcp_reset        = true
    }
  }
  
}


resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


module "virtualmachinescaleset" {
  source  = "Azure/avm-res-compute-virtualmachinescaleset/azurerm"
  version = "0.3.0"
  for_each = var.VMss
  name                        = each.value.name
  resource_group_name         = module.rg.name
  location                    = var.location
  admin_password              = "P@ssword12345"
  instances                   = each.value.instances
  sku_name                    = each.value.sku_name
  extension_protected_setting = {}
  user_data_base64            = null
  admin_ssh_keys = [(
    {
      username   = "azureuser"
       public_key = tls_private_key.example_ssh.public_key_openssh
      id= tls_private_key.example_ssh.id
    }
  )]
  network_interface = [{
    name                      = "VMSS-NIC"
    network_security_group_id = module.networksecuritygroup["nsg1"].resource_id
    ip_configuration = [{
      name      = "VMSS-IPConfig"
      subnet_id = module.subnet["subnet1"].resource_id
      
    }]
  }]
  os_profile = {
    custom_data = base64encode(file("custom-data.yaml"))
    linux_configuration = {
      disable_password_authentication = false
      user_data_base64                = base64encode(file("user-data.sh"))
      admin_username                  = "azureuser"
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

data "azurerm_virtual_machine_scale_set" "private_ip_address" {
  name                = "VMss"
  resource_group_name = module.rg.name
}



























# module "keyvault-vault" {
#   source  = "Azure/avm-res-keyvault-vault/azurerm"
#   version = "0.9.1"
#   name                           = var.keyvault_name
#   location                       = var.location
#   resource_group_name            = module.rg.name
#   tenant_id                      = data.azurerm_client_config.this.tenant_id
#   legacy_access_policies_enabled = true
#   legacy_access_policies = {
#     test = {
#       object_id          = data.azurerm_client_config.this.object_id
#       tenant_id          = data.azurerm_client_config.this.tenant_id
#       secret_permissions = [
#         "Get", "List"]
#     }
#   }
#    for_each = var.keyvault_secret
#    secrets = {
#     test_secret = {
#       name = each.value.name
#     }
#   }
#   secrets_value = {
#     test_secret = each.value.value
#   }
# }

