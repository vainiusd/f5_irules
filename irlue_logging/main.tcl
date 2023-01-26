when HTTP_REQUEST {

   ### Log via High-speed logging (data interfaces)
   set hsl [HSL::open -proto UDP -pool log_server_pool]
   # Log HTTP request as local7.info; see RFC 3164 Section 4.1.1 - "PRI Part" for more info
   HSL::send $hsl "<190> [IP::local_addr] [HTTP::uri]\n"
  
   ### Log via management interface
   log 192.168.0.2:514 local7.info "[IP::local_addr] [HTTP::uri]"
   
   ### Log to local file (local0 -> /var/log/ltm)
   log local0.info "[IP::local_addr] [HTTP::uri]"
 
}
