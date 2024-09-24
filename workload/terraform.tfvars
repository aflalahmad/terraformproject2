resource_group = "workloadB"
location = "West Europe"

virtual_network = {
    workloadVNet = {
    name = "workloadVNet"
    address_space = "10.0.0.0/16"
  }
}


subnet = {
  "subnet1" = {
    name = "web_subnet"
    address_prefixes = "10.0.1.0/24"
    #zone = "1"
  },
  "subnet2" = {
    name = "app_subnet"
    address_prefixes = "10.0.2.0/24"
    #zone = "2"
  },
  "subnet3" = {
    name = "DB_subnet"
    address_prefixes = "10.0.3.0/24"
    #zone = "3"
  },
}

nsg_name = ["nsg1","nsg2","nsg3"]

# public_ip = {
#     public_ip = {
#     name = "public_ip"
#     allocation_method = "Static"
#     sku = "Standard"
#     sku_tier = "Regional"
   
# }
# }

lb = {

    loadbalancer = {
        name = "load_balancer"
        
        frontendip = {
        frontendip_config = {
            name = "internal_lb_private_ip_1_config"
        }
        }
    }
}

keyvault_name = "project6635"

keyvault_secret = {
  secret1 = {
  name = "secretusername"
  value = "terraformproject2"
  },
  secret2 = {
    name = "secretpassword"
    value = "P@ssword12345"
  }
}