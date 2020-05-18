provider "azurerm" {
  version = "=1.28"
}

variable "service_principal_client_id" {
  description = "The Client ID for the Service Principal"
}

variable "service_principal_client_secret" {
  description = "The Client Secret for the Service Principal"
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-cluster_demo"
  location = "East US"
}

resource "azurerm_network_security_group" "sg" {
  name                = "aks-ntwrk_sg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "network" {
  name                = "aks_virtual_net"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                      = "aks_subnet_grp"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.sg.id}"
  address_prefix            = "10.1.0.0/24"
  virtual_network_name      = "${azurerm_virtual_network.network.name}"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name       = "aks_test"
  location   = "${azurerm_resource_group.rg.location}"
  dns_prefix = "aksDemo"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  kubernetes_version  = "1.15.10"

  agent_pool_profile {
    name           = "aks"
    count          = "1"
    vm_size        = "Standard_D2s_v3"
    os_type        = "Linux"
    vnet_subnet_id = "${azurerm_subnet.subnet.id}"
  }

  service_principal {
    client_id     = "${var.service_principal_client_id}"
    client_secret = "${var.service_principal_client_secret}"
  }

  network_profile {
    network_plugin = "azure"
  }
}

output "kube_config" {
  value = "${azurerm_kubernetes_cluster.cluster.kube_config_raw}"
}