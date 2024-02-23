import boto3
from boto3.dynamodb.conditions import Attr
import json
import datetime
from decimal import Decimal
import os
import urllib3
from xml.dom import minidom
import json

http = urllib3.PoolManager()

TABLENAME=os.environ['DYNAMODB']
TABLENAME_CODES=os.environ['DYNAMODB_CODES']
URL = os.environ['URL']
TYPE = os.environ['TYPE']

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLENAME)
codes = dynamodb.Table(TABLENAME_CODES)

validationresult = {
    "key1": None,
    "key2": None,
    "ownvat": None,
    "foreignvat": None,
    "type": TYPE,
    "valid": None,
    "errorcode": None,
    "errorcode_description": None,
    "valid_from": None,
    "valid_to": None,
    "errorcode_hint": None,
    "timestamp": None,
    "company": None,
    "address": None,
    "town": None,
    "zip": None,
    "street": None
}

class fakefloat(float):
    def __init__(self, value):
        self._value = value
    def __repr__(self):
        return str(self._value)

def defaultencode(o):
    if isinstance(o, Decimal):
        # Subclass float with custom repr?
        return fakefloat(o)
    if isinstance(o, (datetime.datetime, datetime.date)):
        return o.isoformat()
    raise TypeError(repr(o) + " is not JSON serializable")


def load_codes(lang, errorcode):
    if errorcode is None:
        return None

    response = codes.get_item(Key={
        'status': errorcode
        })
    
    if 'Item' in response:
        if 'de' in response['Item'] and lang == 'de':
            return response['Item']['de']
        if 'en' in response['Item'] and lang == 'en':
            return response['Item']['en']
        
    return None


def lambda_handler(event, context): #NOSONAR

    print(event)
    requestfields = event
    # read the values from the payload

    # check, if there is valid history of the vat

    try:
        resp = http.request("GET", URL + requestfields['foreignvat'][2:])
        print(resp.status, resp.data)
        result = json.loads(resp.data)
        # example response:
        # {"target":{"name":"DEUTSCHE BANK AG LONDON","vatNumber":"243609761","address":{"line1":"21 MOORFIELDS","line2":"LONDON","postcode":"EC2Y 9DB","countryCode":"GB"}},"processingDate":"2024-02-09T20:30:07+00:00"}'
        # bring result in right format

        result['errorcode'] = None

        validationresult = {
            'key1': '',
            'key2': '',
            'ownvat': requestfields['ownvat'],
            'foreignvat': requestfields['foreignvat'],
            'type': TYPE,
            'valid': resp.status == 200,
            'errorcode': result['errorcode'],
            'errorcode_description': load_codes(requestfields['lang'], result['errorcode']),
            'valid_from': '',
            'valid_to': '',
            'timestamp': result['processingDate'],
            'company': result['target']['name'],
            'address': result['target']['address']['line1'] + chr(13) + result['target']['address']['line2'],
            'town': '',
            'zip':  result['target']['address']['postcode'],
            'street': ''
        }
        # store result back in DynamoDB
        return validationresult
    except Exception as e:
        return {'vatError': 'VAT2500', 'vatErrorMessage': repr(e)}
