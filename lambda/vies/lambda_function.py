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
URL = os.environ['URL']
TYPE = os.environ['TYPE']

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLENAME)

validationresult = {
    "key1": None,
    "key2": None,
    "ownvat": None,
    "foreignvat": None,
    "validationtype": TYPE,
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

HEADERS= {
    'Content-Type': 'text/xml; charset=utf-8'
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

def lambda_handler(event, context): #NOSONAR

    print(event)
    requestfields = event
    # read the values from the payload

    # check, if there is valid history of the vat

    payload = f"""<Envelope xmlns=\"http://schemas.xmlsoap.org/soap/envelope/\">
                <Body xmlns=\"http://schemas.xmlsoap.org/soap/envelope/\">
                  <checkVatApprox xmlns=\"urn:ec.europa.eu:taxud:vies:services:checkVat:types\">
                     <countryCode>{requestfields['foreignvat'][:2]}</countryCode>
                     <vatNumber>{requestfields['foreignvat'][2:]}</vatNumber>
                     <requesterCountryCode>{requestfields['ownvat'][:2]}</requesterCountryCode>
                     <requesterVatNumber>{requestfields['ownvat'][2:]}</requesterVatNumber>
                  </checkVatApprox>
                </Body>
               </Envelope>"""
    
    try:
        resp = http.request("POST", URL, headers=HEADERS, body=payload)

        # example response:
        # <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Header/><env:Body><ns2:checkVatApproxResponse xmlns:ns2="urn:ec.europa.eu:taxud:vies:services:checkVat:types"><ns2:countryCode>IT</ns2:countryCode><ns2:vatNumber>01739710307</ns2:vatNumber><ns2:requestDate>2024-02-09+01:00</ns2:requestDate><ns2:valid>false</ns2:valid><ns2:traderName></ns2:traderName><ns2:traderCompanyType>---</ns2:traderCompanyType><ns2:traderAddress></ns2:traderAddress><ns2:requestIdentifier></ns2:requestIdentifier></ns2:checkVatApproxResponse></env:Body></env:Envelope>'
        dom = minidom.parseString(resp.data)
        node = dom.documentElement

        result = {}
        try:
            result['traderName'] = node.getElementsByTagName('ns2:traderName')[0].childNodes[0].nodeValue
        except KeyError as e:
            result['traderName'] = None
        try:
            result['traderAddress'] = node.getElementsByTagName('ns2:traderAddress')[0].childNodes[0].nodeValue
        except KeyError as e:
            result['traderAddress'] = None
        try:
            result['valid'] = node.getElementsByTagName('ns2:valid')[0].childNodes[0].nodeValue
        except KeyError as e:
            result['valid'] = None
        try:
            result['requestDate'] = node.getElementsByTagName('ns2:requestDate')[0].childNodes[0].nodeValue
        except KeyError as e:
            result['requestDate'] = None

        # bring result in right format
        validationresult = {
            'key1': '',
            'key2': '',
            'ownvat': requestfields['ownvat'],
            'foreignvat': requestfields['foreignvat'],
            'type': TYPE,
            'valid': result['valid'] == "true",
            'errorcode': '',
            'errorcode_description': '',
            'valid_from': '',
            'valid_to': '',
            'errorcode_hint': '',
            'timestamp': result['requestDate'],
            'company': result['traderName'],
            'address': result['traderAddress'],
            'town': '',
            'zip': '',
            'street': ''
        }
        return validationresult
    except Exception as e:
        return {'vatError': 'VAT1500', 'vatErrorMessage': repr(e)}