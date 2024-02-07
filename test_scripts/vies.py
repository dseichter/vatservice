url = 'https://ec.europa.eu/taxation_customs/vies/services/checkVatService'

#   postbody := '<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">' + '<Body xmlns="http://schemas.xmlsoap.org/soap/envelope/">' +
#     '<checkVatApprox xmlns="urn:ec.europa.eu:taxud:vies:services:checkVat:types">' + '<countryCode>' + Copy(helper_normalizevat_request(importdata[importid].foreignvat), 0, 2) + '</countryCode>' +
#     '<vatNumber>' + Copy(helper_normalizevat_request(importdata[importid].foreignvat), 3) + '</vatNumber>' +

#     '<requesterCountryCode>' + Copy(helper_normalizevat_request(importdata[importid].ownvat), 0, 2) + '</requesterCountryCode>' + '<requesterVatNumber>' +
#     Copy(helper_normalizevat_request(importdata[importid].ownvat), 3) + '</requesterVatNumber>' + '</checkVatApprox>' + '</Body>' + '</Envelope>';