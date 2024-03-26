# VATService

Service to validate VAT numbers against BZSt, VIES or HMRC.

## Badges

![pep8](https://github.com/dseichter/vatservice/actions/workflows/pep8.yml/badge.svg)
![tflint](https://github.com/dseichter/vatservice/actions/workflows/tflint.yml/badge.svg)
![tfsec](https://github.com/dseichter/vatservice/actions/workflows/trivy.yml/badge.svg)


### Prerequisites

* AWS Account to deploy the complete infrastructure
* Python
* terraform

optional: you own a VAT number to be able to perform requests

## Contributing

Please read [CONTRIBUTING](/CONTRIBUTING.md) and also [CODE_OF_CONDUCT](/CODE_OF_CONDUCT.md). All contributions are welcome.


## Short overview

Instead of performing a request to different services with different formats, VATService provides a common interface. This makes an integration into applications easier.

![architecture](/docu/vatservice.png)

### How it works

If you perform a request to the API Gateway, the first Lambda function is getting invoked. This will precheck the received data. If everything is fine, the Step Function will be triggered synchronous. 
The Step Function will decide, if
* your VAT id starts with GB, the HMRC Lambda will be triggered (all others will fail after the Brexit).
* your own VAT starts with DE, you will be able to use the BZSt interface. Otherwise your request will be performed by using the VIES interface.

You can overwrite this behaviour by specifying the type in the payload.

Every response will be stored in the DynamoDB to keep the original response of the interfaces. This enables you to be able to have the evidence in case of an audit.

### Interfaces

* BZSt: [https://evatr.bff-online.de/evatrRPC](https://evatr.bff-online.de/evatrRPC)
* HMRC: [https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/](https://api.service.hmrc.gov.uk/organisations/vat/check-vat-number/lookup/)
* VIES: [https://ec.europa.eu/taxation_customs/vies/services/checkVatService](https://ec.europa.eu/taxation_customs/vies/services/checkVatService)

### References to the used services on AWS

The main components used by VATService:

* [AWS Lambda](https://aws.amazon.com/lambda)
* [AWS Step Functions](https://aws.amazon.com/step-functions/)
* [Amazon DynamoDB](https://aws.amazon.com/dynamodb/)
* [Amazon API Gateway](https://aws.amazon.com/api-gateway)

And a lot more :)