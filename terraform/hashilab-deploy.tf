
variable "vnet-name" {
  type    = "string"
  default = ""
}
variable "vnet-cidr" {
  type    = "string"
  default = ""
}
variable "server-subnet-cidr" {
  type    = "string"
  default = ""
}
variable "jumpbox-subnet-cidr" {
  type    = "string"
  default = ""
}
variable "rg-name" {
  type    = "string"
  default = ""
}
variable "location" {
  type    = "string"
  default = ""
}
variable "admin-username" {
  type    = "string"
  default = ""
}
variable "admin-password" {
  type    = "string"
  default = ""
}
variable "inbound-rdp-allow-cidr" {
  type    = "string"
  default = ""
}



module "hashilab" {

  source = "./modules/hashilab"

  vnet-name              = "${var.vnet-name}"
  vnet-cidr              = "${var.vnet-cidr}"
  server-subnet-cidr     = "${var.server-subnet-cidr}"
  jumpbox-subnet-cidr    = "${var.jumpbox-subnet-cidr}"
  rg-name                = "${var.rg-name}"
  location               = "${var.location}"
  admin-username         = "${var.admin-username}"
  admin-password         = "${var.admin-password}"
  inbound-rdp-allow-cidr = "${var.inbound-rdp-allow-cidr}"

}
