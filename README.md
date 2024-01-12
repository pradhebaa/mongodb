# Mongodb
Install MongoDB cluster and setup replication while the instances are booting

## Packer
Packer installs mongo binaries and necessary configuration. At this stage, MongoDB is installed without enabling authentication. 

## Terraform 
Terraform scripts are used to bring up the AWS resources. Following values has to be changed in order to execute the script

| Variable | Type | Comment |
|:----------------------------------|:--------------|:----------------------------|
|`dbAdminUser`                     | String        | admin mongo user             |
|`dbAdminUserPass`                 | String        | admin mongo user password    |
|`mongodbExporterUser`             | String        | mongoexporter user           |
|`mongodbExporterUserPass`         | String        | mongoexporter user password  |
|`kubernetes_cluster`              | String        | Kubernetes cluster name      |
|`keyname`                         | String        | Existing key name to be used |  
|`region`                          | String        | Region to deploy             |  
|`dns_zone`                        | String        | DNS zone name                |

   
## Notes
 - Backend configuration should be updated with right S3 bucket name and terraform state file
 - This code assumes AWS EC2 key pairs are already created 

## Backups
In order to ensure the consistency of the data while taking backup, one of the mongo node, preferably a secondary node should be locked against writes and the ebs backup should be taken. In order to do that a lambda function is fired at specific time using cloudwatch events and ebs snapshots are taken and then the secondary node is unlocked. 
During every stage of the backup process, a slack notification is sent to a slack channel. The deployment package required by the lambda function is stored in a S3 bucket. 
