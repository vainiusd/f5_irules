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

import urllib3
urllib3.disable_warnings()

BIGIP_ADDRESS = '192.168.2.1'
BIGIP_USER = 'admin'
BIGIP_PASS = 'password'

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
        records = dict([(a['name'],a['data']) for a in req.json()['records']])
        dg_type = req.json()['type']
        return (dg_type, records)
        "return tuple: data-group type and contents of as dictionary"

    def set_data_group(self, dg_name, dg_type, records):
        req_url = "%s/ltm/data-group/internal/%s" %(self.mgmt_url, dg_name)
        datagroup = {'records': [{'data':r[1],'name':r[0]} for r in  records.items()]}
        datagroup['type'] = dg_type
        datagroup['name'] = dg_name
        req = self.session.put(req_url,data = json.dumps(datagroup))
        if req.status_code != 200:
            print('Response not OK: %s' %req.text)
        "update contents of data-group as dictionary"
    
    def create_data_group(self, dg_name, dg_type, records):
        req_url = "%s/ltm/data-group/internal/" %(self.mgmt_url)
        datagroup = {'records': [{'data':r[1],'name':r[0]} for r in  records.items()]}
        datagroup['type'] = dg_type
        datagroup['name'] = dg_name
        req = self.session.post(req_url,data = json.dumps(datagroup))
        if req.status_code != 200:
            print('Response not OK: %s' %req.text)
        "Create data-group with records"

if __name__ == "__main__":
    import argparse
    import sys
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--data-group', required=True, type=str, help='Data-group name')
    parser.add_argument('-a', '--action', required=True, type=str, help='Action: create, update, compare')
    parser.add_argument('-t', '--data-group-type', required=True, type=str, help='Type: ip, string, integer')
    parser.add_argument('-s', '--source', required=True, type=str, help='Link to data')
    #parser.add_argument('-f', '--file', help='Path to record file')
    args = parser.parse_args()

    DATA_GROUP = args.data_group
    DG_TYPE = args.data_group_type
    ACTION = args.action

    # Collect records for data-group from source argument
    # Records must be in a dictionary object
    # Dict key is of data-group type, value is any string
    #r = requests.get('https://www.cloudflare.com/ips-v4')
    r = requests.get(args.source)
    l = r.text.split('\n')
    new_records = dict([(a,"") for a in l])
    
    # Data-group examples:
    # data-group type: string
    # new_records = { "www.example.eu": "1.1.1.1",
    #                 "www.example.lt": "1.1.1.2",
    #               }
    # data-group type: ip
    # new_records = { "1.1.1.1": "aaa",
    #                 "2.2.2.2": "bbb",
    #               }
    # data-group type: integer
    # new_records = { "0": "aaa",
    #                 "1": "bbb",
    #               }

    cgp = CGP(BIGIP_ADDRESS, BIGIP_USER, BIGIP_PASS)
    # Create data-group
    if ACTION == 'create':
        cgp.create_data_group(DATA_GROUP, DG_TYPE, new_records)
        sys.exit(0)
    
    # Get current data-group configuration from device
    dg_type,records = cgp.get_data_group(DATA_GROUP)
    if dg_type != DG_TYPE:
        print("error: datagroup type %s does not match actual type %s" %(args.dg_type,dg_type))
        sys.exit(1)

    if ACTION == 'update':
        for k,v in new_records.items():
            if k not in records:
                print ('New record in %s: %s' %(DATA_GROUP, k))
        for k,v in records.items():
            if k not in new_records:
                print ('Removing record from %s: %s' %(DATA_GROUP, k)) 
        cgp.set_data_group(DATA_GROUP, DG_TYPE, new_records)
        sys.exit(0)
    
    if ACTION == 'compare':
        for k,v in new_records.items():
            if k not in records:
                print ('Source data has new record: %s' %(k))
        for k,v in records.items():
            if k not in new_records:
                print ('Data-group record no present in source: %s' %(k))
        sys.exit(0)

    print('No action taken')
