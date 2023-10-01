---
title: shell 初始化
date: 2023-10-01 17:48:39
tags:
---

# shell 初始化

众所周知，shell 初始化是一坨巨大的不祥之物。但是如果不了解初始化的过程的话，可能会在编写各种 rc、crontab 时被折磨。所以分享让大家试吃一下。

## 基本概念

### login shell

login shell 是个比较古老的概念，指由 logind 验证用户身份后，便提供一个 login shell 供用户工作。这个 shell 的特殊意义在于，它和用户的会话紧紧绑定在一起，在它开始运行前与它结束运行后都会往 `/var/log/wtmp` 写入用户的登录记录。除了它以外，所有的被用户手动运行的 shell 都被视作普通的应用程序。

因为大家现在都在 tty7 用各种基于 X 的登录管理器，它们验证用户身份后会提供一个桌面环境，所以 login shell 的概念没啥用了。但是它的一些历史遗留问题还是可能给大家带来困惑。

生成一个 login shell 有两种方法：

1. 在 shell 后面加上 `-l` 参数，比如 `bash -l`。

比如，这是一个 login shell：

```plain
03:18 Syameimaru-Aya ~
0 bash -l
03:18 Syameimaru-Aya ~
0 logout
```

而这不是一个 login shell：

```plain
03:18 Syameimaru-Aya ~
0 bash
03:18 Syameimaru-Aya ~
0 logout
bash: logout: not login shell: use `exit'
```

2. 让 shell 的 `argv[0]` 以 `-` 开头。

我们在通过 ssh 远程登录，或者从 ttyN 用 logind 登录时都可以获得 login shell。显然 logind 和 ssh 不应当对 shell 的参数做出假设（即不能假设自己即将运行的程序有一个 `-l` 参数）。所以他们用改 `argv[0]` 的方式来通知 shell。

sshd 是这么干的的 `ssh/session.c` ：

```c
/*
 * If we have no command, execute the shell.  In this case, the shell
 * name to be passed in argv[0] is preceded by '-' to indicate that
 * this is a login shell.
 */
```

logind 也是这么干的（在 ttyN 里面试试这些东西）：

```plain
Debian GNU/Linux bookworm/sid Syameimaru-Aya tty2
Syameimaru-Aya login: jyi
Password:
Linux Syameimaru-Aya 5.19.0-2-amd64 #1 SMP PREEMPT_DYNAMIC Debian 5.19.11-1 (2022-09-24) x86_64 GNU/Linux

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Fri Sep 30 03:06:30 CST 2022 on tty2
03:34 Syameimaru-Aya ~/tmp
0 echo $0
-bash
```

### interactive shell

区分 interactive 与 non-interactive 的意义在于，让 shell 在给人类使用时与执行脚本时表现出不同的行为。

要求标准输入和标准输出都指向终端（用 `isatty` 系统调用确定）。仅在 interactive shell 里面会打印提示符，同时启用行编辑和 job control 特性，对人类十分友好！

这也解释了为啥用 `nc -l -p 2333 -e /bin/bash` 搞的丐版远程登录非常难用，因为这不是 interactive shell，没有方便的编辑特性。也能解释为啥 `echo echo hello | bash` 不会输出提示符而是直接输出命令结果，因为这不是 interactive shell，不会输出提示符。

当然，也可以用 `-i` 选项暴力启动交互模式。

```plain
03:42 Syameimaru-Aya ~
0 echo echo hello | bash -i
    03:43 Syameimaru-Aya ~
    0 echo hello
    hello
    03:43 Syameimaru-Aya ~
    0 exit
03:43 Syameimaru-Aya ~
0
```

（为了分辨命令的输出，输出部分往右缩进了一些）。

此时 shell 会像正常一样输出提示符，读取输出并且执行。

## 不同的组合读取配置文件的区别

以 bash 为例：

login：首先是 `/etc/profile`，接着是 `/etc/profile.d/*`，最后是 `~/.bash_profile` `~/.bash_login` `~/.profile` 三者按顺序检查，读取第一个可读的文件。（注意没有 `~/.bashrc`）在 shell 退出时，还会读取 `~/.bash_logout`。
non-login：不会读取任何配置。
interactive：依次读取 `/etc/bash.bashrc` `~/.bashrc`。
non-interactive：不会读取任何配置。

一般情况下，shell 启动时读取的配置是上列之一，并且 login 优先于 interactive。比如，如果 shell 以 login + interactive 的方式启动，则会读取 `/etc/profile`、`/etc/profile.d/*`、`~/.bash_profile`或`~/.bash_login`或`~/.profile`，但是并不会考虑 `/etc/bash.bashrc` 和 `~/.bashrc`，即使这是一个 interactive shell。

有个仅用于 bash 的例外是，当其以 non-login 且 non-interactive 的方式启动时，它会检查名为 `BASH_ENV` 的环境变量。如果变量值所表示的文件存在，则会读取该文件作为配置。

## 这套神秘机制造成的麻烦

### `~/.bashrc` 与 `~/.bash_profile` 之间的互动

1. login shell 不会读取 `~/.bashrc`，这使得 login shell 不能读取一些配置，很难用。为了解决这个问题，人们决定在 `~/.bash_profile` 里引用 `~/.bashrc`
2. 一些人会在 `~/.bashrc` 里对命令加入一些保护措施，比如 `alias rm='rm -I --preseve-root'`，使得在同时删除三个以上文件时需要确认才能删除，另外，有些人可能会拿垃圾桶代替 `rm`。
3. 一些脚本会以 login 的方式执行（通常是运行得非常早的脚本，甚至不能从父进程里继承 `PATH`），以保证自己能读取 `/etc/profile`，得到正确的环境变量。

当这三点齐聚时，会发生什么呢？

1. 安装软件包时，本来应该被彻底删除的临时文件被不明不白地扔进了垃圾箱里，占用不知道多少的空间。
2. 即使用了 `-y` 参数来避免安装时的用户输出，仍然有可能因为 `rm -I` 等命令而需要等待输入。这对一些后台执行的脚本（比如定时自动更新）来说是非常坏的，因为很可能没有用户会来输入一个 `y`。

为了解决这个问题，只好在 `~/.bashrc` 前面加上这一句看起来很像魔法咒语的指令：

```sh
[[ $- == *i* ]] || return
```

……使得 bash 在读取 `~/.bashrc` 当配置文件时，如果是非交互终端则立即停止读取。

### crond 找不到命令，但是自己在终端里操作时又有

为了方便描述，把这个命令叫作 lolcat

1. 有些人喜欢把 lolcat 放在 `~/.local/bin/` 里
2. 有些人写 crontab 时喜欢用 lolcat（？）
3. 他在 `~/.bashrc` 里面将 `~/.local/bin/` 加入到 `PATH` 中
4. crond 运行 shell 时为 non-interactive + non-login 模式

会发生什么呢？

1. 当在终端里试图运行 lolcat 时，因为现有的是 interactive + non-login 模式，所以读取了 `~/.bashrc`，正确地设置了路径。
2. 当在 crond 里运行 lolcat 时，因为是 non-interactive + non-login 模式，没有读取 `~/.bashrc`，`PATH` 里没有 `~/.local/bin`，找不到 lolcat

所以在写 crontab 时，只好写 `bash -lc lolcat`

不仅仅是 shell 脚本，C 中的 `system()`、Python 的 `os.system()` 以及更多类似物都会遇到这个问题。在终端里直接执行时，会从 bash 中继承 `PATH`，从而表现出正确的行为。而如果在 crond 内执行，则会出现找不到命令的问题。

### 更多例子

暂时没遇到……
