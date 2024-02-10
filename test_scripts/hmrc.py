url = 'https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/'

# example: without GB
# https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/1234567890

import urllib3
from xml.dom import minidom
import json

http = urllib3.PoolManager()

URL = 'https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/'
TYPE='HMRC'
OWNVAT=''
FOREIGNVAT='GB243609761'
COMPANY='Übungsfirma'
TOWN=''
ZIP=''
STREET=''

try:
    resp = http.request("GET", URL + FOREIGNVAT[2:])
    print(resp.status, resp.data)
    result = json.loads(resp.data)
    # example response:
    # {"target":{"name":"DEUTSCHE BANK AG LONDON","vatNumber":"243609761","address":{"line1":"21 MOORFIELDS","line2":"LONDON","postcode":"EC2Y 9DB","countryCode":"GB"}},"processingDate":"2024-02-09T20:30:07+00:00"}'
    # bring result in right format
    validationresult = {
        'key1': '',
        'key2': '',
        'ownvat': OWNVAT,
        'foreignvat': FOREIGNVAT,
        'type': TYPE,
        'valid': resp.status == '200',
        'errorcode': '',
        'errorcode_description': '',
        'valid_from': '',
        'valid_to': '',
        'errorcode_hint': '',
        'timestamp': result['processingDate'],
        'company': result['target']['name'],
        'address': result['target']['address']['line1'] + chr(13) + result['target']['address']['line2'],
        'town': '',
        'zip':  result['target']['address']['postcode'],
        'street': ''
    }

    print(json.dumps(validationresult, indent=2))
except Exception as e:
    print(repr(e))
