when HTTP_REQUEST {
  switch -- [string tolower [HTTP::host]] {
    "url1.smn.lt" { 
      if { not ([class match [getfield [IP::client_addr] "%" 1] equals url1_allowed_ip_dg ]) } {
        #log local0. "Request rejected for [HTTP::host] from [IP::client_addr]"
        reject
      }
    }
    "url2.smn.lt" { 
      if { not ([class match [getfield [IP::client_addr] "%" 1] equals url1_allowed_ip_dg ]) } {
        #log local0. "Request rejected for [HTTP::host] from [IP::client_addr]"
        reject
      }
    }
    default { 
      #log local0. "Request allowed for [HTTP::host] from [IP::client_addr]"
      return
    }
  }
}