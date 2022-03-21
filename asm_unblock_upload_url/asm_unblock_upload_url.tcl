when ASM_REQUEST_DONE {
  if { [string tolower [HTTP::host]] starts_with "example.com" }{
    if { [ASM::violation names] contains "VIOLATION_REQUEST_TOO_LONG" } {
      if { [string tolower [HTTP::uri]] contains "/action/user/cost/request" } {
        ASM::unblock
      }
    }
  }
}