#!/bin/sh
set -e

### Meebey's HDD Benchmark Script v0.1 ###
# Boot with: mem=1g (else bonnie++ will do cached reads!)

# REQUIRED TOOLS
if ! which parted > /dev/null; then echo "no parted!"; exit 1; fi
if ! which blockdev > /dev/null; then echo "no blockdev!"; exit 1; fi
if ! which fio > /dev/null; then echo "no fio!"; exit 1; fi
if ! which mkfs.ext3 > /dev/null; then echo "no mkfs.ext3!"; exit 1; fi
if ! which bonnie++ > /dev/null; then echo "no bonnie++!"; exit 1; fi
if ! which wget > /dev/null; then echo "no wget!"; exit 1; fi

# SETUP
HDD=sda
HDD_DEV=/dev/$HDD
HDD_P1=${HDD_DEV}1

# SYSTEM INFORMATION
grep name /proc/cpuinfo | uniq
cat /sys/devices/system/cpu/cpu*/topology/core_id | wc -l
cat /sys/devices/system/cpu/cpu*/topology/core_id | sort | uniq | wc -l
uname -a
# limited to 1 GB
grep Memory: /var/log/dmesg
dd if=/dev/zero of=/dev/null bs=32M count=1000
lspci | grep AHCI
egrep 'ata[0-9]\.|SATA link up' /var/log/dmesg
blockdev --getra $HDD_DEV
cat /sys/block/$HDD/queue/scheduler
cat /sys/block/$HDD/device/queue_depth

# STOCK
fio --filename=$HDD_DEV --direct=1 --rw=write --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1
sleep 10
fio --filename=$HDD_DEV --direct=1 --rw=randwrite --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1 --ioengine=libaio --iodepth=32
sleep 10
fio --readonly --filename=$HDD_DEV --direct=1 --rw=read --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1
fio --readonly --filename=$HDD_DEV --direct=1 --rw=randread --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1 --ioengine=libaio --iodepth=32

cd /tmp; wget http://debian.gsd-software.net/benchmark/seeker_baryluk_amd64; chmod +x seeker_baryluk_amd64
for threads in 01 02 04 08 16 32; do echo -n "Threads: $threads "; ./seeker_baryluk_amd64 $HDD_DEV $threads | grep Results; sleep 1; done

echo 3 > /proc/sys/vm/drop_caches
dd if=$HDD_DEV of=/dev/null bs=1M count=16000
dd if=$HDD_DEV /dev/zero of=/dev/sda bs=1M count=16000

blockdev --rereadpt $HDD_DEV && sleep 3
parted $HDD_DEV mklabel msdos
parted $HDD_DEV mkpart p 2048s 64g; sleep 3
parted blockdev --rereadpt $HDD_DEV && sleep 3
mkfs.ext3 $HDD_P1
mount -o noatime $HDD_P1 /mnt
echo 3 > /proc/sys/vm/drop_caches
bonnie++ -f -n 128:4096:4096 -r 24000 -d /mnt -u root
umount /mnt

# WRITE ONCE
fio --filename=$HDD_DEV --direct=1 --rw=write --bs=1M --numjobs=1 --group_reporting --name=file1
sleep 10

fio --filename=$HDD_DEV --direct=1 --rw=write --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1
sleep 10
fio --filename=$HDD_DEV --direct=1 --rw=randwrite --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1 --ioengine=libaio --iodepth=32
sleep 10
fio --readonly --filename=$HDD_DEV --direct=1 --rw=read --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1
fio --readonly --filename=$HDD_DEV --direct=1 --rw=randread --bs=4k --runtime=60 --numjobs=1 --group_reporting --name=file1 --ioengine=libaio --iodepth=32

cd /tmp; wget http://debian.gsd-software.net/benchmark/seeker_baryluk_amd64; chmod +x seeker_baryluk_amd64
for threads in 01 02 04 08 16 32; do echo -n "Threads: $threads "; ./seeker_baryluk_amd64 $HDD_DEV $threads | grep Results; sleep 1; done

echo 3 > /proc/sys/vm/drop_caches
dd if=$HDD_DEV of=/dev/null bs=1M count=16000
dd if=$HDD_DEV /dev/zero of=/dev/sda bs=1M count=16000

blockdev --rereadpt $HDD_DEV && sleep 3
parted $HDD_DEV mklabel msdos
parted $HDD_DEV mkpart p 2048s 64g; sleep 3
parted blockdev --rereadpt $HDD_DEV && sleep 3
mkfs.ext3 $HDD_P1
mount -o noatime $HDD_P1 /mnt
echo 3 > /proc/sys/vm/drop_caches
bonnie++ -f -n 128:4096:4096 -r 24000 -d /mnt -u root
umount /mnt

