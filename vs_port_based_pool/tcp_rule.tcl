when RULE_INIT {
  # If variable names are not unique in iRules then they can be overwritten
  set static::PRFX_pool_prefix "PRFX_Pool_"
  set static::PRFX_default_pool "PRFX_Default_Pool"
}

when CLIENT_ACCEPTED {
  # Get clientside local port (TCP destination port)
  set cs_server_port [TCP::local_port]
  log local0.info "Local port is: $cs_server_port"
  
  # Set pool name based on local port
  set PRFX_pool_name "${static::PRFX_pool_prefix}${cs_server_port}"  
  
  # If pool exists, load balance to it
  if {[catch {pool $PRFX_pool_name}]} {
    # Pool does not exist, fail load balancing
    log local0.info "Pool for DST port $cs_server_port ($PRFX_pool_name) does not exist. Switching to default pool ($static::PRFX_default_pool)"
    pool $static::PRFX_default_pool
  } else {
    log local0.info "Chosen pool is: $PRFX_pool_name"
    pool $PRFX_pool_name
  }
}

when LB_FAILED {
  log local0.info "Load balancing for TCP DST port $cs_server_port failed."
}