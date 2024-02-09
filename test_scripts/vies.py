url = 'https://ec.europa.eu/taxation_customs/vies/services/checkVatService'


import urllib3
from xml.dom import minidom
import json

http = urllib3.PoolManager()

URL = 'https://ec.europa.eu/taxation_customs/vies/services/checkVatService'
OWNVAT='DE323410633'
FOREIGNVAT='IT01739710307'
COMPANY=''
TOWN=''
ZIP=''
STREET=''

payload = f"""<Envelope xmlns=\"http://schemas.xmlsoap.org/soap/envelope/\">
                <Body xmlns=\"http://schemas.xmlsoap.org/soap/envelope/\">
                  <checkVatApprox xmlns=\"urn:ec.europa.eu:taxud:vies:services:checkVat:types\">
                     <countryCode>{FOREIGNVAT[:2]}</countryCode>
                     <vatNumber>{FOREIGNVAT[2:]}</vatNumber>
                     <requesterCountryCode>{OWNVAT[:2]}</requesterCountryCode>
                     <requesterVatNumber>{OWNVAT[2:]}</requesterVatNumber>
                  </checkVatApprox>
                </Body>
               </Envelope>"""

#print(payload)
headers= {
    'Content-Type': 'text/xml; charset=utf-8'
}

try:
    resp = http.request("POST", URL, headers=headers, body=payload)
    #print(resp.status, resp.data)

    # example response:
    # <env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Header/><env:Body><ns2:checkVatApproxResponse xmlns:ns2="urn:ec.europa.eu:taxud:vies:services:checkVat:types"><ns2:countryCode>IT</ns2:countryCode><ns2:vatNumber>01739710307</ns2:vatNumber><ns2:requestDate>2024-02-09+01:00</ns2:requestDate><ns2:valid>false</ns2:valid><ns2:traderName></ns2:traderName><ns2:traderCompanyType>---</ns2:traderCompanyType><ns2:traderAddress></ns2:traderAddress><ns2:requestIdentifier></ns2:requestIdentifier></ns2:checkVatApproxResponse></env:Body></env:Envelope>'
    dom = minidom.parseString(resp.data)
    node = dom.documentElement

    result = {}
    try:
        result['traderName'] = node.getElementsByTagName('ns2:traderName')[0].childNodes[0].nodeValue
    except:
        result['traderName'] = None
    try:
        result['traderAddress'] = node.getElementsByTagName('ns2:traderAddress')[0].childNodes[0].nodeValue
    except:
        result['traderAddress'] = None
    try:
        result['valid'] = node.getElementsByTagName('ns2:valid')[0].childNodes[0].nodeValue
    except:
        result['valid'] = None
    try:
        result['requestDate'] = node.getElementsByTagName('ns2:requestDate')[0].childNodes[0].nodeValue
    except:
        result['requestDate'] = None

    print(result)

    
except Exception as e:
    print(repr(e))
