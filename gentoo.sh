#!/bin/bash

# ip a



lsblk #查看磁盘，确认磁盘设备disk的名称是/dev/sda  
#进行bios分区
    fdisk /dev/sda
    # 传统 BIOS 引导，支持四个主分区
    # 分区方案
        # /dev/sda1	fat32   256M	Boot系统分区
        # /dev/sda2	(swap)  RAM*2	交换（swap）分区
        # /dev/sda3	ext4    剩余部分	根分区
    # 执行分区操作
        # 输入 p 显示磁盘的当前分区配置
        # 输入 o 在磁盘上创建一个新的 MBR 磁盘标签（这里也称为 DOS 磁盘标签）；这将删除所有现有分区
        # 输入d和分区号来删除
        # 输入 n 创建一个新分区
        # /boot 分区：输入 +256M 创建一个 256MB 的分区
        # /swap 分区：输入 +4G   创建一个 4GB 的分区；完成后，输入t设置分区类型，输入2选择刚刚创建的分区，然后输入 82 设置分区类型为 "Linux Swap"。
        # 根分区：直接回车使用全部剩余空间作为根分区；
        # 要保存分区布局并退出 fdisk，输入 w

# 创建文件系统
mkfs.vfat -F 32 /dev/sda1
mkswap /dev/sda2
swapon /dev/sda2
mkfs.ext4 /dev/sda3
# 以上完成了对硬盘的分区和格式化
lsblk #查看分区结果；

# 挂载 root 分区
mount /dev/sda3 /mnt/gentoo
cd /mnt/gentoo
# 安装stage包
# 验证当前时间使用命令date
date
    # 如果系统时间不准确，也可以使用时间服务器自动更新时间
    ntpd -q -g

# 下载 stage3
# 直接进入镜像站下载最新的 tar 文件
# 例如这个链接： 
wget -c http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20230409T163155Z.tar.xz
# 解压stage 归档文件
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

# 配置编译选项，/mnt/gentoo/etc/portage/make.conf
# vi /mnt/gentoo/etc/portage/make.conf
sed -i '/^COMMON/s/="/="-march=native /' /mnt/gentoo/etc/portage/make.conf
# COMMON_FLAGS="-march=native -O2 -pipe"
# MAKEOPTS="-j2"  #设置 cpu 并行数
# sed '9aMAKEOPTS="-j2"' /mnt/gentoo/etc/portage/make.conf
sed -i '9aMAKEOPTS="-j3"' /mnt/gentoo/etc/portage/make.conf

# 选择镜像站点
# mirrorselect -i -o >> /mnt/gentoo/etc/portage/make.conf
    # 得到：GENTOO_MIRRORS="https://mirrors.aliyun.com/gentoo/ http://mirrors.aliyun.com/gentoo/ https://mirrors.163.com/gentoo/ http://mirrors.163.com/gentoo/ https://mirrors.tuna.tsinghua.edu.cn/gentoo http://mirror.rackspace.com/gentoo/ http://ftp.iij.ad.jp/pub/linux/gentoo/ http://ftp.jaist.ac.jp/pub/Linux/Gentoo/ http://ftp.riken.jp/Linux/gentoo/ http://download.nus.edu.sg/mirror/gentoo/ http://ftp.daum.net/gentoo/ http://ftp.kaist.ac.kr/pub/gentoo/ http://ftp.twaren.net/Linux/Gentoo/"
# sed -i '$aGENTOO_MIRRORS="https://mirrors.aliyun.com/gentoo/ http://mirrors.aliyun.com/gentoo/ https://mirrors.163.com/gentoo/ http://mirrors.163.com/gentoo/ https://mirrors.tuna.tsinghua.edu.cn/gentoo http://mirror.rackspace.com/gentoo/ http://ftp.iij.ad.jp/pub/linux/gentoo/ http://ftp.jaist.ac.jp/pub/Linux/Gentoo/ http://ftp.riken.jp/Linux/gentoo/ http://download.nus.edu.sg/mirror/gentoo/ http://ftp.daum.net/gentoo/ http://ftp.kaist.ac.kr/pub/gentoo/ http://ftp.twaren.net/Linux/Gentoo/"' /mnt/gentoo/etc/portage/make.conf 
# 仅使用国内镜像站
sed -i '$aGENTOO_MIRRORS="https://mirrors.aliyun.com/gentoo/ http://mirrors.aliyun.com/gentoo/ https://mirrors.163.com/gentoo/ http://mirrors.163.com/gentoo/ https://mirrors.tuna.tsinghua.edu.cn/gentoo"' /mnt/gentoo/etc/portage/make.conf
# sed -i '$aGENTOO_MIRRORS="https://mirrors.aliyun.com/gentoo/ http://mirrors.aliyun.com/gentoo/ https://mirrors.163.com/gentoo/ http://mirrors.163.com/gentoo/ https://mirrors.tuna.tsinghua.edu.cn/gentoo"' /etc/portage/make.conf

