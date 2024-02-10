import urllib3
from xml.dom import minidom
import json

http = urllib3.PoolManager()

URL = 'https://evatr.bff-online.de/evatrRPC'
TYPE='BZST'
OWNVAT='DE323410633'
FOREIGNVAT='ATU72811148'
COMPANY='Barbaric GmbH'
TOWN='Linz'
ZIP='4020'
STREET='Pummererstraße 12'

requestfields = {
  'UstId_1':OWNVAT,
  'UstId_2' :FOREIGNVAT,
  'Firmenname' :COMPANY,
  'Ort': TOWN,
  'PLZ' : ZIP,
  'Strasse': STREET
}

def getText(nodelist):
    rc = []
    for node in nodelist:
        if node.nodeType == node.TEXT_NODE:
            rc.append(node.data)
    return ''.join(rc)

try:
    resp = http.request("GET", URL, fields=requestfields)

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
                  newkey=getText(string.childNodes)
            else:
              iskey=True
              for string in strings:
                newvalue=getText(string.childNodes)
                rc[newkey]= newvalue
    print(json.dumps(rc, indent=2))


    validationresult = {
        'key1': '',
        'key2': '',
        'ownvat': OWNVAT,
        'foreignvat': FOREIGNVAT,
        'type': TYPE,
        'valid': rc['ErrorCode'] in ['200', '216'],
        'errorcode': rc['ErrorCode'],
        'errorcode_description': '',
        'valid_from': rc['Gueltig_ab'],
        'valid_to': rc['Gueltig_bis'],
        'errorcode_hint': '',
        'timestamp': rc['Datum'] + ' ' + rc['Uhrzeit'],
        'company': rc['Firmenname'],
        'address': '',
        'town': rc['Ort'],
        'zip':  rc['ErrorCode'],
        'street': rc['Strasse']
    }

    print(json.dumps(validationresult, indent=2))

except Exception as e:
    print(repr(e))


