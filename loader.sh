sleep 60
mkfs -t ext4 /dev/xvdf
mkdir /data
mount /dev/xvdf /data
chown -R ubuntu:ubuntu /data
mdkir /data/labour

# then transfer data into /data/labour using WASAPI or other call

umount -d /dev/xvdf

# we then need to detach using AMAZON CLI, not quite sure how to do that yet in this workflow