# Gentoo ebuild 软件仓库
mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf

# 复制DNS信息
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

# 挂载必要的文件系统
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
# --make-rslave操作是稍后安装systemd支持时所需要的。
mount --make-rslave /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/dev
mount --make-slave /mnt/gentoo/run

# chroot 进入新环境
chroot /mnt/gentoo /bin/bash && source /etc/profile && export PS1="(chroot) ${PS1}"

chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
# env-update && source /etc/profile && export PS1="(chroot) $PS1"

# 挂载 boot 分区
mount /dev/sda1 /boot


# 配置Portage
# 从网站安装 Gentoo ebuild 数据库快照,安装 Gentoo ebuild 数据库
emerge-webrsync
# 选择正确的配置文件
eselect profile list
eselect profile set 1   #只有很少的包被重装或更新
# 更新@world集合，如果一次不行需要多执行几次
# emerge --ask --verbose --update --deep --newuse @world
emerge -av -uDN @world
# 配置USE变量，检查当前活动的USE列表值标记
emerge --info | grep ^USE
    # 得到：USE="acl amd64 bzip2 cli crypt dri fortran gdbm iconv ipv6 libglvnd libtirpc multilib ncurses nls nptl openmp pam pcre readline seccomp split-usr ssl test-rust unicode xattr zlib" ABI_X86="64" ADA_TARGET="gnat_2021" APACHE2_MODULES="authn_core authz_core socache_shmcb unixd actions alias auth_basic authn_alias authn_anon authn_dbm authn_default authn_file authz_dbm authz_default authz_groupfile authz_host authz_owner authz_user autoindex cache cgi cgid dav dav_fs dav_lock deflate dir disk_cache env expires ext_filter file_cache filter headers include info log_config logio mem_cache mime mime_magic negotiation rewrite setenvif speling status unique_id userdir usertrack vhost_alias" CALLIGRA_FEATURES="karbon sheets words" COLLECTD_PLUGINS="df interface irq load memory rrdtool swap syslog" CPU_FLAGS_X86="mmx mmxext sse sse2" ELIBC="glibc" GPSD_PROTOCOLS="ashtech aivdm earthmate evermore fv18 garmin garmintxt gpsclock greis isync itrax mtk3301 nmea ntrip navcom oceanserver oldstyle oncore rtcm104v2 rtcm104v3 sirf skytraq superstar2 timing tsip tripmate tnt ublox ubx" INPUT_DEVICES="libinput" KERNEL="linux" LCD_DEVICES="bayrad cfontz cfontz633 glk hd44780 lb216 lcdm001 mtxorb ncurses text" LIBREOFFICE_EXTENSIONS="presenter-console presenter-minimizer" LUA_SINGLE_TARGET="lua5-1" LUA_TARGETS="lua5-1" OFFICE_IMPLEMENTATION="libreoffice" PHP_TARGETS="php7-4 php8-0" POSTGRES_TARGETS="postgres12 postgres13" PYTHON_SINGLE_TARGET="python3_10" PYTHON_TARGETS="python3_10" RUBY_TARGETS="ruby30" USERLAND="GNU" VIDEO_CARDS="amdgpu fbdev intel nouveau radeon radeonsi vesa dummy v4l" XTABLES_ADDONS="quota2 psd pknock lscan length2 ipv4options ipset ipp2p iface geoip fuzzy condition tee tarpit sysrq proto steal rawnat logmark ipmark dhcpmac delude chaos account"

