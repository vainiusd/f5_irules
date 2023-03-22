# Allow-listing IP addresses:
when CLIENT_ACCEPTED priority 100 {
    if { not [class match [getfield [IP::client_addr] "%" 1] equals DG_NAME ] } {
        #log local0. "Session denied from [IP::client_addr] to [virtual name]"
        drop
        # reject
    }
} 

# Deny-listing IP addresses:
when CLIENT_ACCEPTED priority 100 {
    if { [class match [getfield [IP::client_addr] "%" 1] equals DG_NAME ] } {
        #log local0. "Session denied from [getfield [IP::client_addr] "%" 1] to [virtual 
name]"
        drop
        # reject
    }
}
