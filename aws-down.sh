#!/bin/bash


menu() {
  echo
  echo
  echo $0: info: getting instances
  echo time aws ec2 describe-instances
  json_instances="$(time aws ec2 describe-instances)"
  ids=($(echo "$json_instances" | jq -r '.Reservations | .[] | .Instances | .[] | .InstanceId'))
  echo
  echo $0: info: getting images
  echo time aws ec2 describe-images --image-ids $(echo $json_instances | jq -r '.Reservations | .[] | .Instances | .[] | .ImageId')
  json_images=$(time aws ec2 describe-images --image-ids $(echo $json_instances | jq -r '.Reservations | .[] | .Instances | .[] | .ImageId') | jq .)
  echo
  echo
  printf '%s\t%s\t\t\t%s\t\t%s\t\t%s\t\t%s\t\t\t%s\n' index 'aws id' type state image 'creation time' 'image description'
  for i in ${!ids[@]}; do
    image=$(echo "$json_instances" | jq -r '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .ImageId')
    printf '%s\t%s\t%s\t%s\t\t%s\t%s\t%s\n' $(expr $i + 1) ${ids[$i]} $(echo "$json_instances" | jq -rc '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .InstanceType, .State.Name, .ImageId') $(echo "$json_instances" | jq -r '.Reservations | .[] | .Instances | .[] | select(.InstanceId == "'${ids[$i]}'") | .NetworkInterfaces | .[] | .Attachment.AttachTime') "$(echo "$json_images" | jq -r '.Images | .[] | select(.ImageId == "'$image'") | .Description')"
  done
}

menu

echo
echo
echo -n enter index to stop [1]:\ 
read index
[ "$index" == '' ] && index=1
index=$(expr $index - 1)
echo
echo $0: info: stopping index $(expr $index + 1) with aws id ${ids[$index]}
echo time aws ec2 stop-instances --instance-ids ${ids[$index]} \| jq
time aws ec2 stop-instances --instance-ids ${ids[$index]} | jq

echo
echo
echo $0: info: checking instance state until stopped
echo aws ec2 describe-instances --instance-ids ${ids[$index]} \| jq \'.Reservations \| .[] \| .Instances \| .[] \| .PublicDnsName,.State.Name\'
state=''
until [ "$state" == 'stopped' ]; do
  json="$(aws ec2 describe-instances --instance-ids ${ids[$index]})"
  state="$(echo "$json" | jq -r '.Reservations | .[] | .Instances | .[] | .State.Name')"
  echo "$json" | jq '.Reservations | .[] | .Instances | .[] | .PublicDnsName,.State.Name'
done

menu
