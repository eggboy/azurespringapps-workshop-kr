data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  count    = var.total_count
  name     = "${var.prefix}-rg-${var.postfix}${format("%02d", count.index + 1)}"
  location = var.location
}

resource "azurerm_key_vault" "example" {
  count                       = var.total_count
  name                        = "${var.prefix}-kv-${var.postfix}${format("%02d", count.index + 1)}"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.main[count.index].name
  tenant_id                   = "${data.azurerm_client_config.current.tenant_id}"
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.total_count
  name                = "${var.prefix}-la-${var.postfix}${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main[count.index].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_postgresql_flexible_server" "example" {
  count                  = var.total_count
  name                   = "${var.prefix}-db-${var.postfix}${format("%02d", count.index + 1)}"
  resource_group_name    = azurerm_resource_group.main[count.index].name
  location               = var.location
  version                = "12"
  administrator_login    = "acme"
  administrator_password = "super$ecr3t"
  zone                   = "1"

  storage_mb = 32768

  sku_name = "GP_Standard_D4s_v3"
}

resource "azurerm_redis_cache" "main" {
  count               = var.total_count
  name                = "${var.prefix}-cache-${var.postfix}${format("%02d", count.index + 1)}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main[count.index].name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}