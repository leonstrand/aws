#!/bin/bash


ssh_key=~/.ssh/my-west-keypair.pem
ssh_user='ec2-user'


echo
echo $0: creating aws running instance public dns name array
echo $0: info:
echo aws ec2 describe-instances --filters Name=instance-state-name,Values=running \| jq -r \'.Reservations \| .[] \| .Instances \| .[] \| .PublicDnsName\'
instances=($(aws ec2 describe-instances --filters Name=instance-state-name,Values=running | jq -r '.Reservations | .[] | .Instances | .[] | .PublicDnsName'))

echo
printf '%s\t%s\n' index 'aws public dns name'
for index in $(seq 0 $(expr ${#instances[@]} - 1)); do
  printf '%s\t%s\n' $(expr $index + 1) ${instances[$index]}
done

echo
echo -n $0: select aws instance for rsync [1]:\ 
read index
[ -z "$index" ] && index=1
index=$(expr $index - 1)
instance=${instances[$index]}
if [ -z "$instance" ]; then
  echo $0: fatal: instance name null
  exit 1
fi

echo
echo -n $0: aws instance $instance is '(s)ource or (d)estination [s]: '
read direction
case "$direction" in
  s|'')
    echo
    echo -n $0: 'enter source path (must not be null): '
    read source_path
    if [ "$source_path" == '' ]; then
      echo $0: fatal: null source path
      exit 1
    fi
    echo -n $0: 'enter destination path ['.']: '
    read destination_path
    [ "$destination_path" == '' ] && destination_path='.'
    echo
    echo $0: info:
    echo time rsync -av --partial --progress -e \"ssh -i $ssh_key\" $ssh_user@\"$instance\":$source_path $destination_path
    time rsync -av --partial --progress -e "ssh -i $ssh_key" $ssh_user@"$instance":$source_path $destination_path
  ;;
  d)
    echo
    echo -n $0: 'enter source path [.]: '
    read source_path
    [ "$source_path" == '' ] && source_path='.'
    echo
    echo -n $0: 'enter destination path ['']: '
    read destination_path
    echo
    echo $0: info:
    echo time rsync -av --partial --progress -e \"ssh -i $ssh_key\" $source_path $ssh_user@\"$instance\":$destination_path
    time rsync -av --partial --progress -e "ssh -i $ssh_key" $source_path $ssh_user@"$instance":$destination_path
  ;;
esac

