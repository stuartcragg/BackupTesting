locals {
  raw_storage_accounts = try(jsondecode(data.local_file.storage_accounts.content), [])
  storage_accounts = [
    for sa in local.raw_storage_accounts : merge(sa, {
      tags = {
        for k, v in coalesce(sa.tags, {}) : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(sa.location)
      resource_group_name = lower(sa.resource_group_name)
    })
  ]

  raw_postgresql_servers = try(jsondecode(data.local_file.postgresql_servers.content), [])
  postgresql_servers = [
    for ps in local.raw_postgresql_servers : merge(ps, {
      tags = {
        for k, v in coalesce(ps.tags, {}) : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location = lower(ps.location)
      resource_group_name = lower(ps.resource_group_name)
    })
  ]
}

locals {
  all_resources = concat(local.managed_disks, local.storage_accounts, local.postgresql_servers)
  workload_env_region_combinations = {
    for res in local.all_resources :
    "${try(res.tags.workload, "unknown")}-${try(res.tags.environment, "unknown")}-${try(res.location, "unknown")}" => res...
    if try(res.tags.workload, "") != "" &&
       try(res.tags.environment, "") != "" &&
       try(res.location, "") != "" &&
       contains(var.approved_workloads, lower(try(res.tags.workload, "unknown")))
  }

  vault_resource_mappings = {
    for combo_key, resources in local.workload_env_region_combinations :
    combo_key => {
      workload   = split("-", combo_key)[0]
      environment = split("-", combo_key)[1]
      region      = split("-", combo_key)[2]
      disks       = [
        for res in resources : res
        if lookup(res, "type", "") == "disk" &&
           res.tags.workload == split("-", combo_key)[0] &&
           res.tags.environment == split("-", combo_key)[1] &&
           res.location == split("-", combo_key)[2]
      ]
      storage_accounts = [
        for res in resources : res
        if lookup(res, "type", "") == "storage_account" &&
           res.tags.workload == split("-", combo_key)[0] &&
           res.tags.environment == split("-", combo_key)[1] &&
           res.location == split("-", combo_key)[2]
      ]
      postgresql_servers = [
        for res in resources : res
        if lookup(res, "type", "") == "postgresql_server" &&
           res.tags.workload == split("-", combo_key)[0] &&
           res.tags.environment == split("-", combo_key)[1] &&
           res.location == split("-", combo_key)[2]
      ]
    }
  }
}
