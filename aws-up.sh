#!/bin/bash


echo
echo
echo $0: info: getting instances
echo time aws ec2 describe-instances
json="$(time aws ec2 describe-instances)"
ids=($(echo "$json" | jq -r '.Reservations | .[] | .Instances | .[] | .InstanceId'))
echo
echo
printf '%s\t%s\t\t\t%s\t\t%s\t\t%s\n' index 'aws id' type state image
for i in ${!ids[@]}; do
  printf '%s\t%s\t%s\t%s\t\t%s\n' $(expr $i + 1) ${ids[$i]} $(echo "$json" | jq -rc '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .InstanceType, .State.Name, .ImageId')
done

echo
echo
echo -n enter index to start [1]:\ 
read index
[ "$index" == '' ] && index=1
index=$(expr $index - 1)
echo
echo $0: info: starting index $(expr $index + 1) with aws id ${ids[$index]}
echo time aws ec2 start-instances --instance-ids ${ids[$index]} \| jq
time aws ec2 start-instances --instance-ids ${ids[$index]} | jq

echo
echo
echo $0: info: checking instance state until running
echo aws ec2 describe-instances --instance-ids ${ids[$index]} \| jq \'.Reservations \| .[] \| .Instances \| .[] \| .PublicDnsName,.State.Name\'
state=''
until [ "$state" == 'running' ]; do
  json="$(aws ec2 describe-instances --instance-ids ${ids[$index]})"
  state="$(echo "$json" | jq -r '.Reservations | .[] | .Instances | .[] | .State.Name')"
  echo "$json" | jq '.Reservations | .[] | .Instances | .[] | .PublicDnsName,.State.Name'
done

echo
echo
echo $0: info: getting instances
echo time aws ec2 describe-instances
json="$(time aws ec2 describe-instances)"
ids=($(echo "$json" | jq -r '.Reservations | .[] | .Instances | .[] | .InstanceId'))
echo
echo
printf '%s\t%s\t\t\t%s\t\t%s\t\t%s\n' index 'aws id' type state image
for i in ${!ids[@]}; do
  printf '%s\t%s\t%s\t%s\t\t%s\n' $(expr $i + 1) ${ids[$i]} $(echo "$json" | jq -rc '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .InstanceType, .State.Name, .ImageId')
done
echo
echo
