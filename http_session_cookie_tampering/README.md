## Session cookie enforcement iRule


 Force login to web page based on session cookie presence and integrity
 Session cookie is generated after a successful login by the backend server

### Workflow

iRule workflow:
1.  Start with a browsing session without any knowledge of the web page.
2.  Go to any URL of the web page.
3.  Receive a redirect to $static::website_name_login_url
4.  Provide correct credentials, receive a response in which: 
  1.  The server sets cookie $static::cookie_auth_name
  2.  F5 copies the value of $static::cookie_auth_name to a new cookie $static::cookie_encr_name and encrypts it with static::cookie_encr_key
5.  When you visit any intranet page after authentication the browser must provide both cookies: 
  1.  F5 decrypts $static::cookie_encr_name and checks if it matches $static::cookie_auth_name
  2.  If $static::cookie_auth_name and $static::cookie_encr_name do not match, client is redirected to login
  3.  If $static::cookie_auth_name and $static::cookie_encr_name are missing, client is redircted to login