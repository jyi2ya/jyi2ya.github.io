---
title: 一些能够节省按键次数的 bash 配置
date: 2023-10-01 17:48:39
tags:
---

# 一些能够节省按键次数的 bash 配置

众所周知，敲击键盘的同时，人的手指会经历一系列的磨损。长此以往，手指就会变短。为了保护手指，使用下面的 bash 配置，成为和我一样能少按键盘就少按键盘的人吧！

## 给命令起单个字符的别名

对于一些常用的命令，如果没有重复命令，可以给他们起单个字符的别名。

```bash
alias a='ls -A'
alias g='grep'
alias j='jobs -l'
alias l='ls'
alias o='xdg-open'
alias r='rm'
alias t='task' # taskwarrior: 一个 todo-list 小软件
alias v='vi'
alias -- -='cd -' # 这里的意思是将 - 作为 cd - 的别名
```

但是这些写法在 xargs 这里出了点小问题：

```plain
% 17:51:28 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 alias x='xargs'
% 17:51:32 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 l|x g hello
xargs: g: No such file or directory
```

我们的本意是想让它运行

```bash
ls | xargs grep hello
```

但由于 `g` 并不是命令，xargs 报了错。要是我们想让 `x` 被展开为 `xargs` 后，其后的 `g` 继续被展开，我们可以这样写：

```bash
alias x='xargs ' # 注意，xargs 与第二个单引号之间有一个空格
```

之后再运行

```plain
% 17:58:29 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
1 l
a.md
% 17:58:30 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
1 l|x g '`xargs`'
由于 `g` 并不是命令，xargs 报了错。要是我们想让 `x` 被展开为 `xargs` 后，其后的 `g` 继续被展开，我们可以这样写：
```

就好了。这是 bash 的小特性，结尾的空格可以让下一个标识符展开（如果是别名的话）。同理，我们对 `sudo` 也做类似的事情：

```bash
alias s='sudo '
```

太方便辣！

此外，单个 `%` 的作用和 `fg` 相同，都是让后台进程回到前台。

## 给有歧义的命令们起一样的名字

我日常使用 `find` 和 `file` 比较频繁，正常人在缩写他们时，都会想到用 `f` 来作为它们的别名。而如果一个用 `f` 作了别名，另一个就只能用其他奇奇怪怪的缩写。有没有办法让它们共用一个名字呢？

由于脑机接口尚未开发完成，shell 无法通过魔法装置读取我们的思想，知道我们在运行 `f` 时究竟是想运行 `find`，还是 `file`，我们只能手动实现一个 shell 函数，根据上下文猜测输入时究竟想要什么。

（怎么有种 Perl 猜代码块和匿名哈希的感觉）

这是一个简单的示例，可以根据实际使用情况另作调整。

```bash
# find, file
f()
{
	local i
	local expect_find=

	# 如果发现身处管道之中，stdin 里不是终端，有输入，则猜测想要
	# 确定 stdin 中文件的类型
	if ! [ -t 0 ]; then
		file -

	# 如果 stdin 是终端，但是没有参数，猜测是想要递归列出当前目录
	# 下的文件，调用 find
	elif [ -z "$1" ]; then
		find
	else

		# 如果有参数以连字符（-）打头，则猜测是 find 的参数，
		# 比如 -name -type 之类的。
		# 如果参数没有以连字符打头的，则猜测是 file 的参数，参数
		# 都是文件名
		for i in "$@"; do
			if [ "${i:0:1}" = '-' ]; then
				expect_find=y
				break
			fi
		done

		if [ -n "$expect_find" ]; then
			find "$@"
		else
			file "$@"
		fi
	fi
}
```

实际使用看起来还不错。

```plain
% 18:56:38 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 f
.
./a.md
% 18:56:40 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 f < a.md
/dev/stdin: UTF-8 Unicode text
% 18:56:42 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 f -type f
./a.md
% 18:56:45 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 f a.md
a.md: UTF-8 Unicode text
```

这样基本符合日常使用，无法处理的边边角角的情况打全名也不是不能接受啦。

还有一些类似的函数：

```
c()
{
	# 复制？还是复制到剪贴板？
	if [ -t 0 ] && [ "$#" -ge 2 ]; then
		cp "$@"
	else
		clip "$@"
	fi
}

p()
{
	# 调用分页器（pager）？还是打印当前目录？
	if [ -z "$1" ] && [ -t 0 ]; then
		pwd
	else
		less -F "$@"
	fi
}
```

## 给小工具更多的默认行为

有时一些操作总是连在一起的，比如新建文件夹然后切换进去，我们可以用这样的神奇函数：

```bash
md()
{
	if [ -z "$2" ]; then
		mkdir "$1" || return
		cd "$1"
	else
		mkdir "$@"
	fi
}
```

或者我们经常将别处的文件移到当前文件夹，使用这个函数，这样我们可以省略最后那个 `.` 参数。因为奇怪的原因，只有在有且仅有一个参数时才会有这个功能。有多个参数时总会有无法解决的歧义问题。（不过这样已经足够好了）

```bash
m()
{
	if [ -z "$1" ]; then
		echo too few arguments
	elif [ -z "$2" ]; then
		mv "$1" .
	else
		mv "$@"
	fi
}
```

