import boto3
from boto3.dynamodb.conditions import Attr
import json
import datetime
from decimal import Decimal
import os

STEPFUNCTION=os.environ['STEPFUNCTION']

sf = boto3.client('stepfunctions', region_name = 'eu-central-1')

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

def return_fielderror(fieldname):
    return {
            'statusCode': 406,
            'body': json.dumps({'errorcode': 'VAT0001', 'message': f"The following field is missing: {fieldname}"}, default=defaultencode)
        }

def lambda_handler(event, context):
    
    print(event)
    payload = json.loads(event['body'])

    if not 'key1' in payload:
        return return_fielderror('key1')
    if not 'key2' in payload:
        return return_fielderror('key2')
    if not 'ownvat' in payload:
        return return_fielderror('ownvat')
    if not 'foreignvat' in payload:
        return return_fielderror('foreignvat')
    if not 'company' in payload:
        return return_fielderror('company')
    if not 'town' in payload:
        return return_fielderror('town')
    if not 'zip' in payload:
        return return_fielderror('zip')
    if not 'street' in payload:
        return return_fielderror('street')
    
    if not 'type' in payload:
        payload['type'] = 'bzst' if payload['ownvat'].upper()[:2] == 'DE' else 'vies'

    # trigger stepfunction
    try:
        response = sf.start_sync_execution(
            stateMachineArn = STEPFUNCTION,
            name=payload['foreignvat'],
            input = json.dumps(payload)
        )
        print(response)
        if response['status'] == 'SUCCEEDED' and 'output' in response:
            result = json.loads(response['output'])
            if 'vatError' not in result:
                return {
                    'statusCode': 200,
                    'body': response['output']
                }
            else:
                return {
                    'statusCode': 500,
                    'body': response['output']
                } 
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'errorcode':'EW400', 'errormessage': response})
            }
    except Exception as e:
        print(repr(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'errorcode':'EW500', 'errormessage': repr(e)}, default=defaultencode)
        }