## Backend and F5 HTTP response delay measuring

Logging HTTP request delay times (in ms) for:
* F5 HTTP request processing (F5 REQ_TIME)
* Backend HTTP response to F5 (BE RESP_TIME)
* F5 HTTP response processing (F5 RESP_TIME)

Usually this is a troubleshooting task in response to notifications about large delays, which are measured from clientside.
There are always at least two suspects: middleware, like F5, and the backend servers.
This rule is used to help the investigation and pinpoint the root cause location.

### iRule logging filter configuration

``` 
when RULE_INIT {
    set static::cap_http_client_ip "IP_ADDRESS"
    set static::cap_http_host "HOST_VALUE"
    set static::cap_http_path "PATH_VALUE"
}
```
Turbūt trivialu kas yra kas. Svarbu, kad reikia įvesti kliento IP adresą, kurį “mato” F5. Šitą turbūt lengvai galite įvertinti iš ugniasienės konfigūracijos, bet berods pas jus Source NAT’as nedaromas.
HTTP path turi būti tikslus, HTTP path yra viskas, kas yra po HTTP host iki klaustuko URI dalyje.

### Logging requests to all HTTP host paths from client IP address

Comment lines:
```
    # IF static::cap_http_host is not set start commenting here
    if { [IP::client_addr] equals $static::cap_http_client_ip } {
        # IF static::cap_http_host is not set start commenting here
        if { [HTTP::host] equals $static::cap_http_host } {
            # IF static::cap_http_path is not set start commenting here
            # if { [HTTP::path] equals $static::cap_http_path } {
                set measure_request 1
                set http_request_time [clock clicks -milliseconds]
                set req_definition "[IP::client_addr]:[TCP::client_port] -> [HTTP::host][HTTP::path]"
            # }
        }
    }
```


### Logging all requests from client IP address

Comment lines:
    # IF static::cap_http_host is not set start commenting here
    if { [IP::client_addr] equals $static::cap_http_client_ip } {
        # IF static::cap_http_host is not set start commenting here
        # if { [HTTP::host] equals $static::cap_http_host } {
            # IF static::cap_http_path is not set start commenting here
            # if { [HTTP::path] equals $static::cap_http_path } {
                set measure_request 1
                set http_request_time [clock clicks -milliseconds]
                set req_definition "[IP::client_addr]:[TCP::client_port] -> [HTTP::host][HTTP::path]"
            # }
        # }
    }
