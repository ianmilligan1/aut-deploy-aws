sleep 60
mkfs -t ext4 /dev/nvme1n1
mkdir /data
mount /dev/nvme1n1 /data
chown -R ubuntu:ubuntu /data
mdkir /data/labour

# then transfer data into /data/labour using WASAPI or other call

# umount -d /dev/nvme1n1

# we then need to detach using AMAZON CLI, not quite sure how to do that yet in this workflow