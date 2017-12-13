instance=$(aws ec2 run-instances --image-id ami-6e1a0117 --security-group-ids sg-6b803e17 --count 1 --instance-type i3.xlarge --key-name devenv-key --subnet-id subnet-fb432d93 --user-data file://startup.sh --query 'Instances[0].InstanceId' | tr -d '"')
ip2=$(aws ec2 describe-instances --instance-ids ${instance} --query 'Reservations[0].Instances[0].PublicIpAddress' | tr -d '"')
ssh -o StrictHostKeyChecking=no -i devenv-key.pem ubuntu@${ip2}
