module "backup_instances" {
  source = "module_repo"
  backup_configs = merge(
    // Blob backups
    {
      for sa in local.blob_backup_instances : sa.name => {
        type                 = "blob"
        storage_account_name = sa.name
        vault_id             = module.azure_vault["${try(sa.tags.workload, "unknown")}-${try(sa.tags.environment, "unknown")}-${try(sa.location, "unknown")}"].backup_vault_id
        location             = sa.location
        environment          = sa.tags.environment
        storage_account_id   = sa.resourceId
        policy_id            = lookup(module.azure_vault["${try(sa.tags.workload, "unknown")}-${try(sa.tags.environment, "unknown")}-${try(sa.location, "unknown")}"].blob_storage_backup_policy, lower(sa.tags.backup), null)
        container_names      = ["tescontainer1", "testcontainer2", "container3"]
      }
    },
    // Disk backups
    {
      for md in local.disk_backup_instances : md.name => {
        type                         = "disk"
        disk_id                      = md.resourceId
        azure_disk_name              = md.name
        location                     = md.location
        environment                  = md.tags.environment
        vault_id                     = module.azure_vault["${try(md.tags.workload, "unknown")}-${try(md.tags.environment, "unknown")}-${try(md.location, "unknown")}"].backup_vault_id
        policy_id                    = lookup(module.azure_vault["${try(md.tags.workload, "unknown")}-${try(md.tags.environment, "unknown")}-${try(md.location, "unknown")}"].disks_backup_policy, lower(md.tags.backup), null)
        snapshot_resource_group_name = "rg-backup-testing"
      }
    }
  )
}
