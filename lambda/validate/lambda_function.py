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

def lambda_handler(event, context):
    
    # example
    input_dict = {'key': 'value', 'vat': 'DE1234567890'}
    # read the values from the payload

    # check, if request is valid
    
    
    # trigger stepfunction
    try:
        response = sf.start_execution(
            stateMachineArn = STEPFUNCTION,
            input = json.dumps(input_dict)
        )
    except Exception as e:
        print(repr(e))

    return {
            'statusCode': 200,
            'body': json.dumps({'status': 'ok', 'data': 'test'}, default=defaultencode)
        }