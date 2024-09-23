output "name"{
    value = module.rg.name
}

output "subnet1_id" {
  value = module.subnet["subnet1"].resource_id
}

