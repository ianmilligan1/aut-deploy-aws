# Loading Data Process

## Startup

**All of this is scripted in the startup command, `load-data.sh`.** This automates it all.

Launch a c5.large (seems to be the best balance btw price and network performance - low to moderate connections CRAWL, the data is too big).

```
aws ec2 run-instances --image-id ami-6e1a0117 --security-group-ids sg-6b803e17 --count 1 --instance-type c5.large --key-name devenv-key --subnet-id subnet-fb432d93 --user-data file://debug.sh --query 'Instances[0].InstanceId' | tr -d '"'
```

Attach an instance:

```
aws ec2 attach-volume --volume-id vol-0ed6ca7a9950468dc --instance-id i-00f999e7bcd16e3d7 --device /dev/sdf
```

Get the IP:

```
aws ec2 describe-instances --instance-ids i-00f999e7bcd16e3d7 --query 'Reservations[0].Instances[0].PublicIpAddress' | tr -d '"'
```

Connect to the nano.

```
ssh -i key ubtunu@IP
```

## Connect the Drive

These commands are all found in the `loader.sh` command.

Format the drive

```
sudo mkfs -t ext4 /dev/xvdf
```

Mount the drive:

```
sudo mkdir /data
sudo mount /dev/xvdf /data
```

Change ownership to ubuntu user:

```
sudo chown -R ubuntu:ubuntu /data
```

## Transfer the Data Over

Create a new directory to contain ARCs/WARCs:

```
mdkir /data/labour
```

And then transfer data into `/data/labour`.

## Detach Volume

We are then ready to detach and then do next step.

```
aws ec2 detach-volume --volume-id vol-0ed6ca7a9950468dc
```
