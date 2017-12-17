#!/bin/bash

# setting up the machine
sudo apt-get update
sudo apt -y install openjdk-8-jdk
sudo apt -y install sshpass
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo apt -y install postfix
sudo apt -y install mailutils
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
mkdir /home/ubuntu/data
mkdir /data
mount /dev/xvdf /data

# notify
printf "Hello,\n\nI am beginning to process your data.\n\nThe AUT Toolkit" | mailx -s "AUT Results" -r "archivesunleashed@gmail.com" -a "From: Archives Unleashed Toolkit <archivesunleashed@gmail.com>" ianmilligan1@gmail.com

# downloading script that will be run (IMPORTANT TO CHANGE)
curl -L "https://gist.githubusercontent.com/ianmilligan1/559455fc19412ba4fbdb1b87a5659727/raw/760e621e5a7c8be32861f58fc7714d1d57d287d1/script-all-derivatives.scala" > /home/ubuntu/aut/script.scala

# downloading and setting up AUT & Shell
mkdir /home/ubuntu/aut
curl -L "https://github.com/archivesunleashed/aut/releases/download/aut-0.12.1/aut-0.12.1-fatjar.jar" > /home/ubuntu/aut/aut-0.12.1-fatjar.jar
curl -L "http://d3kbcqa49mib13.cloudfront.net/spark-2.1.1-bin-hadoop2.6.tgz" > /home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6.tgz
tar -xvf /home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6.tgz -C /home/ubuntu/aut/
rm /home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6.tgz
chown -R ubuntu:ubuntu /home/ubuntu/aut/
chown -R ubuntu:ubuntu /home/ubuntu/data/
chown -R ubuntu:ubuntu /data

# running script (with 50GB memory) and aggregating results
cd /home/ubuntu/aut
spark-2.1.1-bin-hadoop2.6/bin/spark-shell --driver-memory 50G --packages "io.archivesunleashed:aut:0.12.1" -i /home/ubuntu/aut/script.scala
mkdir /data/aggregates
cat /data/all-domains/part* > /data/aggregates/all-domains.txt
rm /data/all-domains/part*
rm -rf /data/all-domains
cat /data/all-text/part* > /data/aggregates/all-text.txt
rm /data/all-text/part*
rm -rf /data/all-text
mv /data/links-for-gephi.gexf /data/aggregates/links-for-gephi.gexf

# send done announcement
printf "Hello,\n\Your job is done! Logs attached. Results are on the now detached EBS volume. Grab it with a nano instance before I bankrupt you!\n\nThe AUT Toolkit" | mailx -s "AUT Results" -r "archivesunleashed@gmail.com" -a "From: Archives Unleashed Toolkit <archivesunleashed@gmail.com>" -A /var/log/cloud-init-output.log ianmilligan1@gmail.com

# kill the instance and save your money
sudo halt
