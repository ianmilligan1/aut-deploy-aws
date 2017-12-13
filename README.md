# aut-deploy-aws

This repository deploys an AWS instance, installs dependencies and AUT, transfers data, analyses it, and e-mails a relatively small amount of output to the user. You get a nice message like below.

![Screenshot of output](https://user-images.githubusercontent.com/3834704/33961337-b2730900-e01b-11e7-805c-fcf7bf878645.png)

**Note: This is a janky hack and proof of concept for me.**

## Dependencies

- [AWS-CLI interface](https://aws.amazon.com/cli/): `pip install awscli`

## Setting up Amazon CLI

You need to run the following commands. First, you need to configure the client. You'll need your AWS credentials from the "Your Security Credentials" page on the AWS homepage. You can enter them by typing the following command.

```
aws configure
```

You'll then also need to create a security groups, key pairs, etc. You will want to change some of the example lanuage below.

This creates a security group:

```
aws ec2 create-security-group --group-name devenv-sg --description "security group for development environment in EC2"
```

This tells the security group to allow SSH connections:

```
aws ec2 authorize-security-group-ingress --group-name devenv-sg --protocol tcp --port 22 --cidr 0.0.0.0/0
```

Finally, this creates a new key pair:

```
aws ec2 create-key-pair --key-name devenv-key --query 'KeyMaterial' --output text > devenv-key.pem
```

You may need to change the permissions depending on your system:

```
chmod 400 devenv-key.pem
```

## Deploying

Now you're ready to run the script in this repository, which will do all of this. However, let's look at the commands.

The first command spins up an instance. The command below uses an i3.xlarge, but you may want to scale up or down depending on the data. **Note that you will need to configure your own subnet, using the VPC work on Amazon.** The second line gets the IP, and the third line SSHes into the prompt.

The important thing is that it runs a script, `startup.sh`. 

```
instance=$(aws ec2 run-instances --image-id ami-6e1a0117 --security-group-ids sg-6b803e17 --count 1 --instance-type i3.xlarge --key-name devenv-key --subnet-id subnet-fb432d93 --user-data file://startup.sh --query 'Instances[0].InstanceId' | tr -d '"')
ip2=$(aws ec2 describe-instances --instance-ids ${instance} --query 'Reservations[0].Instances[0].PublicIpAddress' | tr -d '"')
ssh -o StrictHostKeyChecking=no -i devenv-key.pem ubuntu@${ip2}
```

By customizing these commands, found in `aws-deploy.sh`, you will be able to run it yourself. Most of the tweaks will have to do with the `security-group-ids` and `subnet-id`.

## The Script

The above command sends a script, `startup.sh` to be run by the root user on the remote AWS instance. In general, it runs in the background, processes data, e-mails you the result file, and then kills itself. You shouldn't have to change too much, just the source of the data; the e-mail address you're sending results to.

```bash
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
```

It is annotated here. But if you had your own publicly accessible data, you could swap it out on the "downloading data" section. It runs this scala script, remotely grabbed from [here](https://gist.githubusercontent.com/ianmilligan1/3a313a13084bd0b9995affa9555e218f/raw/a0f576ae365b478da84fccf1e65d559b3e283313/script.scala).

```scala
import io.archivesunleashed.spark.matchbox._
import io.archivesunleashed.spark.rdd.RecordRDD._

val r = RecordLoader.loadArchives("/home/ubuntu/data/*.gz", sc) 
.keepValidPages()
.map(r => r.getUrl)
.saveAsTextFile("/home/ubuntu/data/output")

sys.exit
```

## All Together

Once you have things set up, you can just swap out the script and variables and run like so.

```
sh aws-deploy.sh
```
