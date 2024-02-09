url = 'https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/'

# example: without GB
# https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/1234567890

import urllib3
from xml.dom import minidom
import json

http = urllib3.PoolManager()

URL = 'https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/'
OWNVAT=''
FOREIGNVAT='GB243609761'
COMPANY='Übungsfirma'
TOWN=''
ZIP=''
STREET=''

try:
    resp = http.request("GET", URL + FOREIGNVAT[2:])
    print(resp.status, resp.data)

    # example response:
    # {"target":{"name":"DEUTSCHE BANK AG LONDON","vatNumber":"243609761","address":{"line1":"21 MOORFIELDS","line2":"LONDON","postcode":"EC2Y 9DB","countryCode":"GB"}},"processingDate":"2024-02-09T20:30:07+00:00"}'

except Exception as e:
    print(repr(e))
