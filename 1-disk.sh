#!/bin/bash
#set -x
#set -euo pipefail

echo 
echo "先给硬盘做分区，分3个盘"
echo "分别是：boot、swap和系统盘"
echo "其中boot分+256m，swap分+4g，剩下的空间都给系统盘"
echo && fdisk /dev/sda

sleep 1 && echo
echo "对硬盘分区和格式化"
mkfs.vfat -F 32 /dev/sda1 && sleep 1
mkswap /dev/sda2 && sleep 1
swapon /dev/sda2 && sleep 1
mkfs.ext4 /dev/sda3
echo "分区完成"
echo && echo "查看分区结果" && lsblk 
echo && echo "验证当前时间" && date

### 设置make配置所使用的的临时变量
mmMakeconf="/mnt/gentoo/etc/portage/make.conf"
echo && echo "国内镜像网站列表"
mmMirrors='GENTOO_MIRRORS="http://mirrors.ustc.edu.cn/gentoo/ http://mirrors.aliyun.com/gentoo/ http://mirrors.163.com/gentoo/ https://mirrors.tuna.tsinghua.edu.cn/gentoo"'
echo $mmMirrors && sleep 1
echo && echo "获取编译核心数"
mmMakeCPU=$(cat /proc/cpuinfo | grep "model name" | wc -l)
mmMakeCPUcore=$(($mmMakeCPU+1))
mmMakeCPUopts='MAKEOPTS="-j'$mmMakeCPUcore'"'
echo $mmMakeCPUopts && sleep 1
echo && echo "获取文件下载链接"
mmDownloadSite="http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/"
mmS3tar=$(curl -s $mmDownloadSite | grep -oP "stage3-amd64-openrc-\K\d{8}[^\"]*xz" | head -n1)
mmS3tarFile=$mmDownloadSite"stage3-amd64-openrc-"$mmS3tar
echo $mmS3tarFile && sleep 1

### 下载stage3到挂载分区
echo "挂载root分区"
mount /dev/sda3 /mnt/gentoo && sleep 1
cd /mnt/gentoo && sleep 1
echo "下载stage3"
wget -c $mmS3tarFile && sleep 1
echo "解压stage3归档文件"
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner && sleep 1
# 修改make.conf
echo && echo "配置编译选项"
sed -i '/^COMMON/s/="/="-march=native /' $mmMakeconf
sleep 1 && echo $mmMakeCPUopts >> $mmMakeconf
sleep 1 && echo $mmMirrors >> $mmMakeconf
sleep 1 && echo 'ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"' >> $mmMakeconf
sleep 1 && echo $mmMirrors >> $mmMakeconf
sleep 1 && echo 'USE="-X"' >> $mmMakeconf
echo && echo "复制 Gentoo ebuild 软件仓库配置"
mkdir --parents /mnt/gentoo/etc/portage/repos.conf && sleep 1
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf && sleep 1

echo && echo "复制当前DNS信息到etc"
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/ && sleep 1

echo && echo "挂载必要的文件系统"
sleep 1 && mount --types proc /proc /mnt/gentoo/proc
sleep 1 && mount --rbind /sys /mnt/gentoo/sys
sleep 1 && mount --rbind /dev /mnt/gentoo/dev
sleep 1 && mount --bind /run /mnt/gentoo/run
echo "挂载完成" && echo "复制脚本文件到root"
cp -R /root/*.sh /mnt/gentoo/root/


# tips
echo
echo "      马上进入 chroot 环境"
echo "      复制下面的两条命令，并依次执行"
echo
echo "-------------------------------------------------"
echo '      source /etc/profile && export PS1="(chroot) $PS1"'
echo '      sh /root/2-compile.sh'
echo "-------------------------------------------------"
echo && sleep 1
chroot /mnt/gentoo /bin/bash