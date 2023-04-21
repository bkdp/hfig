#!/bin/bash
# set -eux
# set -o pipefail

# 挂载 boot 分区
# mount /dev/sda1 /boot

# 配置Portage
# 安装 Gentoo ebuild 数据库
emerge-webrsync
# 选择正确的配置文件
eselect profile list
# 更新@world集合
emerge -av -uDN @world



# 查看 cpu 功能代码
emerge --ask app-portage/cpuid2cpuflags
cpuid2cpuflags  #检查输出
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
env-update 

echo
echo "为了让新环境生效，同时为了和LiveCD环境区分"
echo "请先复制下面的命令，然后在命令行执行一次"
echo
echo 'source /etc/profile && export PS1="(chroot) $PS1"'
echo

