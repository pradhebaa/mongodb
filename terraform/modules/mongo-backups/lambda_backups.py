import time
import boto3
import botocore
from pymongo import MongoClient
from pymongo.errors import OperationFailure, ServerSelectionTimeoutError
import json
import requests
import datetime
import dateutil.tz
import os

pacific = dateutil.tz.gettz(os.environ['timezone'])


def isPrimary(client):
    isMasterJson = client.admin.command('ismaster')
    if not isMasterJson['ismaster'] and isMasterJson['secondary']:
        return 0
    else:
        return 1


def isLocked(client):
    lockCheck = client.admin.command('currentOp')
    if 'fsyncLock' in lockCheck and lockCheck['fsyncLock']:
        return 1
    else:
        return 0

def unLock(client):
    unlock = client.admin.command("fsyncUnlock")
    if unlock['ok'] == 1.0:
        print("Database has been unlocked")
    else:
        print("Aborting snapshot creation. Error in unlocking database.")
        notifySlack(
            text="Scheduled mongodb backup creation is not complete. Unable to unlock Mongodb")


def takeSnapshot(host, client):
    # Get instance id based on the name tag and create a snapshot for data and journal volume
    ec2 = boto3.client('ec2', region_name=os.environ['region'])
    hostname = host.split(".%s" % os.environ['env'])[0]
    instanceId = ec2.describe_instances(
        Filters=[
            {'Name': 'tag:Name', 'Values': [hostname]},
        ])
    if instanceId['Reservations']:
        for r in instanceId['Reservations']:
            for i in r['Instances']:
                for b in i['BlockDeviceMappings']:
                    if b['DeviceName'] == '/dev/sdf' or b['DeviceName'] == '/dev/sdg':
                        deviceName = 'data' if b['DeviceName'] == '/dev/sdf' else 'journal'
                        volumeId = b['Ebs']['VolumeId']
                        try:
                            snapshot = ec2.create_snapshot(
                                VolumeId=volumeId,
                                Description="Lambda backup for ebs %s" % volumeId,
                                TagSpecifications=[{
                                    'ResourceType': 'snapshot',
                                    'Tags': [{
                                        'Key': 'Name',
                                        'Value': 'Mongo Snapshot for %s-%s' % (deviceName, datetime.datetime.now(tz=pacific))
                                    }]
                                }]
                            )
                            # Use boto3 waiter to check if the snapshot has been created
                            snapshot_waiter = ec2.get_waiter('snapshot_completed')
                            snapshot_waiter.wait(SnapshotIds=[snapshot["SnapshotId"]])
                            print('Snapshot has been created successfully with %s for %s' % (snapshot["SnapshotId"], volumeId))
                            notifySlack(text='Snapshot has been created successfully with %s for %s' % (snapshot["SnapshotId"], volumeId))
                        except botocore.exceptions.WaiterError as e:
                            if "Max attempts exceeded" in e.message:
                                print("Snapshot did not create after waiting for 600 seconds")
                                notifySlack(text="Mongodb snapshot creation failed")
                            else:
                                print(e.message)
                                notifySlack(text="Mongodb snapshot creation failed")
                            # Unlock database if snapshot creation fails
                            unLock(client)
    else:
        print("Aborting mongodb snapshot creation. Error finding instance with tag name %s" % hostname)
        notifySlack(text="Aborting mongodb snapshot creation. Error finding instance with tag name %s" % hostname)
        return 0


def notifySlack(text):
    slack_data = {'text': "%s %s" % (datetime.datetime.now(tz=pacific), text),
                  'username': 'Mongo alerts for backups'}

    response = requests.post(
        os.environ['webhookurl'], data=json.dumps(slack_data),
        headers={'Content-Type': 'application/json'}
    )
    print('Sending error message to slack channel. Slack response code: %s' % str(response.status_code))

    if response.status_code != 200:
        raise ValueError(
            'Request to slack returned an error %s, the response is:\n%s'
            % (response.status_code, response.text)
        )

def lambda_handler(event, context):
    notifySlack(text="Mongodb snapshot creation started")
    for host in os.environ['hostnames'].split(" "):
        client = MongoClient(host, username=os.environ['adminusername'], password=os.environ['adminpassword'])
        try:
          client.server_info()
        except (OperationFailure, ServerSelectionTimeoutError) as e:
            print(e.details)
            notifySlack(text="Not able to log into Mongo server. Auth/Network error")


        if not (isPrimary(client)):
            print("%s is a Secondary, so perform lock check" % host)
            # check if the database is already locked
            if isLocked(client):
                counter = 0
                while isLocked(client) and counter <= 4:
                    time.sleep(10)
                    counter = counter + 1
                    print("waiting for the database to unlock..Trying for the %s time" % str(counter))
                print("Aborting snapshot creation. Mongodb secondary was already locked")
                notifySlack(
                    text="Scheduled mongodb backup creation has been aborted. Mongodb secondary db %s was already locked" % host)
            else:
                print("Locking database")
                lock = client.admin.command("fsync", lock=True)
                if lock['ok'] == 1.0:
                    print("Database has been locked successfully")
                    takeSnapshot(host, client)
                    unLock(client)
                    notifySlack(text="Mongodb snapshot creation ended")
                else:
                    print("Aborting snapshot creation. Error with database locking")
                    notifySlack(
                        text="Scheduled mongodb backup creation has been aborted. Unable to lock Mongodb %s" % host)
            break
        else:
            print("%s is master. Looking for a secondary node" % host)
