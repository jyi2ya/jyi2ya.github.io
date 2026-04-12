Sun Oct 12 14:20:17 CST 2025

看看 Perl 标准库里都有哪些好玩的东西。

== perl-base

=== Carp

高级的 die，写库的时候比较有用。

=== Cwd

路径库，和 shell 里的 pwd 差不多。支持把文件相对路径转换为绝对路径的功能。

=== File::Basename

将文件划分成路径、文件名和后缀

=== File::Spec

也是文件路径相关的库。虽然比直接拼安全，但是没直接拼好用。主打跨平台。

还是多用用吧

=== File::Temp

用于创建临时目录和文件的库，很有用。

怎么感觉都是一些非常 unix 的库。

=== Getopt::Long

哦，原来这个是标准库里的。感觉不错

哎，才知道它可以把收到的参数存到一个大 hash 里，就不用依次定义每个参数的存储位置了。

它支持 utf8 吗？没说，那应该是不支持了

需要之后仔细学学

=== Hash::Util

可以限定某个 hash 无法新增或者减少 key。我超这不是我们 py 的 dataclass 吗

好像没啥用。。。用处在哪？等会搜下。

哦，可以限制一下 class 的成员。但是感觉不如 fields pragma

=== IO::Pipe

这个好，可以代劳 fork 和 exec，直接读取或者写入子进程的 stdio。不过不能同时读写，同时读写需要用到 IPC::Open3 之类的了。

=== IO::Select

比较废物，感觉不如直接上 Mojo::IOLoop 来的好用，那个支持 async await。

=== IO::Socket::INET

神中神，比默认的 socket 调用好用太多。

=== IPC::Open2/IPC::Open3

还行，需要手动 waitpid，感觉不如 IPC::System::capture，但是更加灵活一些。

=== List::Util

神中神

=== POSIX

把 Perl 当 C 写导致的

=== Scalar::Util

只知道它可以用来防止循环引用

=== SelectSaver

Scope Guard 版本的 select 调用，选择默认输出的文件描述符。有点用

=== Text::ParseWords

呃，写 shell 类似物的时候倒是神中神。别的时候不知道用途在哪

=== Text::Wrap

可以把文段做一些简单的排版，具体来讲就是在合适的地方换行。

=== fields

可以限制对象的成员，禁止对不存在的成员读写。鉴定为比较有用。可以替代一点 Mojo::Base，而且似乎比 Class::Struct 对序列化更友好。是基于 restricted hash 做的。

鉴定为好用，是 parse instead of validate 的重要帮手。

== perl

完整版的 perl，比精简版的库更多。

=== bigfloat/bigint/bignum/bigrat

大数字

=== blib

可以自动寻找 blib/lib 中的库，替代 perl -I 的语法。神

=== constant

在 Perl 中创建常量。有用吗？感觉有用但是不多

=== sigtrap

可以方便地处理一组信号。有预置的各种信号列表。算是有用吧……

=== Amiga

amiga 是什么？？完全没听说过……原来是古代操作系统。哎这个感觉没用

=== Archive::Tar

tar 接口，可以创建 tar、设定压缩方式、读写更新里面的文件啥的。鉴定为有用

=== Attribute::Handlers

疑似有用，但是不太会用。不管了

=== AutoLoader

根据模块名和规则自动加载函数……感觉没用。调用函数的时候不就已经知道自己要调的函数的名字了吗，估计是古代函数按名调用的时候的遗产。

=== Benchmark

有用，确实有用

=== CPAN::*

自己写代码的时候没啥用

=== Class::Struct

看似有用，实则没啥用。一个重大缺陷是它生成的哈希表的 key 有个 `Class::` 前缀，导致序列化特别不方便。

哦，好像还是有点用的，它能用数组来存里头的元素，比哈希表小一些。

大多数情况好像确实不如 fields ……

=== Compress::Zlib

好用，可以压缩。

=== DB

内置的调试器，有用吗感觉其实没啥用……可能有用，但是不会用

=== GDBM/SDBM/ODBM/NDBM/DB_File

https://en.wikipedia.org/wiki/DBM_(computing)

呃呃，怎么这么多 nosql

https://perldoc.perl.org/AnyDBM_File

有个对比图，看看

#figure(
  ```plain
                          odbm    ndbm    sdbm    gdbm    bsd-db
                          ----    ----    ----    ----    ------
  Linkage comes w/ perl   yes     yes     yes     yes     yes
  Src comes w/ perl       no      no      yes     no      no
  Comes w/ many unix os   yes     yes[0]  no      no      no
  Builds ok on !unix      ?       ?       yes     yes     ?
  Code Size               ?       ?       small   big     big
  Database Size           ?       ?       small   big?    ok[1]
  Speed                   ?       ?       slow    ok      fast
  FTPable                 no      no      yes     yes     yes
  Easy to build           N/A     N/A     yes     yes     ok[2]
  Size limits             1k      4k      1k[3]   none    none
  Byte-order independent  no      no      no      no      yes
  Licensing restrictions  ?       ?       no      yes     no
  ```
)

坏，感觉 odbm sdbm 和 ndbm 好废物啊，key 和 value 长度加起来有上限。真能用吗

gdbm 和 berkeley db 还行，虽然打不过 sqlite，总归比 fopen 要好一些。而且两个都有维护用的命令行小工具。

berkeley db 不错哦，又支持 hash 又支持 btree 的

