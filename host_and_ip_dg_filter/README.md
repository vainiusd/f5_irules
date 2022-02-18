## Limitig access to websites by source IP and HTTP Host

* Separate iRule source IP address datagroups per HTTP Host. Change names `urlX_allowed_ip_dg` to configured address type data groups.
* Script switch uses lowercase HTTP Host names. Change HTTP host value `urlX.smn.lt` to the needed website FQDN.
* Default action is to allow traffic.
* Uncomment logging for troubleshooting purposes