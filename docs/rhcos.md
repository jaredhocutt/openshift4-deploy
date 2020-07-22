# Red Hat CoreOS (RHCOS)

Red Hat CoreOS is the operating system for the nodes that make up the OpenShift
cluster.

## RHCOS AMI

Due to current imitations in non-commercial regions of AWS, the RHCOS image is
not available and will need to be imported.

### Importing RHCOS AMI

**Step 1**

Ensure that your AWS account has an S3 bucket created and the required IAM
service role defined.

https://docs.aws.amazon.com/vm-import/latest/userguide/vmie_prereqs.html#vmimport-role

**Step 2**

Export your AWS credentials and the region to use.

If you already have a profile setup using the
`awscli`, you can export `AWS_PROFILE`.

```bash
export AWS_PROFILE=govcloud
export AWS_DEFAULT_REGION=us-gov-east-1
```

Otherwise, export `AWS_ACCESS_KEY_ID`
and `AWS_SECRET_ACCESS_KEY`.

```bash
export AWS_ACCESS_KEY_ID=access_key
export AWS_SECRET_ACCESS_KEY=secret=key
export AWS_DEFAULT_REGION=us-gov-east-1
```

**Step 3**

Download the AWS VMDK disk image, unarchive it, and upload it to S3.

Download the highest version that is less than or equal to the OpenShift
version you are installing. For example, if you are installing OpenShift
`4.5.4` and the latest RHCOS available is `4.5.2`, then use RHCOS `4.5.2`.

The RHCOS images can be found:
http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/

Export the version of RHCOS you want to use.

```bash
export RHCOS_VERSION=4.5.2
export VMIMPORT_BUCKET_NAME=name-of-your-bucket
```

You want to find the RHCOS image with `aws` in the name.

```bash
wget http://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/`echo ${RHCOS_VERSION} | awk '{split($0,a,"."); print a[1]"."a[2]}'`/${RHCOS_VERSION}/rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64.vmdk.gz

gunzip rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64.vmdk.gz

aws s3 cp rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64.vmdk s3://${VMIMPORT_BUCKET_NAME}
```

**Step 4**

Create the disk containers file `containers.json`.

Be sure to replace the values for `S3Bucket` to match your bucket name and
`S3Key` to match the name of the file you ended up with after unarchiving the
RHCOS image.

```bash
cat <<EOF > containers.json
{
   "Description": "rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64",
   "Format": "vmdk",
   "UserBucket": {
      "S3Bucket": "${VMIMPORT_BUCKET_NAME}",
      "S3Key": "rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64.vmdk"
   }
}
EOF
```

**Step 5**

Import the disk as a snapshot into AWS.

```bash
aws ec2 import-snapshot \
   --region ${AWS_DEFAULT_REGION} \
   --description "rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64" \
   --disk-container file://containers.json
```

**Step 6**

Check the status of the image import:

```bash
watch -n 5 aws ec2 describe-import-snapshot-tasks --region ${AWS_DEFAULT_REGION}
```

After the import is complete, you should see similar output to below.

```json
{
    "ImportSnapshotTasks": [
        {
            "Description": "rhcos-4.5.2-x86_64-aws.x86_64",
            "ImportTaskId": "import-snap-fh6i8uil",
            "SnapshotTaskDetail": {
                "Description": "rhcos-4.5.2-x86_64-aws.x86_64",
                "DiskImageSize": 819056640.0,
                "Format": "VMDK",
                "SnapshotId": "snap-06331325870076318",
                "Status": "completed",
                "UserBucket": {
                    "S3Bucket": "name-of-your-bucket",
                    "S3Key": "rhcos-4.5.2-x86_64-aws.x86_64.vmdk"
                }
            }
        }
    ]
}
```

**Step 7**

Register an image using the snapshot.

Be sure to replace the `SnapshotId` using the value from the output you got
when checking the snapshot task.

```bash
aws ec2 register-image \
   --region ${AWS_DEFAULT_REGION} \
   --architecture x86_64 \
   --description "rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64" \
   --ena-support \
   --name "rhcos-${RHCOS_VERSION}-x86_64-aws.x86_64" \
   --virtualization-type hvm \
   --root-device-name '/dev/xvda' \
   --block-device-mappings 'DeviceName=/dev/xvda,Ebs={DeleteOnTermination=true,SnapshotId=REPLACE_ME}'
```
