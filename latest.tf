data "local_file" "postgresql_flexible" {
  filename = "/var/adoagent/_work/1/s/${var.env_short_code}_postgres_flexible_servers.json"
}

locals {
  approved_workloads = ["app1", "app2", "myapp",]

  all_resources = concat(local.managed_disks, local.storage_accounts, local.postgresql_flexible)


  raw_postgresql_flexible = try(jsondecode(data.local_file.postgresql_flexible.content), [])
  postgresql_flexible = [
    for pg in local.raw_postgresql_flexible : merge(pg, {
      tags = {
        for k, v in pg.tags : lower(k) => (
          k == "backup" || k == "workload" || k == "environment" ? lower(v) : v
        )
      }
      location            = replace(lower(pg.location), " ", "")
      type                = "postgresql_flexible"
      resource_group_name = pg.resourceGroup
      containers          = try(pg.containers, [])
    })
  ]

  postgresql_flexible_instances = {
    for pg in local.postgresql_flexible :
    pg.name => pg
    if(
      lookup(pg.tags, "backup", "none") != "none" &&
      lookup(pg.tags, "backup", "none") != "disabled" &&
      contains(keys(local.postgres_backup_policies), lookup(pg.tags, "backup", "none")) &&
      contains(keys(local.workload_env_region_combinations), "${try(pg.tags.workload, "unknown")}-${try(pg.tags.environment, "unknown")}-${try(pg.location, "unknown")}")
    )
  }

  workload_env_region_combinations = {
    for res in local.all_resources :
    "${try(res.tags.workload, "unknown")}-${try(res.tags.environment, "unknown")}-${try(res.location, "unknown")}" =>
    res...
    if try(res.tags.workload, "") != "" &&
    try(res.tags.environment, "") != "" &&
    try(res.location, "") != "" &&
    try(res.tags.backup, "") != "" &&
    lower(try(res.tags.backup, "none")) != "none" &&
    lower(try(res.tags.backup, "disabled")) != "disabled" &&
    contains(local.approved_workloads, lower(try(res.tags.workload, "unknown")))
  }

}
