import boto3
from boto3.dynamodb.conditions import Attr
import json
from datetime import date
from decimal import Decimal
import os


TABLENAME=os.environ['DYNAMODB']

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLENAME)


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

    print(event)
    # read the values from the payload

    # check, if there is valid history of the vat

    # check against BZST

    # check against VIES

    # check against HRMC

    # store result back in DynamoDB

    return {
            'statusCode': 200,
            'body': json.dumps({'status': 'ok', 'data': 'bzst'}, default=defaultencode)
        }