#!/usr/bin/python
#
# Chen Gateway Protocol
#
# Example of using iControl REST
# From: https://devcentral.f5.com/s/articles/routing-http-by-request-headers
#
# Requires iControl REST > 11.5.0
#
# The following script allows one to dynamically update a data-group via
# iControl REST
#
import requests
import json

BIGIP_ADDRESS = '127.0.0.1'
BIGIP_USER = 'admin'
BIGIP_PASS = 'password'

DATA_GROUP = 'TEST_DG1'

class CGP(object):
    def __init__(self, host, user, passwd):
        self.host = host
        self.user = user
        self.passwd = passwd
        self.mgmt_url = "https://%s/mgmt/tm" %(host)

        self.session = requests.session()
        self.session.auth = (user, passwd)
        self.session.verify = False
        self.session.headers.update({'Content-Type':'application/json'})

    def get_data_group(self, dg_name):
        req_url = "%s/ltm/data-group/internal/%s" %(self.mgmt_url, dg_name)
        req = self.session.get(req_url)
        return (dict([(a['name'],a['data']) for a in req.json()['records']]),req.json()['type'])
        "return contents of data-group as dictionary"

    def set_data_group(self, dg_name, data, dg_type):
        req_url = "%s/ltm/data-group/internal/%s" %(self.mgmt_url, dg_name)
        datagroup = {'records': [{'data':r[1],'name':r[0]} for r in  data.items()]}
        datagroup['type'] = dg_type
        req = self.session.put(req_url,data = json.dumps(datagroup))
        "update contents of data-group as dictionary"
        

if __name__ == "__main__":
    import argparse
    import sys
    parser = argparse.ArgumentParser()
    parser.add_argument('action')
    parser.add_argument('dg_type')
    parser.add_argument('key')
    parser.add_argument('value',nargs='?')
    args = parser.parse_args()

    cgp = CGP(BIGIP_ADDRESS, BIGIP_USER, BIGIP_PASS)
    data,dg_type = cgp.get_data_group(DATA_GROUP)
    if dg_type != args.dg_type:
        print "error: datagroup type %s does not match actual type %s" %(args.dg_type,dg_type)
        sys.exit(1)
    if args.action == 'del':
        if args.key in data:        
            del data[args.key]
            print "deleted:", args.key
        else:
            print "error: %s does not exist" %(args.key)
            sys.exit(1)
    elif args.action == 'add':
        if args.key in data:
            print "error: %s already exists" %(args.key)
            sys.exit(1)
        else:
            data[args.key] = args.value
            print "added: %s" %(args.key)
    elif args.action == 'update':
        if args.key in data:        
            data[args.key] = args.value
            print "updated:", args.key
        else:
            print "error: %s does not exist" %(args.key)
            sys.exit(1)
    elif args.action == 'get':
        print "%s: %s" %(args.key,data.get(args.key,"DOES NOT EXIST"))
    cgp.set_data_group(DATA_GROUP, data, dg_type)