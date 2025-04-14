resource "azurerm_role_assignment" "storage_backup_contributor" {
  for_each = {
    for combo_key, vault in local.vault_resource_mappings : 
    combo_key => vault
    if length(vault.storage_accounts) > 0
  }

  dynamic "sa_assignment" {
    for_each = {
      for sa in each.value.storage_accounts : 
      "${each.key}-${sa.name}" => sa
    }
    content {
      scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${sa_assignment.value.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${sa_assignment.value.name}"
      role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1" # Storage Account Backup Contributor
      principal_id       = module.backup_vault[each.key].vault_principal_id
    }
  }
}

resource "azurerm_role_assignment" "postgresql_ltr_backup" {
  for_each = {
    for combo_key, vault in local.vault_resource_mappings : 
    combo_key => vault
    if length(vault.postgresql_servers) > 0
  }

  dynamic "psql_assignment" {
    for_each = {
      for psql in each.value.postgresql_servers : 
      "${each.key}-${psql.name}" => psql
    }
    content {
      scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${psql_assignment.value.resource_group_name}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${psql_assignment.value.name}"
      role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/c088a766-074b-43ba-90d4-1fb21feae531" # PostgreSQL LTR Backup
      principal_id       = module.backup_vault[each.key].vault_principal_id
    }
  }
}
