# A web application on Azure. Read as text by the examples, never applied.

resource "azurerm_resource_group" "app" {
  name     = "rg-booking-prod"
  location = "australiaeast"
}

resource "azurerm_virtual_network" "app" {
  name                = "vnet-booking"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  address_space       = ["10.30.0.0/16"]
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = ["10.30.1.0/24"]
}

resource "azurerm_service_plan" "app" {
  name                = "asp-booking"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  os_type             = "Linux"
  sku_name            = "P1v3"
}

resource "azurerm_linux_web_app" "api" {
  name                      = "app-booking-api"
  location                  = azurerm_resource_group.app.location
  resource_group_name       = azurerm_resource_group.app.name
  service_plan_id           = azurerm_service_plan.app.id
  virtual_network_subnet_id = azurerm_subnet.app.id

  site_config {}

  app_settings = {
    SQL_SERVER = azurerm_mssql_server.app.fully_qualified_domain_name
    KEY_VAULT  = azurerm_key_vault.app.vault_uri
  }
}

resource "azurerm_mssql_server" "app" {
  name                = "sql-booking"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  version             = "12.0"
}

resource "azurerm_mssql_database" "bookings" {
  name      = "bookings"
  server_id = azurerm_mssql_server.app.id
}

resource "azurerm_key_vault" "app" {
  name                = "kv-booking"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  tenant_id           = "00000000-0000-0000-0000-000000000000"
  sku_name            = "standard"
}

resource "azurerm_storage_account" "files" {
  name                     = "stbookingfiles"
  location                 = azurerm_resource_group.app.location
  resource_group_name      = azurerm_resource_group.app.name
  account_tier             = "Standard"
  account_replication_type = "ZRS"
}

resource "azurerm_application_insights" "app" {
  name                = "appi-booking"
  location            = azurerm_resource_group.app.location
  resource_group_name = azurerm_resource_group.app.name
  application_type    = "web"
}
