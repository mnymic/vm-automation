#----------providers--------
provider "azuread" {}
provider "azurerm" {}
provider "kubernetes" {
  host = module.aks.host
  client_certificate = module.aks.client_certificate
  client_key = module.aks.client_key
  cluster_ca_certificate = module.aks.cluster_ca_certificate}
provider "docker" {}
#----------vars--------
variable "prefix" {default = "dpl12-11"}
variable "location" {default = "westeurope"}
variable "my_name" {default = "rg-name"}
variable "admin_username" {default = "oro"}

output "pubip" {
  value = module.vm.public_ip_address
}
