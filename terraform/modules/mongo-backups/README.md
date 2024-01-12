# Lambda function to create backups

## Inputs

| Variable | Type | Comment |
|:----------------------------------|:--------------|:----------------------------               |
|`adminusername`                   | String        | admin mongo user                            |
|`adminpassword`                   | String        | admin mongo user password                   |
|`env`                             | String        | environment name (dev, staging, production) |           |
|`hostnames`                       | String        | FQDN of mongo servers                       |
|`region`                          | String        | Region to deploy lambda fn                  |  
|`webhookurl`                      | String        | Webhook url of slack to send notification   |               |

## Output
To view your Lambda function's logs:
1. Open the Logs page of the CloudWatch console
2. Choose the log group for your function (/aws/lambda/function-name)
3. Choose the first stream in the list.
   
## Configuarion
Configuration of lambda function is managed using terraform code

## Notes
Sensitive variables `adminusername`,`adminpassword` and `webhookurl` required by the lambda function is proved as input using terraform environmental variables. 