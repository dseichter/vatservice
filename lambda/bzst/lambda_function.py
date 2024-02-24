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


def gettext(nodelist):
    rc = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
    return ''.join(rc)


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


def save_validation(result):
    today = datetime.date.today()
    try:
       print('before db')
       response = table.update_item(
            Key={"vat": result['foreignvat'], "date": today.strftime("%Y-%m-%d") + "|" + result['type']},
                    UpdateExpression="set validationtimestamp=:validationtimestamp, checktype=:checktype, valid=:valid, errorcode=:errorcode,valid_from=:valid_from, valid_to=:valid_to, company=:company, address=:address,town=:town, zip=:zip, street=:street ",
                    ExpressionAttributeValues={":validationtimestamp": result['timestamp'],
                                            ":checktype": result['type'],
                                            ":valid": result['valid'],
                                            ":errorcode": result['errorcode'],
                                            ":valid_from": result['valid_from'],
                                            ":valid_to": result['valid_to'],
                                            ":company": result['company'],
                                            ":address": result['address'],
                                            ":town": result['town'],
                                            ":zip":  result['zip'],
                                            ":street": result['street']
                                            },
                    ReturnValues="UPDATED_NEW", 
            )
       print('after db')
    except Exception as e:
            print(repr(e))
            return False
    
    return True


def lambda_handler(event, context): #NOSONAR

    print(event)
    requestfields = event
    # read the values from the payload

    # map requested fields to bzst request
    bzstmap = {
        'UstId_1': requestfields['ownvat'],
        'UstId_2':requestfields['foreignvat'],
        'Firmenname':requestfields['company'],
        'Ort':requestfields['town'],
        'PLZ':requestfields['zip'],
        'Strasse':requestfields['street']
    }
    # check, if there is valid history of the vat

    try:
        resp = http.request("GET", URL, fields=bzstmap)

        dom = minidom.parseString(resp.data)

        params = dom.childNodes

        rc = {}
        for param in params:
            arrays=param.getElementsByTagName("array")
            iskey=True
            for array in arrays:
                values=array.getElementsByTagName("value")
                for value in values:
                    strings=value.getElementsByTagName("string")
                    if iskey:
                        iskey=False
                        for string in strings:
                            newkey=gettext(string.childNodes)
                    else:
                        iskey=True
                        for string in strings:
                            newvalue=gettext(string.childNodes)
                            rc[newkey]= newvalue

        validationresult = {
            'key1': requestfields['key1'],
            'key2': requestfields['key2'],
            'ownvat': requestfields['ownvat'],
            'foreignvat': requestfields['foreignvat'],
            'type': TYPE,
            'valid': rc['ErrorCode'] in ['200', '216'],
            'errorcode': rc['ErrorCode'],
            'errorcode_description': load_codes(requestfields['lang'], rc['ErrorCode']),
            'valid_from': rc['Gueltig_ab'],
            'valid_to': rc['Gueltig_bis'],
            'timestamp': datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%S"),
            'company': rc['Firmenname'],
            'address': '',
            'town': rc['Ort'],
            'zip':  rc['PLZ'],
            'street': rc['Strasse']
        }

        # save only, if response itself is valid
        if resp.status == 200:
            save_validation(validationresult)

        return validationresult
    except Exception as e:
        return {'vatError': 'VAT3500', 'vatErrorMessage': repr(e)}