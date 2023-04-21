#!/bin/bash
#set -x
#set -euo pipefail

# 挂载 boot 分区
mount /dev/sda1 /boot && sleep 1
# 安装 Gentoo ebuild 数据库
emerge-webrsync
# eselect profile list
emerge -vuDN @world
emerge app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
# 选择系统时区
echo "Asia/Shanghai" > /etc/timezone
emerge --config sys-libs/timezone-data
# 设置字符集
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo 'LC_COLLATE="C"' >> /etc/env.d/02locale
# 重载环境
sleep 1 && env-update

# 修改sshd配置 允许root使用密码登录
sed -i '/^#PermitRootLogin/aPermitRootLogin yes' /etc/ssh/sshd_config
/etc/init.d/sshd start
rc-update add sshd default

### 配置Linux内核
emerge sys-kernel/installkernel-gentoo
emerge sys-kernel/gentoo-kernel-bin
emerge --depclean
emerge @module-rebuild

# echo "使用 DHCP"
emerge net-misc/dhcpcd
rc-update add dhcpcd default
# echo "设置主机名"
echo "GENTOO" > /etc/hostname

# 安装 GRUB 
# 创建/etc/fstab文件
cat << EOF >> /etc/fstab
/dev/sda1   /boot        vfat    defaults,noatime     0 2
/dev/sda2   none         swap    sw                   0 0
/dev/sda3   /            ext4    noatime              0 1
EOF
emerge -vuDN sys-boot/grub
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo
echo
echo
echo
echo "      基础系统已装好，还有几步收尾动作"
echo "      请设置 root 用户的 正式密码"
echo
echo "      密码有长度要求，8个字符以上"
echo "      大小写字母+数字+特殊字符 的字符组合"
echo
passwd
echo
echo "      请牢记密码！！"
echo
echo "      请确认当前是否chroot环境，左边有无显示 (chroot)？"
echo "      如果有，请输入 exit 退出"
echo "-------------------------------------------------"
echo "                  exit"
echo "-------------------------------------------------"
echo
echo "      复制下面的命令取消磁盘的挂载然后重启系统"
echo "-------------------------------------------------"
echo '      cd && umount -l /mnt/gentoo/dev{/shm,/pts,} && umount -R /mnt/gentoo && reboot'
echo "-------------------------------------------------"
echo
echo
