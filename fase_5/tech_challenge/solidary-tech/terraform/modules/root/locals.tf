locals {
  environment_map = {
    dev = "Development"
    hom = "Homologation"
    pro = "Production"
  }

  environment_tag = lookup(local.environment_map, var.env, title(var.env))
}
