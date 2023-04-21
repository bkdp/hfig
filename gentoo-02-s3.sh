#!/bin/bash
# set -eux
# set -o pipefail

# source /etc/profile
# sleep 1
# export PS1="(chroot) ${PS1}"
# sleep 1

echo
echo "已经进入chroot环境，为了和LiveCD环境区分"
echo "请先复制下面的命令，然后在命令行执行一次"
echo
echo 'source /etc/profile && export PS1="(chroot) $PS1"'
echo