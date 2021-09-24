when RULE_INIT {
    set static::cap_http_client_ip "IP_ADDRESS"
    set static::cap_http_host "HOST_VALUE"
    set static::cap_http_path "PATH_VALUE"
}

# An iRule event triggered when the system fully parses the complete 
# client HTTP request headers (that is, the method, URI, version, 
# and all headers, not including the HTTP request body).
when HTTP_REQUEST {
    set measure_request 0
    # https://support.f5.com/csp/article/K21541017
    if { [HTTP::has_responded] } {
        return
    }
    # IF static::cap_http_host is not set start commenting here
    if { [IP::client_addr] equals $static::cap_http_client_ip } {
        # IF static::cap_http_host is not set start commenting here
        if { [HTTP::host] equals $static::cap_http_host } {
            # IF static::cap_http_path is not set start commenting here
            if { [HTTP::path] equals $static::cap_http_path } {
                set measure_request 1
                set http_request_time [clock clicks -milliseconds]
                set req_definition "[IP::client_addr]:[TCP::client_port] -> [HTTP::host][HTTP::path]"
            }
        }
    }
}

# An iRule event triggered immediately before an HTTP request is sent to the
# server-side TCP stack. This is a server-side event.
when HTTP_REQUEST_SEND  {
    if { $measure_request } {
        set http_request_send_time [clock clicks -milliseconds]
    }
}

# An iRule event triggered when the system parses all of the response status
# and header lines from the server response. 
when HTTP_RESPONSE  {
    if { $measure_request } {
        set http_response_time [clock clicks -milliseconds]
    }
}

# An iRule event triggered when the system is about to release 
# HTTP data on the clientside of the connection.
# This event is triggered after modules process the HTTP response.
when HTTP_RESPONSE_RELEASE {
    if { $measure_request } {
        set http_response_send [clock clicks -milliseconds]
        # F5 REQ_TIME: (request received)-(request sent)  
        set f5_req_time [expr { $http_request_send_time - $http_request_time } ]
        # BE RESP_TIME (request sent) - (response recevied)
        set be_resp_time [expr { $http_response_time - $http_request_send_time } ]
        # F5 RESP_TIME: (response received)-(response sent)
        set f5_resp_time [expr { $http_response_send - $http_response_time } ]
        # REQ_DEFINITION: additional information about request from HTTP_REQUEST event
        log local0. "F5 REQ_TIME: $f5_req_time ; BE RESP_TIME: $be_resp_time ; F5 RESP_TIME: $f5_resp_time ; $req_definition"
    }
}
