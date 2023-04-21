#!/bin/bash
#set -eux
#set -o pipefail

echo
echo "国内镜像网站列表"
mmMirrors='GENTOO_MIRRORS="http://mirrors.ustc.edu.cn/gentoo/ http://mirrors.aliyun.com/gentoo/ http://mirrors.163.com/gentoo/ https://mirrors.tuna.tsinghua.edu.cn/gentoo"'
echo $mmMirrors
sleep 1

echo
echo "获取编译核心数"
mmMakeCPU=$(cat /proc/cpuinfo | grep "model name" | wc -l)
mmMakeCPUcore=$(($mmMakeCPU+1))
mmMakeCPUopts='MAKEOPTS="-j'$mmMakeCPUcore'"'
echo $mmMakeCPUopts
sleep 1

echo
echo "获取文件下载链接"
mmDownloadSite="http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/"
mmS3tar=$(curl -s $mmDownloadSite | grep -oP "stage3-amd64-openrc-\K\d{8}[^\"]*xz" | head -n1)
mmS3tarFile=$mmDownloadSite"stage3-amd64-openrc-"$mmS3tar
echo $mmS3tarFile
sleep 1

### 下面的预配置脚本将调用上面设置的变量

echo "挂载root分区"
mount /dev/sda3 /mnt/gentoo
sleep 1
cd /mnt/gentoo
sleep 1
ls -l
sleep 1

echo
echo "下载stage3"
wget -c $mmS3tarFile
sleep 1
echo
echo "解压stage3归档文件"
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner
sleep 1

echo
echo "配置编译选项到/mnt/gentoo/etc/portage/make.conf"
sed -i '/^COMMON/s/="/="-march=native /' /mnt/gentoo/etc/portage/make.conf
sleep 1
echo
echo "设置 cpu 并行数"
echo $mmMakeCPUopts >> /mnt/gentoo/etc/portage/make.conf
sleep 1
echo
echo "使用国内镜像站"
echo $mmMirrors >> /mnt/gentoo/etc/portage/make.conf
sleep 1

echo
echo "复制 Gentoo ebuild 软件仓库配置"
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
sleep 1
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
sleep 1
echo
echo "复制当前DNS信息到etc"
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
sleep 1

echo
echo "挂载必要的文件系统"
mount --types proc /proc /mnt/gentoo/proc
sleep 1
mount --rbind /sys /mnt/gentoo/sys
sleep 1
mount --rbind /dev /mnt/gentoo/dev
sleep 1
mount --bind /run /mnt/gentoo/run
sleep 1

echo
echo "chroot 进入新环境"
chroot /mnt/gentoo /bin/bash
echo "进入新环境之后请 cd 到 /root 目录继续执行后续操作"
echo

exit 0