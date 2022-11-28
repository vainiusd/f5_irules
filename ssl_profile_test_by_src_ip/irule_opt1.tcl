when RULE_INIT {
    # Using unique variable name will prevent this variable from colliding with other iRules
    ### Set configuration object names ###
    set static::OdOg9Xo_ssl_profile_name "clientssl1"
    set static::OdOg9Xo_ssl_datagroup_name "/Common/data_group1"
    
    # Initial check if datagroup exists, check /var/log/ltm for messages after applying iRule
    set static::OdOg9Xo_ssl_datagroup_exists 1
    if { not ([class exists $static::OdOg9Xo_ssl_datagroup_name]) } {
      log local0. "Data Group $static::OdOg9Xo_ssl_datagroup_name does not exist, please check configuration."
      set static::OdOg9Xo_ssl_datagroup_exists 0
  }
}


when CLIENT_ACCEPTED {
  if { $static::OdOg9Xo_ssl_datagroup_exists } {
    if { ([class match [IP::client_addr] equals $static::OdOg9Xo_ssl_datagroup_name]) } {
      # SSL::profile command requires a clientssl profile configured on VS
      if { [catch { SSL::profile $static::OdOg9Xo_ssl_profile_name }] } {
        # Log if catch notices a failure, the only option is a missing clientssl profile
        log local0. "Client SSL profile $static::OdOg9Xo_ssl_profile_name does not exist, please check configuration."
      }
    }
  }
}