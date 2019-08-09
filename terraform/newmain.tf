terraform {

  backend "consul" {
    address      = "127.0.0.1:8500"
    scheme       = "http"
    path         = "terraform/azure/hashilab"
    access_token = "b89add27-703d-2fa8-3526-066e708142ba"
  }

}

provider "vault" {
  address = "http://127.0.0.1:8200"
}

data "vault_generic_secret" "subID" {
  path = "kv/azure/subscription"
}
data "vault_generic_secret" "tenantID" {
  path = "kv/azure/tenant"
}
data "vault_generic_secret" "spID" {
  path = "kv/azure/spTerraform"
}

provider "azurerm" {
  version         = "=1.28.0"
  subscription_id = "${data.vault_generic_secret.subID.data["id"]}"
  tenant_id       = "${data.vault_generic_secret.tenantID.data["id"]}"
  client_id       = "${data.vault_generic_secret.spID.data["applicationID"]}"
  client_secret   = "${data.vault_generic_secret.spID.data["clientSecret"]}"
}
