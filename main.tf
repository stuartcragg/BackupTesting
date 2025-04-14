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
