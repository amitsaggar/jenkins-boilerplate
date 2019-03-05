# Jenkins Templates for AWS CloudFormation

Find the documentation here: https://templates.cloudonaut.io/en/stable/jenkins/

## Developer notes

### RegionMap
To update the region map execute the following lines in your terminal:

```
$ regions=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)
$ for region in $regions; do ami=$(aws --region $region ec2 describe-images --filters "Name=name,Values=amzn2-ami-hvm-2.0.20190115-x86_64-gp2" --query "Images[0].ImageId" --output "text"); printf "'$region':\n  AMI: '$ami'\n"; done
```

### Packer - AMI Builder (EBS backed)

The amazon-ebs Packer builder is able to create Amazon AMIs backed by EBS volumes for use in EC2. For more information on the difference between EBS-backed instances and instance-store backed instances, see the "storage for the root device" section in the EC2 documentation. [Packer](https://www.packer.io/docs/builders/amazon-ebs.html)

