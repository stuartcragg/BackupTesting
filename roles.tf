# main.tf
module "azure_vault" {
  source = "./modules/azure_vault"
  for_each = local.vault_resource_mappings

  vault_name          = "backup-vault-${each.value.workload}-${each.value.environment}-${each.value.region}"
  resource_group_name = each.value.resource_group
  location            = each.value.region
}

resource "azurerm_role_assignment" "disk_backup_reader" {
  for_each = {
    for pair in flatten([
      for combo_key, vault in local.vault_resource_mappings : [
        for disk in vault.disks : {
          key = "${combo_key}-${disk.name}"
          combo_key = combo_key
          disk = disk
        }
      ]
    ]) : pair.key => pair
  }

  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${each.value.disk.resource_group_name}/providers/Microsoft.Compute/disks/${each.value.disk.name}"
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/3e5e47e6-65f7-47ef-90b5-e5dd4d455f24"
  principal_id       = module.azure_vault[each.value.combo_key].vault_system_identity_principal_id
}

resource "azurerm_role_assignment" "storage_backup_contributor" {
  for_each = {
    for pair in flatten([
      for combo_key, vault in local.vault_resource_mappings : [
        for sa in vault.storage_accounts : {
          key = "${combo_key}-${sa.name}"
          combo_key = combo_key
          sa = sa
        }
      ]
    ]) : pair.key => pair
  }

  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${each.value.sa.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${each.value.sa.name}"
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1"
  principal_id       = module.azure_vault[each.value.combo_key].vault_system_identity_principal_id
}

resource "azurerm_role_assignment" "postgresql_ltr_backup" {
  for_each = {
    for pair in flatten([
      for combo_key, vault in local.vault_resource_mappings : [
        for psql in vault.postgresql_servers : {
          key = "${combo_key}-${psql.name}"
          combo_key = combo_key
          psql = psql
        }
      ]
    ]) : pair.key => pair
  }

  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${each.value.psql.resource_group_name}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${each.value.psql.name}"
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/c088a766-074b-43ba-90d4-1fb21feae531"
  principal_id       = module.azure_vault[each.value.combo_key].vault_system_identity_principal_id
}