# 查看 cpu 功能代码
emerge --ask app-portage/cpuid2cpuflags
cpuid2cpuflags  #检查输出
# 将输出的cpu 功能代码写入到指定文件
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags
# 配置软件许可证，显示当前系统范围的值
portageq envvar ACCEPT_LICENSE
# 更改 /etc/portage/make.conf 覆盖系统范围默认接受项
echo 'ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE"' >> /etc/portage/make.conf


# 为系统选择时区，查找可用的时区，然后写进/etc/timezone文件
# ls /usr/share/zoneinfo
echo "Asia/Shanghai" > /etc/timezone
# 基于 /etc/timezone 条目更新 /etc/localtime 文件，让系统的 C 类库知道系统在什么时区。
emerge --config sys-libs/timezone-data

# 区域设置
# 设置字符集，在/etc/locale.gen里增加：en_US ISO-8859-1
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo 'LC_COLLATE="C"' >> /etc/env.d/02locale

# 重新加载环境：
env-update && source /etc/profile && export PS1="(chroot) ${PS1}"

### 配置Linux内核
# 使用 distribution 内核前, 请验证系统已经安装正确的 installkernel 软件包
emerge --ask sys-kernel/installkernel-gentoo
# 避免编译本地内核源代码的系统管理员可以使用预编译的内核镜像
emerge --ask sys-kernel/gentoo-kernel-bin
# 清理过时的软件包
emerge --depclean
# 需要的话, 可以手动重建 initramfs，内核更新后，执行
emerge --ask @module-rebuild


### 配置系统
# 创建/etc/fstab文件，用于挂载系统分区
# blkid 查看系统分区的标签信息
# cat /etc/fstab
cat << EOF >> /etc/fstab
/dev/sda1   /boot        vfat    defaults,noatime     0 2
/dev/sda2   none         swap    sw                   0 0
/dev/sda3   /            ext4    noatime              0 1
EOF
# cat /etc/fstab 确认是否添加

# 设置主机名 OpenRC方式
echo GENTOO > /etc/hostname

# 通过 dhcpcd 使用 DHCP
emerge --ask net-misc/dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start

# 使用passwd命令设置root密码
passwd
crust7nation9Bark
Ih@d5Hd&xt


# 配置引导和启动 OpenRC方式
# 系统使用/etc/rc.conf配置系服务，启动和关闭


###### 安装系统工具
### 系统日志工具 OpenRC方式
# 选择的系统日志工具，你可以用 emerge 命令安装它。在 OpenRC 中，使用 rc-update 将它加入默认运行级别
emerge --ask app-admin/sysklogd
rc-update add sysklogd default

# Cron守护进程，执行计划中需要定期执行的命令
emerge --ask sys-process/cronie
rc-update add cronie default

# 远程 shell 访问
# 先修改 sshd_config 允许 root 用户登录
sed -i '32aPermitRootLogin Yes' /etc/ssh/sshd_config
sed -i '/PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config
cat -n /etc/ssh/sshd_config | grep -E "PermitRootLogin|PasswordAuthentication"
# 将 sshd init 脚本添加到默认运行级别
rc-update add sshd default

# 同步系统时钟
emerge --ask net-misc/chrony
rc-update add chronyd default

# 安装DHCP客户端
# 使系统能够使用netifrc脚本自动获取一个或多个IP地址
# emerge --ask net-misc/dhcpcd


##### 配置引导加载程序GRUB
# 引导器负责在引导过程中启动内核——若没有引导器，系统将不知道按下电源键后将如何进行
# 使用只支持MBR分区表的旧版BIOS系统时，无需进行其他配置即可安装GRUB
emerge --ask --verbose sys-boot/grub
# emerge -av sys-boot/grub
emerge -av -uDN sys-boot/grub
# 如果返回错误，可能是用了 uefi
# echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
# 安装 GRUB 所需的文件到/boot/grub/目录
grub-install /dev/sda
# 生成 GRUB
grub-mkconfig -o /boot/grub/grub.cfg



# 退出chroot环境并unmount全部已持载分区。然后敲入一条有魔力的命令来初始化最终的、真实的测试：reboot。
exit


cd
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot










