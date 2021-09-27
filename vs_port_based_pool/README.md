## Virtaul server port based pool port

iRules for TCP/UDP load balancing based on virtual server client side L4 port.
Used when there are many listeners on data collecting servers/applications in order to simplify F5 configuration.
Additionally could be even more simplified by omitting pool configuration and pointing traffic directly to node:cs_port. 

## TCP

### iRule PRFX_TCP
```
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
  if {[catch {pool $PRFX_pool_name}]}{
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
```

### TCP logs:

```
Jun 14 10:20:03 f5-large info tmm1[8602]: Rule /Common/PRFX_TCP <CLIENT_ACCEPTED>: Local port is: 5201
Jun 14 10:20:03 f5-large info tmm1[8602]: Rule /Common/PRFX_TCP <CLIENT_ACCEPTED>: Chosen pooldoes not exist. Switching to default pool
Jun 14 10:20:15 f5-large info tmm1[8602]: Rule /Common/PRFX_TCP <LB_FAILED>: Load balancing for TCP DST port 5201 failed.
Jun 14 10:23:52 f5-large info tmm1[8602]: Rule /Common/PRFX_TCP <CLIENT_ACCEPTED>: Local port is: 5198
Jun 14 10:23:52 f5-large info tmm1[8602]: Rule /Common/PRFX_TCP <CLIENT_ACCEPTED>: Chosen pool is: PRFX_Pool_5198
Jun 14 10:24:04 f5-large info tmm1[8602]: Rule /Common/PRFX_TCP <LB_FAILED>: Load balancing for TCP DST port 5198 failed.
```

## UDP

### iRule PRFX_UDP
```
when RULE_INIT {
  # If variable names are not unique in iRules then they can be overwritten
  set static::PRFX_pool_prefix "PRFX_Pool_"
  set static::PRFX_default_pool "PRFX_Default_Pool"
}

when CLIENT_ACCEPTED {
  # Get clientside local port (TCP destination port)
  set cs_server_port [UDP::local_port]
  log local0.info "Local port is: $cs_server_port"
  
  # Set pool name based on local port
  set PRFX_pool_name "${static::PRFX_pool_prefix}${cs_server_port}"  
  
  # If pool exists, load balance to it
  if {[catch {pool $PRFX_pool_name}]}{
    # Pool does not exist, fail load balancing
    log local0.info "Pool for DST port $cs_server_port ($PRFX_pool_name) does not exist. Switching to default pool ($static::PRFX_default_pool)"
    pool $static::PRFX_default_pool
  } else {
    log local0.info "Chosen pool is: $PRFX_pool_name"
    pool $PRFX_pool_name
  }
}

when LB_FAILED {
  log local0.info "Load balancing for UDP DST port $cs_server_port failed."
}
```

### UDP logs:

```
Jun 14 10:26:25 f5-large info tmm3[8602]: Rule /Common/PRFX_UDP <CLIENT_ACCEPTED>: Local port is: 5198
Jun 14 10:26:25 f5-large info tmm3[8602]: Rule /Common/PRFX_UDP <CLIENT_ACCEPTED>: Chosen pool is: PRFX_Pool_5198
Jun 14 10:26:34 f5-large info tmm3[8602]: Rule /Common/PRFX_UDP <CLIENT_ACCEPTED>: Local port is: 5201
Jun 14 10:26:34 f5-large info tmm3[8602]: Rule /Common/PRFX_UDP <CLIENT_ACCEPTED>: Pool for DST port 5201 (PRFX_Pool_5201) does not exist. Switching to default pool (PRFX_Default_Pool)
```

## Configs

### Port list

Listen to these ports/ port ranges:
```
net port-list PRFX_port_list {
    ports {
        5198 { }
        5199 { }
        5200-5250 { }
    }
}
```

### VS

#### TCP

```
ltm traffic-matching-criteria VS_PRFX_VS_TMC_OBJ {
    destination-address-inline 10.48.7.77
    destination-port-list PRFX_port_list
    protocol tcp
    source-address-inline 0.0.0.0
}

admin@(f5-large)(cfg-sync Standalone)(Active)(/Common)(tmos)# list ltm virtual VS_PRFX
ltm virtual VS_PRFX {
    creation-time 2020-06-14:09:01:27
    ip-protocol tcp
    last-modified-time 2020-06-14:10:37:56
    pool PRFX_Default_Pool
    profiles {
        tcp { }
    }
    rules {
        PRFX_TCP
    }
    traffic-matching-criteria VS_PRFX_VS_TMC_OBJ
    translate-address enabled
    translate-port disabled
    vs-index 6
}
```

#### UDP
```
ltm traffic-matching-criteria VS_PRFX_VS_TMC_OBJ {
    destination-address-inline 10.48.7.77
    destination-port-list PRFX_port_list
    protocol udp
    source-address-inline 0.0.0.0
}

ltm virtual VS_PRFX {
    creation-time 2020-06-14:09:01:27
    ip-protocol udp
    last-modified-time 2020-06-14:10:26:06
    pool PRFX_Default_Pool
    profiles {
        udp { }
    }
    rules {
        PRFX_UDP
    }
    traffic-matching-criteria VS_PRFX_VS_TMC_OBJ
    translate-address enabled
    translate-port disabled
    vs-index 6
}
```

### Pools
```
ltm pool PRFX_Default_Pool {
    members {
        PRFX1:syslog-tls {
            address 192.168.2.4
        }
        PRFX2:syslog-tls {
            address 192.168.2.5
        }
    }
}
ltm pool PRFX_Pool_5198 {
    members {
        PRFX1:5198 {
            address 192.168.2.4
        }
        PRFX2:5198 {
            address 192.168.2.5
        }
    }
}
ltm pool PRFX_Pool_5199 {
    members {
        PRFX1:5199 {
            address 192.168.2.4
        }
        PRFX2:5199 {
            address 192.168.2.5
        }
    }
}
```