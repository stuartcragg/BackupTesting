resource "azurerm_role_assignment" "disk_backup_reader" {
  for_each = {
    for combo_key, vault in local.vault_resource_mappings :
    combo_key => vault
    if length(vault.disks) > 0
  }

  scope              = "/subscriptions/${var.subscription_id}/resourceGroups/${each.value.disks[0].resource_group_name}/providers/Microsoft.Compute/disks/${each.value.disks[0].name}"
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/3e5e47e6-65f7-47ef-90b5-e5dd4d455f24" # Disk Backup Reader
  principal_id       = module.azure_vault[each.key].vault_system_identity_principal_id
