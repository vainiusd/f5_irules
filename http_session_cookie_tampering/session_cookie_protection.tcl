# Force login to web page based on session cookie presence and integrity
# Session cookie is generated after a successful login by the backend server

# iRule workflow:
# 1.  Start with a browsing session without any knowledge of the web page.
# 2.  Go to any URL of the web page.
# 3.  Receive a redirect to $static::website_name_login_url
# 4.  Provide correct credentials, receive a response in which: 
#     a.  The server sets cookie $static::cookie_auth_name
#     b.  F5 copies the value of $static::cookie_auth_name to a new cookie
#        $static::cookie_encr_name and encrypts it with static::cookie_encr_key
# 5.  When you visit any intranet page after authentication the browser 
#        must provide both cookies: 
#     a.  F5 decrypts $static::cookie_encr_name and checks if it 
#        matches $static::cookie_auth_name
#     b.  If $static::cookie_auth_name and $static::cookie_encr_name
#        do not match, client is redirected to login
#     c.  If $static::cookie_auth_name and $static::cookie_encr_name
#        are missing, client is redircted to login

when RULE_INIT {
    set static::cookie_auth_name "backend_cookie"
    set static::cookie_encr_name "f5_cookie"
    set static::website_name_login_url "/login/"
    set static::cookie_encr_key "p@ssw0rd"
    set static::cookie_auth_debug 0
}

when HTTP_REQUEST priority 100 {
    # Pass $static::website_name_login_url (and longer links)
    # and pass /favicon.ico file without cookie check
    if { [string tolower [HTTP::path]] starts_with $static::website_name_login_url } {
        if { $static::cookie_auth_debug } { log local0. "Request for login page '[HTTP::path]' - passing request" }
        return
    } elseif { [string tolower [HTTP::path]] equals "/favicon.ico" } {
        if { $static::cookie_auth_debug } { log local0. "Request for '/favicon.ico' - passing request" }
        return
    } 


    # Check availability of authenticated session cookie 
    set login_redirect 1
    if { [HTTP::cookie exists $static::cookie_auth_name] } {
        if { [HTTP::cookie exists $static::cookie_encr_name] } {
            set decrypted_cookie [HTTP::cookie decrypt $static::cookie_encr_name $static::cookie_encr_key]
            if { [string eq [HTTP::cookie $static::cookie_auth_name] $decrypted_cookie] } {
                set login_redirect 0
                if { $static::cookie_auth_debug } { log local0. "Cleartext session cookie and encrypted session cookie values match - passing request" }
            } else {
                if { $static::cookie_auth_debug } { log local0. "Cleartext session cookie and encrypted session cookie values do not match - redirecting to login" }
            }
        } else {
            if { $static::cookie_auth_debug } { log local0. "Encrypted session cookie not provided - redirecting to login" }
        }
    } else {
        if { $static::cookie_auth_debug } { log local0. "Cleartext session cookie not provided - redirecting to login" }
    }
    if { $login_redirect } {
        HTTP::redirect "https://[HTTP::host]$static::website_name_login_url"
        if { $static::cookie_auth_debug } { log local0. "Redirect to login page sent for client [IP::client_addr]" }
    }
}

when HTTP_RESPONSE priority 100 {
    if { [HTTP::cookie exists $static::cookie_auth_name] } {
        HTTP::cookie insert name $static::cookie_encr_name value [HTTP::cookie value $static::cookie_auth_name]
        HTTP::cookie expires $static::cookie_encr_name [HTTP::cookie expires $static::cookie_auth_name] absolute
        HTTP::cookie maxage $static::cookie_encr_name [HTTP::cookie maxage $static::cookie_auth_name]
        HTTP::cookie path $static::cookie_encr_name [HTTP::cookie path $static::cookie_auth_name]
        HTTP::cookie domain $static::cookie_encr_name [HTTP::cookie domain $static::cookie_auth_name]
        HTTP::cookie secure $static::cookie_encr_name enable
        HTTP::cookie encrypt $static::cookie_encr_name $static::cookie_encr_key
    }
}