当然，执行 `cd` 再执行 `ls` 应该是某种常规的操作，每年因为这项操作没有优化，无数根手指被磨短。当然可以把 `cd` 变成 `cd && ls`，但是我们想到了一种更加酷炫的方法来解决这个问题，放在另一个部分说。

## 开启大量 shell 内置特性

bash 内置了大量方便的扩展特性，这些特性可以使用 `shopt -s <特性名称>` 打开。比如：`shopt -s autocd`。

### autocd

自动切换目录……意思是假设当前目录下有一个名为 `my-doc` 的子目录，可以用 `my-doc` 取代 `cd my-doc`。这有一个小问题，由于补全时 bash 并不知道想输入的是目录还是指令，指令会和目录一起进入补全列表，又慢又难选。使用 `./my-doc` 会好很多。

### checkwinsize

在终端窗口变化时重新设置 `$LINES` 和 `$COLUMNS`

### dotglob

匹配隐藏文件，这个按个人需求而定？我是觉得这个选项很酷所以打开了。

### extglob

扩展的匹配，完全没用！真的好难用，试图给通配符加上一些正则表达式的扩展，还没有 `find` `sed` `grep` `xargs` 香。

### failglob

没有匹配时报错而不是将模式作为参数传递给程序。非常有用，能避免一堆奇奇怪怪问题。比如：

开启前：

```plain
% 19:21:49 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 touch *.c # 我要摸摸所有 c 文件
% 19:21:49 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 ls
 a.md  '*.c' # 啊不好了，他给我新建了一个 ./*.c
```

开启后：

```plain
% 19:23:23 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 touch *.c
-bash: no match: *.c # 没有找到！
% [1] 19:23:28 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 ls
a.md
```

### globstar

让 `**` 通配符支持递归进子文件夹的匹配，比如 my/\*\*/file 可以匹配 my/magic/powerful/fancy/file ，可以用来部分代替 `find`。

## 全自动的 ls

有时我们希望当前目录下文件发生改变，或工作目录发生改变时，自动 `ls` 一下展示目录现状。

我们很容易写出这样的函数：

```bash
# 第一次运行，保存工作目录和当前目录内容（的哈希值）
LAST_LS=$(command ls | sum)
LAST_PWD="$PWD"

_prompt_smart_ls()
{
	local this_ls
	this_ls=$(command ls | sum)
	if [ "$LAST_LS" != "$this_ls" ] || [ "$LAST_PWD" != "$PWD" ]; then
		LAST_LS="$this_ls"
		LAST_PWD="$PWD"
		ls
		return
	fi
}
```

之后，每调用一次 `_prompt_smart_ls`，它都会检查工作目录和当前目录内容，如果发现有不一样的地方，就 `ls` 一次。我们只要想办法每执行一次指令，就调用一次这个函数就行了。

（当然也可以用其他的检查方式，比如使用神奇的守护进程监视文件系统变化，再和 shell 通信，但是其他方法好像都没有每执行完一次指令就检查一次简单有效）

怎么做到每执行一次命令，就调用一次函数呢？

```bash
PROMPT_COMMAND='_prompt_smart_ls'
```

使用 bash 魔法变量，bash 会在执行每条命令后自动执行 `PROMPT_COMMAND` 这个变量里所存的命令。

最后效果：

```plain
% 20:17:09 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 touch test
a.md  test
% 20:17:12 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 rm test
a.md
% 20:17:13 jyi@Syameimaru-Aya ~/s/m/b/n/shell-abbr
0 cd /
bin/   dev/  home/  lib/    lost+found/  mnt/  proc/  run/   srv/  tmp/  var/
boot/  etc/  init*  lib64/  media/       opt/  root/  sbin/  sys/  usr/
```

太炫酷了！

## 更多的 cd

我们知道设置了 `autocd` 之后，输入 `..` 会自动切换到上级目录……我们可以做得更多！

```bash
alias ...='cd ../..'
alias ....='cd ../../../'
```

## 使用外部工具！

仔细想了想，发现平时使用 `z.sh` 按访问频率自动跳转时，有时会跳转到自己不希望的位置，如果能够选择跳转到哪里就好了。

我们还需要可见的界面！这个想法是从 zsh 的补全里偷来的，感觉可以上下左右选择非常厉害。

所以使用 `fzf` 配合 `z.sh`，做出非常友好的跳转方式：

```bash
fz()
{
	local dir
	dir="$(z | sed 's/^[0-9. \t]*//' |fzf -1 -0 --no-sort --tac +m)" && \
		cd "$dir" || return 1
}
```

## 正确的重新加载配置的方法

修改了 `.bashrc` 文件，想要试用一番！怎么加载配置文件呢？

`source ~/.bashrc`：不好，前任配置文件中残留的 alias 尸体、环境变量可能会影响使用，尤其是写错了的情况下……

`bash`：不好，退出的时候也要连按许多 exit 或者 Ctrl-D

`bash; exit`：比上一个好，但是会影响 `$SHLVL` 变量，可能会对一些奇特脚本（比如 debian 11 下的 `~/.bash_logout`）造成影响。

`exec bash`：非常好！用了 `exec bash`，亩产一千八！

所以这是重新加载配置文件的缩写（reload）：

```bash
alias rl='exec bash'
```

## 总结

> 打键盘是不错，但是也别敲过了头。打键盘打得太多，手指可就被磨短了。
