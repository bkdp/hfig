#!/bin/bash

echo
echo "对硬盘分区和格式化"
mkfs.vfat -F 32 /dev/sda1
sleep 1
mkswap /dev/sda2
sleep 1
swapon /dev/sda2
sleep 1
mkfs.ext4 /dev/sda3
echo "完成"

echo
echo "查看分区结果"
lsblk 

echo
echo "验证当前时间使用命令date"
date
echo
