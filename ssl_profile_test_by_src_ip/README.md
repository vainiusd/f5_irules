## Test a Client SLL profile for a custom client IP range

iRule that allows choosing a custom Client SLL profile for a specified user group.
Users are identified by their IP address.

### Inputs

Configuration object names used in this iRule are set in event RULE_INIT.

Test user IP address list is stored in Data Group `/Common/data_group1`.
Custom SSL profile name is `clientssl1`.