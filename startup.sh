#!/bin/bash

# setting up the machine
sudo apt-get update
sudo apt -y install openjdk-8-jdk
debconf-set-selections <<< "postfix postfix/mailname string your.hostname.com"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
sudo apt -y install postfix
sudo apt -y install mailutils
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
mkdir /home/ubuntu/data

# downloading data
curl -L "https://raw.githubusercontent.com/archivesunleashed/aut-resources/master/Sample-Data/ARCHIVEIT-227-QUARTERLY-XUGECV-20091218231727-00039-crawling06.us.archive.org-8091.warc.gz" > /home/ubuntu/data/ARCHIVEIT-227-QUARTERLY-XUGECV-20091218231727-00039-crawling06.us.archive.org-8091.warc.gz

# downloading and setting up AUT & Shell
mkdir /home/ubuntu/aut
curl -L "https://github.com/archivesunleashed/aut/releases/download/aut-0.12.0/aut-0.12.0-fatjar.jar" > /home/ubuntu/aut/aut-0.12.0-fatjar.jar
curl -L "http://d3kbcqa49mib13.cloudfront.net/spark-2.1.1-bin-hadoop2.6.tgz" > /home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6.tgz
curl -L "https://gist.githubusercontent.com/ianmilligan1/3a313a13084bd0b9995affa9555e218f/raw/a0f576ae365b478da84fccf1e65d559b3e283313/script.scala" > /home/ubuntu/aut/script.scala
tar -xvf /home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6.tgz -C /home/ubuntu/aut/
rm /home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6.tgz
chown -R ubuntu:ubuntu /home/ubuntu/aut/
chown -R ubuntu:ubuntu /home/ubuntu/data/

# running script and e-mailing results
/home/ubuntu/aut/spark-2.1.1-bin-hadoop2.6/bin/spark-shell --jars /home/ubuntu/aut/aut-0.12.0-fatjar.jar -i /home/ubuntu/aut/script.scala
printf "Hello,\n\nYour results are attached. Please see below.\n\nThe AUT Toolkit" | mailx -s "AUT Results" -r "archivesunleashed@gmail.com" -a "From: Archives Unleashed Toolkit <archivesunleashed@gmail.com>" -A /home/ubuntu/data/output/part-00000 ianmilligan1@gmail.com

# kill the instance and save your money
sudo halt
