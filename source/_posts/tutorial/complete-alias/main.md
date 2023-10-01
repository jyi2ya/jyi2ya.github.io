# 使用 complete-alias 补全 bash 别名的参数

## 命令别名

众所周知，bash 中有个很方便的功能，使用 `alias` 命令创建命令别名。比如：

```bash
# Git
alias cg='cd `git rev-parse --show-toplevel || echo .`'
alias gaA='git add -A'
alias gad='git add'
alias gbc='git branch'
alias gcm='git commit'
alias gco='git checkout'
alias gst='git status'
alias gcl='git clone'
alias glg='git log --graph'
alias gmg='git merge'
alias gdf='git diff'
```

这样，如果我们输入 `gcl`，bash 就会认为我们输入的是 `git clone`。极大地减少了输入字母的数量。

## 命令参数补全

bash 还有另一个强大的功能，命令参数补全。这个命令参数补全不仅仅是补全当前目录下的文件，而是根据当前已经输入的命令和参数，猜测补全下一个参数。一般来说发行版都会提供大量写好的补全脚本，可以直接使用。

以 Debian 为例，安装 `bash-completion` 软件包后，在 `~/.bashrc` 中加上 `source /etc/bash_completion`。接着输入命令，连续按下两下 `tab` 键就可以触发补全功能（按下 `tab` 键的地方在下面用 `<TAB>` 表示：

```plain
% 19:50:08 (master) ~/sr/md/bl/note/complete-alias
0 ls --h<TAB><TAB>
--help                --hide-control-chars  --hyperlink
--hide=               --human-readable
```

虽然说没有 zsh 的好用就是啦。

## 但是有一个小问题

bash 的命令参数补全是根据命令名来确定的，举一个简单的例子：

```bash
_id()
{
    local cur prev words cword
    _init_completion || return

    if [[ $cur == -* ]]; then
        local opts=$(_parse_help "$1")
        [[ $opts ]] || opts="-G -g -u" # POSIX fallback
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    else
        COMPREPLY=($(compgen -u "$cur"))
    fi
} &&
    complete -F _id id
```

这是从 `/usr/share/bash-completion/completions/id` 里面摘抄的补全相关代码。可以看到，代码里先实现了 shell 函数 `_id`，再用 `complete -F _id id` 来把 `id` 命令相关的补全和 `_id` 绑定在一起。即需要补全 `id` 命令的参数时，会用某种方式调用 `_id` 函数。

这样确实可以处理很多情况，但是对别名无效。比如我们运行 `alias gco='git checkout'`，把 `gco` 作为 `git checkout` 的别名。当我们输入 `gco` 再按 `tab` 键时，因为没有绑定 `gco` 相关的补全函数，所以 bash 不知道如何补全，只能在后面接上文件名。

我们期待的行为应该是输入 `gco` 再按 `tab` 就和输入 `git checkout` 再按 `tab` 一样，可以补全出分支名称：

```plain
% 20:03:23 (master) ~/sr/md/bl/note/complete-alias
0 git checkout<TAB><TAB>
HEAD                 linux-csharp-build   master               ORIG_HEAD
```

## 小问题解决了

之前肯定也有人遇到过一样的问题，并且造了相关的轮子。这儿有一个好用的：[complete-alias](https://github.com/cykerway/complete-alias)。

我们只要把仓库里面 `complete_alias` 文件中的内容复制下来，贴到 `~/.bashrc` 尾巴上（有 1000 多行，有点野蛮。讲究的人可以把它放到某个目录里然后 `.bashrc` 里面用 `source` 命令处理？），再把最后一行 `#complete -F _complete_alias "${!BASH_ALIASES[@]}"` 前面的井号 `#` 删掉就算配置完成。重新启动 bash 即可使用。

总而言之挺开箱即用的，配置不费劲。

效果：

```plain
% 20:14:27 (master) ~/sr/md/bl/note/complete-alias
0 gco<TAB><TAB>
HEAD                 linux-csharp-build   master               ORIG_HEAD
```
