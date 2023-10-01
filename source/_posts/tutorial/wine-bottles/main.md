---
title: Bottles 安装
date: 2023-10-01 17:48:39
tags:
---

# Bottles 安装

## 好名字！

[Bottles](https://docs.usebottles.com/) 是类似 winetricks 的小软件，用于自动配置 wine、自动安装并配置软件。至于为什么有了 winetricks 还需要新的小软件，bottles 在他们官网上给出了[解释](https://docs.usebottles.com/faq/where-is-winetricks)：bottles 希望提供中心化的依赖处理系统，并且希望拥有比 winetricks 更强的扩展性。总之不是重复造轮子就对了。

之前试着用 winetricks 一键安装 qq，结果有一个托管在 ftp.hp.org 上的文件一直下载不下来。接着我就把 winetricks 扬了。

Wine bottles，酒瓶子。:D

## 安装和安装过程的问题修复

参考[官方的安装指南](https://docs.usebottles.com/getting-started/installation)

### 直接使用包管理器安装

[官方的安装指南](https://docs.usebottles.com/getting-started/installation)里面说，bottles 在多个发行版的源里有包。比如 fedora，就可以使用 `sudo dnf install bottles` 来安装。其他支持的发行版可以去安装指南里头看看。

但是 debian 源竟然没有包，神奇……明明代码目录里有个 `debian/`，这不指明了是要人打包吗？

### 编译 deb 包，再使用包管理器安装

#### 编译 deb 包

因为 debian 源里面没有 bottles 的包，所以我们需要编译代码。同时为了维护依赖，便于删除，我们利用代码目录里面 `debian/` 下的东西把它打成 deb 包，再使用 `apt` 命令安装。

bottles 使用 meson 和 ninja 作为构建系统。听说这两个东西很先进，打算改天去学一下。从 [devgenius.io](https://blog.devgenius.io/how-to-build-debian-packages-from-meson-ninja-d1c28b60e709) 上现学了怎么使用 meson/ninja 打 deb 包：

1. 首先安装 `debhelper` `build-essentials` 和 `dh-make`。其中 `debhelper` 和 `dh-make` 是 debian 的软件包构建相关工具。`build-essentials` 则是软件开发的基础工具，包含 `make` 等小工具。

```sh
sudo apt install debhelper build-essentials dh-make
```

2. 接着下载代码并且进入环境：

```sh
git clone https://github.com/bottlesdevs/Bottles
cd Bottles
```

3. 然后运行 debian 包的自动配置脚本，指定构建系统为 meson：

```sh
dh_auto_configure --buildsystem=meson
```

4. 最后运行构建软件包的命令。参数的 `-b` 是指仅构建二进制的 deb 包。因为是命令是偷来的所以也不是很清楚参数有什么用……

```sh
dpkg-buildpackage -rfakeroot -us -uc -b
```

5. 回到上级目录，发现 deb 包出现了！

```sh
cd ../ && ls -l
```

输出：

```plain
total 284
drwxrwxr-x 1 root root    672 Mar  5 20:02 Bottles-2022.2.28-trento-2/
-rw-r--r-- 1 root root   6872 Mar  5 20:02 com.usebottles.bottles_2022.2.28-trento-2_amd64.buildinfo
-rw-r--r-- 1 root root   5004 Mar  5 20:02 com.usebottles.bottles_2022.2.28-trento-2_amd64.changes
-rw-r--r-- 1 root root 269408 Mar  5 20:02 com.usebottles.bottles_2022.2.28-trento-2_amd64.deb
```

6. 安装

```sh
sudo apt -y install ./com.usebottles.bottles.*.deb
```

7. 检查有没有 bottles 命令

```sh
type bottles
```

如果出现

```plain
bottles is /usr/bin/bottles
```

说明安装成功！

## 启动和启动过程的问题修复

在我这儿 bottles 安装好后运行命令并不能直接启动，会报错：

```plain
% [1] 20:43:10 jyi@Syameimaru-Aya ~
0 bottles
Traceback (most recent call last):
  File "/usr/bin/bottles", line 56, in <module>
    from bottles import main
  File "/usr/share/bottles/bottles/main.py", line 32, in <module>
    from bottles.window import MainWindow
  File "/usr/share/bottles/bottles/window.py", line 35, in <module>
    from bottles.views.details import DetailsView
  File "/usr/share/bottles/bottles/views/details.py", line 25, in <module>
    from bottles.views.bottle_details import BottleView
  File "/usr/share/bottles/bottles/views/bottle_details.py", line 36, in <module>
    from bottles.dialogs.generic import MessageDialog
  File "/usr/share/bottles/bottles/dialogs/generic.py", line 20, in <module>
    gi.require_version('GtkSource', '4')
  File "/usr/lib/python3/dist-packages/gi/__init__.py", line 129, in require_version
    raise ValueError('Namespace %s not available for version %s' %
ValueError: Namespace GtkSource not available for version 4
```

经过搜索发现这里是缺少了 `gir1.2-gtksource-4` 的库。估计是写依赖时写漏了。使用 `sudo apt install gir1.2-gtksource-4` 安装上就可以正常运行了。

## 简易使用

安装运行之后会出现欢迎界面，点几下 “下一步” 之后 bottles 会下载相关组件。这个很慢，可能是因为服务器在国外。多等一会儿就好了。等的时候可以写写博客之类的……

之后使用方式非常显然，所以就不写了（咕了）。
