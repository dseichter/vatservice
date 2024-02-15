import boto3
from boto3.dynamodb.conditions import Attr
import json
from datetime import date
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
        result = {
            'status': 'ok' if response['status'] == 'SUCCEEDED' else 'error',
            'data': json.loads(response['output'])
        }
        return {
            'statusCode': 200 if result['status'] == 'ok' else 400,
            'body': json.dumps(result['data'], default=defaultencode)
        }
    except Exception as e:
        print(repr(e))
        return {
            'statusCode': 500,
            'body': json.dumps({'status': 'error', 'message': repr(e)}, default=defaultencode)
        }