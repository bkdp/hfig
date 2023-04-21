#!/bin/bash
# set -eux
# set -o pipefail

echo "请先设置root密码"
passwd
# 另外注意：基于安全考虑，此脚本的sshd服务默认没有启动，如果需要可以取消底下的注释脚本
### sshd服务的启用脚本
### 默认是没启动ssh的，
# 这里需要修改 /etc/ssh/sshd_config 把：
#PermitRootLogin prohibit-password
# PermitRootLogin yes
# 启动ssh和加入默认启动 
/etc/init.d/sshd start
rc-update add sshd default

### 配置Linux内核
# 使用 distribution 内核前, 请验证系统已经安装正确的 installkernel 软件包
emerge  sys-kernel/installkernel-gentoo
# 避免编译本地内核源代码的系统管理员可以使用预编译的内核镜像
emerge  sys-kernel/gentoo-kernel-bin
# 清理过时的软件包
emerge --depclean
# 需要的话, 可以手动重建 initramfs，内核更新后，执行
emerge  @module-rebuild


### 配置系统
echo "创建/etc/fstab文件，用于挂载系统分区"
# blkid 查看系统分区的标签信息
# cat /etc/fstab
cat << EOF >> /etc/fstab
/dev/sda1   /boot        vfat    defaults,noatime     0 2
/dev/sda2   none         swap    sw                   0 0
/dev/sda3   /            ext4    noatime              0 1
EOF
# cat /etc/fstab 确认是否添加


echo "设置主机名"
echo GENTOO > /etc/hostname


###### 安装系统工具
echo "使用 DHCP"
emerge  net-misc/dhcpcd
rc-update add dhcpcd default
# rc-service dhcpcd start
### 系统日志工具 OpenRC方式
# 选择的系统日志工具，你可以用 emerge 命令安装它。在 OpenRC 中，使用 rc-update 将它加入默认运行级别
echo "安装系统日志工具"
emerge  app-admin/sysklogd
rc-update add sysklogd default
# Cron守护进程，执行计划中需要定期执行的命令
echo "安装cronie"
emerge  sys-process/cronie
rc-update add cronie default

echo "同步系统时钟"
emerge  net-misc/chrony
rc-update add chronyd default


##### 配置引导加载程序GRUB
# 引导器负责在引导过程中启动内核——若没有引导器，系统将不知道按下电源键后将如何进行
# 使用只支持MBR分区表的旧版BIOS系统时，无需进行其他配置即可安装GRUB
emerge  --verbose sys-boot/grub
# emerge -av sys-boot/grub
emerge -av -uDN sys-boot/grub

# 安装 GRUB 所需的文件到/boot/grub/目录
grub-install /dev/sda
# 生成 GRUB
grub-mkconfig -o /boot/grub/grub.cfg




echo
echo
echo
echo
echo "来到这里就已经全部装完了，还有最后几步"
echo "请确认是否仍在chroot环境，如果是，请输入 exit"
echo
echo "如果左边显示是在 livecd 环境，请复制底下命令并执行，执行完毕，就可以reboot了"
# echo
echo 'cd && umount -l /mnt/gentoo/dev{/shm,/pts,} && umount -R /mnt/gentoo'
echo
echo
echo
echo