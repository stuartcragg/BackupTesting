# ----------------------------------------------------------------------------------------------------------------------
# Read in the JSON files from local storage
# ----------------------------------------------------------------------------------------------------------------------

data "local_file" "storage_accounts" {
  filename = "/var/adoagent/_work/1/s/storage_accounts.json"
  //filename = "C:/Code/Temp/storage_accounts.json"
}


data "local_file" "managed_disks" {
  filename = "/var/adoagent/_work/1/s/managed_disks.json"
  //filename = "C:/Code/Temp/managed_disks.json"
}

locals {
  approved_workloads = ["app1", "app2", "app3", "app4"]

  # ----------------------------------------------------------------------------------------------------------------------
  # Set the tags on each resource type to lowercase for consistency
  # ----------------------------------------------------------------------------------------------------------------------

  raw_storage_accounts = try(jsondecode(data.local_file.storage_accounts.content), [])
  storage_accounts = [
    for sa in local.raw_storage_accounts : merge(sa, {
      tags = {
        for k, v in sa.tags : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(sa.location)
    })
  ]

  raw_managed_disks = try(jsondecode(data.local_file.managed_disks.content), [])
  managed_disks = [
    for md in local.raw_managed_disks : merge(md, {
      tags = {
        for k, v in coalesce(md.tags, {}) : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(md.location)
    })
  ]

  # ----------------------------------------------------------------------------------------------------------------------
  # Create the backup instances for each resource type
  # ----------------------------------------------------------------------------------------------------------------------

  blob_backup_instances = {
    for sa in local.storage_accounts :
    sa.name => sa
    if(
      lookup(sa.tags, "backup", "none") != "none" &&
      lookup(sa.tags, "backup", "disabled") != "disabled" &&
      lookup(sa.tags, "backup", "none") != "none" ? contains(keys(local.blob_storage_backup_policies), lookup(sa.tags, "backup", "none")) : false
    ) &&
    contains(keys(local.workload_env_region_combinations), "${try(sa.tags.workload, "unknown")}-${try(sa.tags.environment, "unknown")}-${try(sa.location, "unknown")}")
  }

  disk_backup_instances = {
    for md in local.managed_disks :
    md.name => md
    if(
      lookup(md.tags, "backup", "none") != "none" &&
      lookup(md.tags, "backup", "disabled") != "disabled" &&
      lookup(md.tags, "backup", "none") != "none" ? contains(keys(local.managed_disk_backup_policies), lookup(md.tags, "backup", "none")) : false
    ) &&
    contains(keys(local.workload_env_region_combinations), "${try(md.tags.workload, "unknown")}-${try(md.tags.environment, "unknown")}-${try(md.location, "unknown")}")
  }

 postgresql_flexible_instances = {
    for pg in local.postgresql_flexible :
    pg.name => pg
    if(
      lookup(pg.tags, "backup", "none") != "none" &&
      lookup(pg.tags, "backup", "disabled") != "disabled" &&
      lookup(pg.tags, "backup", "none") != "none" ? contains(keys(local.postgres_backup_policies), lookup(pg.tags, "backup", "none")) : false
    ) &&
    contains(keys(local.workload_env_region_combinations), "${try(pg.tags.workload, "unknown")}-${try(pg.tags.environment, "unknown")}-${try(pg.location, "unknown")}")
  }

  # ----------------------------------------------------------------------------------------------------------------------
  # Group workloads by environment and region
  # ----------------------------------------------------------------------------------------------------------------------

  workload_env_region_combinations = {
    #for sa in local.storage_accounts :
    for sa in local.managed_disks :
    "${try(sa.tags.workload, "unknown")}-${try(sa.tags.environment, "unknown")}-${try(sa.location, "unknown")}" => sa...
    if try(sa.tags.workload, "") != "" &&
    try(sa.tags.environment, "") != "" &&
    try(sa.location, "") != "" &&
    //contains(local.approved_workloads, try (sa.tags.workload, "unknown"))
    contains(local.approved_workloads, lower(try(sa.tags.workload, "unknown")))
  }
}
