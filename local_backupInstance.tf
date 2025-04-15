  blob_backup_instances = {
    for sa in local.storage_accounts :
    sa.name => sa
    if(
      lookup(sa.tags, "backup", "none") != "none" &&
      lookup(sa.tags, "backup", "disabled") != "disabled" &&
      lookup(sa.tags, "backup", "none") != "none" ?
      contains(keys(local.blob_storage_backup_policies), lookup(sa.tags, "backup", "none")) : false
    ) &&
    contains(keys(local.workload_env_region_combinations), "${try(sa.tags.workload, "unknown")}-${try(sa.tags.environment, "unknown")}-${try(sa.location, "unknown")}")
  }

  disk_backup_instances = {
    for md in local.managed_disks :
    md.name => md
    if(
      lookup(md.tags, "backup", "none") != "none" &&
      lookup(md.tags, "backup", "disabled") != "disabled" &&
      lookup(md.tags, "backup", "none") != "none" ?
      contains(keys(local.managed_disk_backup_policies), lookup(md.tags, "backup", "none")) : false
    ) &&
    contains(keys(local.workload_env_region_combinations), "${try(md.tags.workload, "unknown")}-${try(md.tags.environment, "unknown")}-${try(md.location, "unknown")}")
  }
