
# mounts the ss hard drive (do this first) 

sudo mkfs.ext4 /dev/xvdaa
sudo mkdir -m 000 /mnt # isnt required if /mnt exists.
echo "/dev/xvdaa /mnt auto noatime 0 0" | sudo tee -a /etc/fstab
sudo mount /mnt