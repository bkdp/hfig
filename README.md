
### hands free install gentoo

这几天一直跟着官方手册，在虚拟机底下反复练习编译安装gentoo，走了不少弯路之后终于装好，现将安装所用到的相关命令整理到脚本里面，通过脚本可简化大量手工操作，快速装好一个最新版gentoo；

提醒：本脚本是学习记录，仅供参考测试，勿作生产用途；

- 官方手册：https://wiki.gentoo.org/wiki/Handbook:AMD64
- 中文版：https://wiki.gentoo.org/wiki/Handbook:AMD64/zh-cn


### 本地硬件
- 主机：MacBook Pro
- 系统：macOS x.14.6 Mojave
<!-- - CPU：2.3 GHz Intel Core i7
- 内存：16 GB 1600 MHz DDR3
- 显卡：Intel Iris Pro 1536 MB -->

### 软件环境
- 版本：vmware fusion 11.0.1

### 安装目标
- 在虚拟机里面安装一个【无桌面】的gentoo系统，平时主要使用终端ssh管理
- 路线选型：
    - amd64系统架构
    - OpenRC的系统服务
    - 传统bios的启动类型
    - 启动引导程序使用grub
    - 桥接有线网络的方式联网

---
前期准备工作：
### 下载livecd
- 地址：进入中科大镜像站下载
    - http://mirrors.ustc.edu.cn/gentoo/releases/amd64/autobuilds/current-install-amd64-minimal/
    - 在左边的文件列表里面找到镜像文件：install-amd64-minimal-20230416T164657Z.iso （文件名会定期更新，以最新为准）
    - 将这个镜像文件下载到宿主机，作为启动光盘livecd
    - 建议使用这个gentoo官方的livecd，内置的系统环境对安装来说非常方便

### 宿主机新建虚拟机
- 选择安装方法
    - 创建自定虚拟机
    - 选择操作系统
        - linux
        - 其他linux 或更高版本内核64位
    - 选择固件类型
        - 传统BIOS
    - 选择虚拟磁盘
        - 新建虚拟磁盘
    - 自定设置
        - 保存名字改为：gentoo.vmwarevm
        - 系统设置：
            - 常规：默认
            - 共享：取消
            - 键盘鼠标：默认
            - 处理器和内存：cpu 2核，内存 4096m（4G），有条件的话这里可以加大，测试就无所谓了
            - 显示器：取消加速，不使用全分辨率
        - 可移除设备
            - 网络适配器：选中连接，桥接选中以太网卡
            - 硬盘：25g
            - CD/DVD：连接，选择光盘影像为刚下载gentoo官方livecd的iso文件
            - 声卡：取消，然后移除
            - USB：usb设备全部取消，蓝牙也取消
            - 打印机：取消，然后移除
            - 摄像头：移除
        - 其他
            - 启动磁盘：默认，或者指定硬盘启动也可以
            - 加密和限制：不启用
            - 兼容性：默认
            - 隔离：全部取消
            - 高级：默认
### 启动虚拟机
- 点击虚拟机小三角启动运行gentoo的livecd
    - grub：直接回车
    - 选择键盘：直接回车
    - 进入livecd后：
        - 设定livecd的临时密码
            - 输入并执行命令：`passwd`
            - livecd的密码是临时的，所以对密码复杂度要求不高
            - 这里只要输入一个简单好记的密码即可，例如 123456
        - 启用sshd
            - 输入并执行命令：`/etc/init.d/sshd start`
        - 查看ip地址
            - 输入并执行命令：`ip a`
            - 默认网卡是第二个：enp2s1
            - 记住inet后面的ip地址，例如：192.168.1.16
        - 保持livecd状态不变(不关机)
            - 现在可以切换到宿主机上使用ssh连接
            - 离开虚拟机窗口，按快捷键：cmd+ctrl

### 回到宿主机使用终端
- 宿主机打开两个终端窗口
    - 窗口1：ssh连接livecd
    - 窗口2：github拉脚本
- 窗口1：ssh连接livecd
    - 先做这一步
    - ssh root@192.168.1.16
    - 因为是首次连接，会提示输入：yes 确认连接
    - 输入临时密码进入livecd
- 窗口2：github拉脚本
    - github脚本拉到本地机器
        - git clone git@github.com:bkdp/hfig.git
    - 把脚本上传到livecd的/root目录
        - scp 1-disk.sh 2-compile.sh root@192.168.1.16:/root
        - 上传好之后可以关闭窗口2，回到窗口1
- 以下操作都是在窗口1里面执行脚本
    - 第一步：磁盘分区和准备stage
    - 第二步：编译系统内核

---
使用脚本安装系统，只要两步，减少大量手动操作
### 第一步：磁盘分区和准备stage
- 执行命令
    - `sh /root/1-disk.sh`
- 脚本1主要动作和内容：
    - fdisk 为 sda 执行手动分区
    - 主要使用命令：p n w
        - 因本脚本是按官网wiki的操作来，所以磁盘的分区也是和官方一致；
        - 脚本需要磁盘分为以下三个区：
            - boot： /dev/sda1   +256M
            - swap： /dev/sda2   +4G
            - 系统盘：/dev/sda3   +剩余全部空间
        - 分区具体操作的详细说明请参考官方手册：https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks/zh-cn
    - 后面基本都是自动执行的操作
    - 格式化分区
    - 下载最新版本的stage3文件
        - 版本是：stage3-amd64-openrc-<发布日期>
    - 修改make配置文件
    - 挂载文件系统

### 第二步：编译系统内核
- 第一步执行完之后也会输出以下命令提示
- 执行命令
    - `source /etc/profile && export PS1="(chroot) $PS1"`
    - `sh /root/2-compile.sh`
- 脚本2主要内容：
    - 同步安装 ebuild 数据库
    - 更新系统
    - 配置内核、编译内核
    - 挂载分区
    - 安装dhcp
    - 设置root密码
        - 密码复杂度要求：包含大小写字母、数字、特殊字符，8位以上
        - 记住这个复杂的密码，后面正式登录的时候需要用到
    - 最后是按提示手动重启系统

### 装完之后
- 如果重启仍然进入livecd，那么需要设定虚拟机的启动磁盘为硬盘启动，或者取消挂载cdrom；
- 使用ssh再次连接，如果会提示错误，是因为之前的ip地址是livecd的，找到宿主机用户目录底下的.ssh/known_host，把错误提示的对应ip记录删除即可；
- 注意：为方便重启后的首次登录，脚本文件修改了/etc/ssh/sshd_config的配置，启用了root用户允许密码登录；如果后面新增用户或使用key登录建议关闭，PermitRootLogin yes改成no即可；
- 为了减少安装时间，安装脚本只是做了一个基础系统的安装，并没安装官方推荐的系统工具和服务，如cron守护进程、系统日志工具、文件索引工具、时间同步、文件系统、无线网络工具、git、vim、X桌面等等，这些工具或服务可以在系统重启之后，再按需安装；


---

### 特别感谢
- 安装过程得到中文社区大佬们的无私帮助
    - 中文社区：https://www.gentoo.site/index.php


