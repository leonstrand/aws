#!/bin/bash


menu() {
  echo
  echo
  echo $0: info: getting instances
  echo time aws ec2 describe-instances
  #json_instances="$(time aws ec2 describe-instances)"
  json_instances="$(time aws ec2 describe-instances --filters Name=instance-state-name,Values=pending,running,shutting-down,stopping,stopped)"
  ids=($(echo "$json_instances" | jq -r '.Reservations | .[] | .Instances | .[] | .InstanceId'))
  echo
  echo $0: info: getting images
  echo time aws ec2 describe-images --image-ids $(echo $json_instances | jq -r '.Reservations | .[] | .Instances | .[] | .ImageId')
  json_images=$(time aws ec2 describe-images --image-ids $(echo $json_instances | jq -r '.Reservations | .[] | .Instances | .[] | .ImageId') | jq .)
  echo
  echo
  printf '%6s %51s\t%19s\t%s\t\t%s\t\t%s\t\t%s\t\t\t%s\n' index 'public hostname' 'aws id' type state image 'creation time' 'image description'
  for i in ${!ids[@]}; do
    image=$(echo "$json_instances" | jq -r '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .ImageId')
    printf '%6s %51s\t%19s\t%s\t%s\t\t%s\t%s\t%s\n' $(expr $i + 1) $(echo "$json_instances" | jq -rc '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .PublicDnsName') ${ids[$i]} $(echo "$json_instances" | jq -rc '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .InstanceType, .State.Name, .ImageId') $(echo "$json_instances" | jq -r '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .NetworkInterfaces | .[] | .Attachment.AttachTime') "$(echo "$json_images" | jq -r '.Images | .[] | select(.ImageId == "'$image'") | .Description')"
  done
}

menu

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

menu
