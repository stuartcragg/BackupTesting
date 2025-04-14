# locals.tf
data "local_file" "managed_disks" {
  filename = "/var/adoagent/_work/1/s/managed_disks.json"
}

data "local_file" "storage_accounts" {
  filename = "/var/adoagent/_work/1/s/storage_accounts.json"
}

data "local_file" "postgresql_servers" {
  filename = "/var/adoagent/_work/1/s/postgresql_servers.json"
}

locals {
  # Normalize disk data
  raw_managed_disks = try(jsondecode(data.local_file.managed_disks.content), [])
  managed_disks = [
    for md in local.raw_managed_disks : merge(md, {
      tags = {
        for k, v in coalesce(md.tags, {}) : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(md.location)
      type = "disk"
    })
  ]

  # Normalize storage account data
  raw_storage_accounts = try(jsondecode(data.local_file.storage_accounts.content), [])
  storage_accounts = [
    for sa in local.raw_storage_accounts : merge(sa, {
      tags = {
        for k, v in coalesce(sa.tags, {}) : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(sa.location)
      type = "storage_account"
    })
  ]

  # Normalize PostgreSQL server data
  raw_postgresql_servers = try(jsondecode(data.local_file.postgresql_servers.content), [])
  postgresql_servers = [
    for ps in local.raw_postgresql_servers : merge(ps, {
      tags = {
        for k, v in coalesce(ps.tags, {}) : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(ps.location)
      type = "postgresql_server"
    })
  ]

  # Combine all resources
  all_resources = concat(local.managed_disks, local.storage_accounts, local.postgresql_servers)

  # Create unique workload-environment-region combinations
  workload_env_region_combinations = {
    for res in local.all_resources :
    "${try(res.tags.workload, "unknown")}-${try(res.tags.environment, "unknown")}-${try(res.location, "unknown")}" => res...
    if try(res.tags.workload, "") != "" &&
       try(res.tags.environment, "") != "" &&
       try(res.location, "") != "" &&
       try(res.tags.backup, "") != "" &&
       lower(try(res.tags.backup, "none")) != "none" &&
       lower(try(res.tags.backup, "disabled")) != "disabled" &&
       contains(var.approved_workloads, lower(try(res.tags.workload, "unknown")))
  }

  # Map vaults to their matching resources
  vault_resource_mappings = {
    for combo_key, resources in local.workload_env_region_combinations :
    combo_key => {
      workload   = split("-", combo_key)[0]
      environment = split("-", combo_key)[1]
      region      = split("-", combo_key)[2]
      resource_group = lookup(var.backup_vault_resource_group_name, split("-", combo_key)[1], "rg-backup-default")
      disks = [
        for res in resources : res
        if res.type == "disk" &&
           res.tags.workload == split("-", combo_key)[0] &&
           res.tags.environment == split("-", combo_key)[1] &&
           res.location == split("-", combo_key)[2] &&
           lower(try(res.tags.backup, "none")) != "none" &&
           lower(try(res.tags.backup, "disabled")) != "disabled"
      ]
      storage_accounts = [
        for res in resources : res
        if res.type == "storage_account" &&
           res.tags.workload == split("-", combo_key)[0] &&
           res.tags.environment == split("-", combo_key)[1] &&
           res.location == split("-", combo_key)[2] &&
           lower(try(res.tags.backup, "none")) != "none" &&
           lower(try(res.tags.backup, "disabled")) != "disabled"
      ]
      postgresql_servers = [
        for res in resources : res
        if res.type == "postgresql_server" &&
           res.tags.workload == split("-", combo_key)[0] &&
           res.tags.environment == split("-", combo_key)[1] &&
           res.location == split("-", combo_key)[2] &&
           lower(try(res.tags.backup, "none")) != "none" &&
           lower(try(res.tags.backup, "disabled")) != "disabled"
      ]
    }
  }
}