https://fedoraproject.org/wiki/Changes/Libdb_deprecated

> We would like to remove libdb from Fedora in future, because BerkeleyDB 6.x has a more restrictive license than the previous versions (AGPLv3 vs. LGPLv2) and due many projects can't use it. Nowadays Fedora uses the old version (5.3.28) and we can't update to newer. Due to many projects have libdb dependency, we propose few steps to complete removal. First step would mark libdb as deprecated package in Fedora 33. Next steps in Fedora 35 would provide converting tool for existing databases and mark libdb as orphaned. 

吗的，傻逼 oracle

gnu 是对的。我要用 gdbm。我要用一辈子 gnu

=== Data::Dumper

神。可惜不如 Data::Printer。

=== Digest::MD5/Sha

神

=== Digest::file

可以直接给文件名计算文件 hash，神。

=== Env

把环境变量导成真的变量，支持自动分割 PATH 类似物，神。

=== Fatal

感觉不如 autodie ……画质

=== File::Compare/Copy

比 `system('cp')` 和 `system('diff')` 优雅一点

=== File::Fetch

轮椅，神

有 Mojolicous 的情况下不如 Mojo::UserAgent

=== File::Find

神

=== File::Path

有点像 `mkdir -p` 和 `rm -r`

=== File::stat

更好用 stat，可以通过成员方法来获取各个属性的值

=== FileCache

只在文件描述符数量受限的时候有用，换句话说就是没用

=== Filter

似乎是代码生成相关的东西。不懂

=== FindBin

找 perl 脚本本身的位置。神

=== HTTP::Tiny

神，可惜打不过 Mojo::UserAgent

=== Hash::Util::FieldHash

一种古老的科技，Perl 叫做 inside-out class。用全局的哈希表来保存对象的域，键是对象的地址，值是域的值。用来实现 private 真正不可访问。

没啥用

=== IO::Poll

比 IO::Select 好一点，但是也没啥用。

=== IO::Zlib

读写文件时自带压缩……没啥用好像

=== IPC::Cmd

运行命令，并且捕获输出

感觉比 IPC::Open3 要 high level 一些啊，看起来挺好用。

=== IPC::Semaphore/SharedMem

写多进程的时候要用。别的时候没啥用

=== JSON::PP

伟大！

=== Mime::Base64

有用，但是不如直接用 Mojo::Util

=== Mime::QuotedPrint

没啥用。不过倒是解开了邮件收到奇怪内容的谜题

=== Math::Complex

复数。除了 FFT 之外不知道什么地方还会用的到这玩意

=== Math::Trig

三角函数。有用。Perl 只提供了 sin 和 cos。

=== Memoize

全自动持久化 cache，神中之神！函数式的至上权威！

而且它竟然还支持 async await。

=== Net::Cmd/Net::Config

没懂……

=== Net::Domain

获取主机名？感觉没啥用

=== Net::FTP/Net::NNTP

都 5202 年了……

=== Net::POP3/Net::SMTP

理论上来说可以直接从 Perl 服务里面发邮件？

=== Net::Netrc

……我从来没见到人用过这个

=== Net::Ping

支持用不同的协议，比如 tcp 和 icmp，检查远程主机的可访问性。有用

=== Net::Time/Net::hostent

不会用

=== Params::Check

我超，这个有用啊！Perl 自己的 json schema validator。

哦，不支持嵌套数据结构，只支持一层。看来主要是在函数参数校验上面用……

从神变成鬼

=== Pod::Usage

感觉很有用，但是尚未完全掌握 pod

=== Safe

用来执行 Perl 代码的沙盒。更安全，但是也没那么安全的 eval。暂时没想到有什么用……

=== Search::Dict

在字典文件里二分吗？？这东西有用吗？

=== Symbol

操纵 Perl 的符号表。这玩意有点太魔法了……

=== Sys::Syslog

syslog 的接口。不知道，我用 systemd 的。而且这个库好难用

=== Term::ANSIColor

搞颜色！神

=== Term::Complete

支持补全的提示。只支持补全第一个单词，不支持连续的。写交互命令的时候可能有用吗……

=== Term::ReadLine

line editing 的库。可能支持历史记录。虽然看起来很有用，但是需要后端比如 Term::ReadLine::Gnu 支持，还要写一堆初始化代码。实则不如 Term::Complete 开箱即用。

=== Term::Table

神！甚至支持宽字符对齐。泪目了。好用捏

=== Text::Abbrev

可以根据命令列表创建无歧义的合法前缀缩写，并以哈希表的形式返回……

```plain
{
    a       "abort",
    ab      "abort",
    abo     "abort",
    abor    "abort",
    abort   "abort",
    e       "edit",
    ed      "edit",
```

这种的，似乎有用

=== Text::Tabs

expand 和 unexpand，对付 tab 比较有用。感觉是格式化输出用的，实则没用……不如直接塞 Term::Table 里

=== Time::HiRes

获得秒级以下的精确时间。用来测量程序运行时间的时候比较有用

=== Time::Local

本地化？谁会要？

=== User::grent/pwent

读 /etc/passwd 和 /etc/group 的

=== Text::Balanced

用来处理闭合的配对标记，自带转义处理。不知道有啥用。

写简易 lexer 吗……感觉不如用 Regexp::Common 搓个 /mgc 的 tokenizer？

哦懂了，可能是分析什么日志的时候用一下。需要把各种标记 extract 出来，parser 太重了
