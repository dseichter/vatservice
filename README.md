# VATService

Service to validate VAT numbers against BZSt, VIES or HMRC.

## Badges

![pep8](https://github.com/dseichter/vatservice/actions/workflows/pep8/badge.svg)
![tflint](https://github.com/dseichter/vatservice/actions/workflows/tflint/badge.svg)
![tfsec](https://github.com/dseichter/vatservice/actions/workflows/tfsec/badge.svg)


### Prerequisites

* AWS Account to deploy the complete infrastructure
* Python
* terraform

optional: you own a VAT number to be able to perform requests

## Contributing

Please read [CONTRIBUTING](/CONTRIBUTING.md) and also [CODE_OF_CONDUCT](/CODE_OF_CONDUCT.md), and the process for submitting pull requests to us.


## Short overview

Instead of performing a request to different locations, you just have on common interface. This make an integration into application easier.

![architecture](/docu/vatservice.png)

### How it works

If you perform a request to the API Gateway, the first Lambda function is getting invoked. This will precheck the send data. If everything is fine, the Step Function will be triggered synchronous. 
If your VAT id starts with GB, the HMRC Lambda will be triggered (all others will fail after the Brexit).
If your own VAT starts with DE, you will be able to use the BZSt interface. Otherwise your request will be performed by using the VIES interface.
You can overwrite this behaviour by specifying the type.

Every response will be stored in the DynamoDB to keep the original response of the interfaces. This enables you to be able to have the evidence in case of an audit.


### Interfaces

* BZSt: [https://evatr.bff-online.de/evatrRPC](https://evatr.bff-online.de/evatrRPC)
* HMRC: [https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/](https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/)
* VIES: [https://ec.europa.eu/taxation_customs/vies/services/checkVatService](https://ec.europa.eu/taxation_customs/vies/services/checkVatService)