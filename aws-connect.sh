#!/bin/bash


echo
echo
echo $0: info: getting running instances
echo time aws ec2 describe-instances --filters \'Name=instance-state-name,Values=running\'
json="$(time aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running')"
ids=($(echo "$json" | jq -r '.Reservations | .[] | .Instances | .[] | .InstanceId'))
echo
echo
printf '%s\t%s\t\t\t%s\t\t%s\t\t%s\n' index 'aws id' type state image
for i in ${!ids[@]}; do
  printf '%s\t%s\t%s\t%s\t\t%s\n' $(expr $i + 1) ${ids[$i]} $(echo "$json" | jq -rc '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .InstanceType, .State.Name, .ImageId')
done

echo
echo
echo -n enter index to connect to via ssh [1]:\ 
read number
[ "$number" == '' ] && number=1
index=$(expr $number - 1)

echo
echo
echo $0: info: adding ssh host keys for index $number with aws id ${ids[$index]} to ~/.ssh/known_hosts if not already present
ssh_host_key="$(ssh-keyscan $(aws ec2 describe-instances --instance-ids ${ids[$index]} | jq -r '.Reservations | .[] | .Instances | .[] | .PublicDnsName'))"
grep "$ssh_host_key" ~/.ssh/known_hosts || echo "$ssh_host_key" | tee -a ~/.ssh/known_hosts

echo
echo
echo $0: info: determining username for index $number with aws id ${ids[$index]}
json=$(aws ec2 describe-images --image-ids $(aws ec2 describe-instances --instance-ids ${ids[$index]} | jq -r '.Reservations | .[] | .Instances | .[] | .ImageId'))
description=$(echo "$json" | jq -r '.Images | .[] | .Description')
echo $0: info: image description: $description
shopt -s nocasematch
case $description in
  *amazon*) ssh_user='ec2-user';;
  *centos*) ssh_user='centos';;
  *) echo $0: fatal: unknown operating system, can not determine username; exit 1;;
esac
echo $0: info: username: $ssh_user

echo
echo
echo $0: info: connecting to index $number with aws id ${ids[$index]} via ssh
echo ssh -i ~/.ssh/my-west-keypair.pem $ssh_user@\"$\(aws ec2 describe-instances --instance-ids ${ids[$index]} \| jq -r \'.Reservations \| .[] \| .Instances \| .[] \| .PublicDnsName\'\)\"
echo
echo
ssh -i ~/.ssh/my-west-keypair.pem $ssh_user@"$(aws ec2 describe-instances --instance-ids ${ids[$index]} | jq -r '.Reservations | .[] | .Instances | .[] | .PublicDnsName')"
