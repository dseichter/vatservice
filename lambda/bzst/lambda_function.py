import boto3
import datetime
import os
import urllib3
from xml.dom import minidom
import logging

logger = logging.getLogger()
http = urllib3.PoolManager()

TABLENAME = os.environ['DYNAMODB']
TABLENAME_CODES = os.environ['DYNAMODB_CODES']
URL = os.environ['URL']
TYPE = os.environ['TYPE']

# get loglevel from environment
if 'LOGLEVEL' in os.environ:
    loglevel = os.environ['LOGLEVEL']
    if loglevel == 'DEBUG':
        logger.setLevel(logging.DEBUG)
    if loglevel == 'INFO':
        logger.setLevel(logging.INFO)
    if loglevel == 'ERROR':
        logger.setLevel(logging.ERROR)

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


def save_validation(result, rawdata=None):
    today = datetime.date.today()
    try:
        logger.debug('before db')
        response = table.update_item(
            Key={"vat": result['foreignvat'], "date": today.strftime("%Y-%m-%d") + "|" + result['type']},
            UpdateExpression="""
            set validationtimestamp=:validationtimestamp,
                checktype=:checktype,
                valid=:valid,
                errorcode=:errorcode,
                valid_from=:valid_from,
                valid_to=:valid_to,
                company=:company,
                address=:address,
                town=:town,
                zip=:zip,
                street=:street,
                rawdata=:rawdata
            """,
            ExpressionAttributeValues={":validationtimestamp": result['timestamp'],
                                       ":checktype": result['type'],
                                       ":valid": result['valid'],
                                       ":errorcode": result['errorcode'],
                                       ":valid_from": result['valid_from'],
                                       ":valid_to": result['valid_to'],
                                       ":company": result['company'],
                                       ":address": result['address'],
                                       ":town": result['town'],
                                       ":zip": result['zip'],
                                       ":street": result['street'],
                                       ":rawdata": rawdata
                                       },
            ReturnValues="UPDATED_NEW",
        )
        logger.debug('after db')
    except Exception as e:
        logger.error(repr(e))
        return False

    return True


def lambda_handler(event, context):  # NOSONAR

    logger.debug(event)
    requestfields = event
    # read the values from the payload

    # map requested fields to bzst request
    bzstmap = {
        'UstId_1': requestfields['ownvat'],
        'UstId_2': requestfields['foreignvat'],
        'Firmenname': requestfields['company'],
        'Ort': requestfields['town'],
        'PLZ': requestfields['zip'],
        'Strasse': requestfields['street']
    }
    # check, if there is valid history of the vat

    try:
        resp = http.request("GET", URL, fields=bzstmap)

        dom = minidom.parseString(resp.data)

        params = dom.childNodes

        rc = {}
        for param in params:
            arrays = param.getElementsByTagName("array")
            iskey = True
            for array in arrays:
                values = array.getElementsByTagName("value")
                for value in values:
                    strings = value.getElementsByTagName("string")
                    if iskey:
                        iskey = False
                        for string in strings:
                            newkey = gettext(string.childNodes)
                    else:
                        iskey = True
                        for string in strings:
                            newvalue = gettext(string.childNodes)
                            rc[newkey] = newvalue

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
            'zip': rc['PLZ'],
            'street': rc['Strasse']
        }

        # save only, if response itself is valid
        if resp.status == 200:
            save_validation(validationresult, rawdata=resp.data.decode('utf-8'))

        return validationresult
    except Exception as e:
        logger.error(repr(e))
        return {'vatError': 'VAT3500', 'vatErrorMessage': repr(e)}
