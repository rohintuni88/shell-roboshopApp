#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z079173622ZFKOVAG4QDL"
DOMAIN_NAME="rtdevops.online"

for instance in $@
do
echo "Launching Instance $instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-0220d79f3f480ecf5 \
    --instance-type t3.micro \
    --security-groups "myipv4" "robo-$instance" \
    --tag-specifications \
        "ResourceType=instance,Tags=[{Key=Name,Value=robo-$instance}]" \
         --query 'Instances[0].InstanceId' \
    --output text
)

echo "INSTANCE_ID: $INSTANCE_ID"
aws ec2 describe-instance --instance-ids $INSTANCE_ID
if [ $instnace == "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --output text)
    R53_RECORD="$DOMAIN_NAME"
 else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query 'Reservations[*].Instances[*].PrivateIpAddress' \
    --output text)
    R53_RECORD="$instance.$DOMAIN_NAME"
fi

aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch '
        \"Comment\": \"Updating the A record for the main website\",
        \"Changes\": [
            {
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$R53_RECORD\",
                    \"Type\": \"A\",
                    \"TTL\": 1,
                    \"ResourceRecords\": [
                        {
                            \"Value\": \"$IP\"
                        }
                    ]
                }
            }
        ]
    '

done