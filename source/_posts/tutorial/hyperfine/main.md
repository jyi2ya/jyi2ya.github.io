hyperfine 使用指南
==================

简介
----

测量程序运行耗时是一个常见的需求。

我们经常会调整自己编写的程序，来给程序加速。但是自己提出的加速计划，不一定会被
机器认可。比如，你觉得 `++i` 比 `i++` 更快并且花了两天时间把程序里所有的后缀全
改成了前缀，但是机器不管，她编译的时候直接把你的写法给扬掉了。这个时候再在 git
的提交信息里写 `perf: 优化 XX 部分性能` 就会显得非常滑稽。所以，我们经常需要对
程序性能测试来保证自己的优化是有效的。对程序性能测试的最常用的方法就是计时。

小时候幼儿园的老师经常教育我们，在 [bash][] 里面用 `time` 的命令就可以测量程序
运行的时间。这也是大家最常用的方法。但是我们都知道，`time` 是一个非常粗糙的工
具。用它测量程序性能时，总会遇到这么几个问题：

* 测量出来的时间真的是准的吗？会不会受到系统波动的影响？
* 测量出来的时间有多可靠？该怎么知道测量误差？
* 我能比较轻松地对比两个或多个程序的性能吗？

我们可以通过写一堆土制脚本来解决上述问题，但是与其费心写功能不全、漏洞百出的脚
本，还不如直接使用已有的趁手工具。

[hyperfine][] 就是一个优秀的性能测试工具。

[bash]: https://manpages.debian.org/buster/bash/bash.1.en.html
[hyperfine]: https://github.com/sharkdp/hyperfine

优势
----

根据 hyperfine 自己的 [介绍][readme] ，hyperfine 拥有如下功能：

* 多次测量并统计均值方差
* 支持任意 shell 命令
* 进度条和预估剩余时间
* 预热：正式测试之前先运行几次
* 测试之前执行指定命令（可用于清除缓存）
* 自动发现 cache 影响和系统性能波动影响
* 多种输出格式，支持 CSV、JSON、Markdown 等等
* 跨平台

（注：hyperfine 的介绍是有 [中文翻译][tr] 的，但是我看的时候它略微有些过时了。
希望有好心人来更新一下翻译）

[readme]: https://github.com/sharkdp/hyperfine/blob/master/README.md
[tr]: https://github.com/chinanf-boy/hyperfine-zh

它的使用截图如下：

![hyperfine](https://camo.githubusercontent.com/88a0cb35f42e02e28b0433d4b5e0029e52e723d8feb8df753e1ed06a5161db56/68747470733a2f2f692e696d6775722e636f6d2f7a31394f5978452e676966)

个人评测：life-changing 的好东西，我现在没有 hyperfine 都不会测程序了。

基本使用
--------

hyperfine 的使用方式非常符合直觉，命令行结构和选项设计得很好。

### 安装

hyperfine 是用 [rust][] 写的（不打算去学一下？）。如果机器上有 rust 开发环境，
直接运行 `cargo install hyperfine` 即可完成安装。[cargo][] 是 rust 的编译系统
和依赖管理工具。

如果机器上没有 rust 开发环境，可以求助你的包管理器，或者从
[hyperfine 在 Github 上的发布页面][git] 中，下载与自己的机器架构对应的二进制
文件。

[cargo]: https://doc.rust-lang.org/cargo/
[rust]: https://www.rust-lang.org/
[git]: https://github.com/sharkdp/hyperfine/releases

### 测试单个程序

命令：

    hyperfine 'hexdump file'

结果：

    11:17 jyi-station ~/tmp/bgifile
    0 hyperfine 'hexdump test13.c'
    Benchmark 1: hexdump test13.c
      Time (mean ± σ):     385.0 ms ±   5.1 ms    [User: 383.0 ms, System: 2.1 ms]
      Range (min … max):   381.6 ms … 398.9 ms    10 runs

从结果可以看出，hyperfine 把程序运行了 10 次。测量出来平均耗时是 385 ms，误差
是 5.1 ms。运行的时候，hyperfine 把程序的所有输出重定向到了 `/dev/null` 里，所
以终端上没有多余的内容。

你看，我几乎什么都没做，只是把命令提供给 hyperfine，她就自动帮忙把所有东西都测
好了！

我们甚至无需检查误差是否过大，因为 hyperfine 会自动检测误差过大的情况，并且根
据程序运行时间的特征来猜测可能发生了什么问题，并给出一些建议。非常贴心。后面会
详细讨论这些细节。

### 对比测试多个程序

命令：

    hyperfine 'hexdump test13.c' 'xxd test13.c' 'xxd test14.c'

结果：

    11:24 jyi-station ~/tmp/bgifile
    0 hyperfine 'hexdump test13.c' 'xxd test13.c' 'xxd test14.c'
    Benchmark 1: hexdump test13.c
      Time (mean ± σ):     383.6 ms ±   1.9 ms    [User: 381.8 ms, System: 1.6 ms]
      Range (min … max):   381.6 ms … 387.7 ms    10 runs

    Benchmark 2: xxd test13.c
      Time (mean ± σ):      90.2 ms ±   1.0 ms    [User: 88.4 ms, System: 1.9 ms]
      Range (min … max):    88.7 ms …  93.4 ms    32 runs

    Benchmark 3: xxd test14.c
      Time (mean ± σ):     180.2 ms ±   2.8 ms    [User: 176.8 ms, System: 3.2 ms]
      Range (min … max):   177.1 ms … 186.6 ms    16 runs

    Summary
      'xxd test13.c' ran
        2.00 ± 0.04 times faster than 'xxd test14.c'
        4.25 ± 0.05 times faster than 'hexdump test13.c'

在这个例子里，我们给了 hyperfine 三个参数，让她测量三个程序的耗时。hyperfine
首先输出了三个程序各自的运行结果，这部分和测试单个程序时的结果差不多。但是在报
告的最后，hyperfine 还额外给出了一些信息。她指出了跑的最快的程序（港记程序 :P）
，并且显示了其相对其他程序的加速比和误差。

我们一般测试程序时只需要关注最后的 “Summary” 一栏，知道哪个更快、快多少就可以
了。前面几行是和别人吵架时，给他们看测试结果让他们闭嘴时用的。

运行原理
--------

对每个程序，hyperfine 会把它运行 10 次（运行次数有选项可以配置）。hyperfine 会
对运行时间计时，并且求出均值和标准差。

每次运行的时候，hyperfine 会运行一个 shell 来执行这些程序。比如，假定程序
是 `sleep 1`，那么 hyperfine 实际运行的是 `sh -c 'sleep 1'`。这种用 shell 来运
行程序的行为，会导致程序运行时间测量结果偏大；但是如果不用 shell 来运行程序，
大家平时习惯的 `~/` 和 `*.txt` 这些便利缩写就不能用了，非常麻烦。

总之，这种使用 shell 来执行参数的设计，算是便利与准确之间的一种折衷。

为了使测量结果更精确，你可以手动禁止 hyperfine 使用 shell 来执行程序的行为。
hyperfine 本身也会检测 shell 对测量结果的影响，并且在她觉得 shell 对测量结果的
影响已经大到不可忽略时提出警告。判定规则与细节将在之后描述。

使用进阶
--------

现在，你已经基本学会用 hyperfine 了！让我们来看看一些更好玩的东西吧。

### 测试 IO 密集型程序

假设我们要运行一个大量读写磁盘文件的程序 10 次，我们会发现什么怪现象呢？我们
会发现，第一次或前几次运行所花费的时间会显著大于后面几次。这是由于 Linux 系统
有 Page Cache 的机制，它会尽可能努力地把最近使用过的文件缓存在内存里。

在第一次运行的时候，程序试图读文件。操作系统发现内存里没有相关文件，只好老老实
实地从磁盘上把文件读出来再交给程序。但是紧接着程序运行第二三四次，程序试图读文
件时，操作系统发现文件刚刚才被读过，还被缓存在内存里，于是直接把内存中的内容交
给程序，直接省略掉了读盘的过程。众所周知，内存的读写速度一般远大于硬盘。这导致
了第二三四次运行程序时，程序用时会显著少于第一次。

类似的情况还会出现在很多具有缓存机制的系统（没有特指操作系统！）里。在对于这些
系统打交道的程序计时时，我们需要给 hyperfine 加一些参数。

#### 预热

我们可以使用 `--warmup N` 的参数让程序被真正计时之前，先运行 N 次，其中 N 是一
个整数。比如，`hyperfine --warmup 2 sleep 3` 这个命令实际上会运行 `sleep 3` 这
个命令 12 次，其中最后 10 次会被计时。

这种方式有利于将程序需要用到的东西提前装到缓存里。可以测量程序在缓存工作良好时
的运行效率。

#### 提前执行指令

我们可以使用 `--prepare X` 的参数让 hyperfine 每次运行程序之前，先运行一下 X，
其中 X 是一条 shell 命令。比如，
`hyperfine --prepare 'echo 3 | sudo tee /proc/sys/vm/drop_caches' sleep 3`
这个命令，会运行 `sleep 3` 10 次，但是每次运行前，会运行
`echo 3 | sudo tee /proc/sys/vm/drop_caches` 一次，来清除 Linux 的 Page Cache。

这种方式直接让缓存没用了。可以测量程序冷启动的速度。

### 测试运行时间过短的程序

之前说到，hyperfine 会用一个 shell 来执行待计时的程序。但是如果程序跑得很快，
导致 shell 启动、解析、执行的时间已经占总用时不小的一部分了，那么测量误差就会
变得不可接受。

这个时候我们就可以使用 `-N` 参数来制止 hyperfine 使用 shell。此时，她会用一个
内置的简陋的解析器来把命令的可执行文件和参数给分开。这个简陋的解析器主要使用
空白字符来分割参数，但是也支持基础的转义字符和引号。

比如：

    hyperfine -N 'touch x'

### 不知道自己的程序属于哪种类型？

有笨比……

如果你不知道你的程序要跑多久，也不知道它是不是要用到某种缓存系统，直接把它当成
纯计算的程序来测就行了。hyperfine 会在发现不对劲时来提醒你。

下面是几个例子：

#### 奇怪的测量结果

    20:21 jyi-station ~/tmp/bgifile
    0 hyperfine 'cat test18.c'
    Benchmark 1: cat test18.c
      Time (mean ± σ):      16.9 ms ±   1.0 ms    [User: 1.1 ms, System: 15.9 ms]
      Range (min … max):    15.7 ms …  22.1 ms    154 runs

      Warning: Statistical outliers were detected. Consider re-running this
      benchmark on a quiet system without any interferences from other programs.
      It might help to use the '--warmup' or '--prepare' options.

hyperfine 发现测试的时候，有些数据与别的明显不在一个等级。所以她警告你并且建议
你在系统闲的时候重跑。

#### 初次测量很慢

    20:21 jyi-station ~/tmp/bgifile
    0 hyperfine 'cat test19.c'
    Benchmark 1: cat test19.c
      Time (mean ± σ):      34.3 ms ±  14.1 ms    [User: 2.2 ms, System: 31.8 ms]
      Range (min … max):    30.4 ms … 105.4 ms    28 runs

      Warning: The first benchmarking run for this command was significantly slower
      than the rest (105.4 ms). This could be caused by (filesystem) caches that
      were not filled until after the first run. You should consider using the
      '--warmup' option to fill those caches before the actual benchmark.
      Alternatively, use the '--prepare' option to clear the caches before each
      timing run.

这次 hyperfine 不仅发现数据异常，还发现是第一次跑的时候数据异常。于是她猜测是
某种神秘的缓存系统起了作用，并且建议你用 `--warmup` 参数或 `--prepare` 参数来
消除缓存的影响。

#### 程序跑得很快

    20:21 jyi-station ~/tmp/bgifile
    0 hyperfine 'cat test1.c'
    Benchmark 1: cat test1.c
      Time (mean ± σ):       0.9 ms ±   0.1 ms    [User: 0.7 ms, System: 0.4 ms]
      Range (min … max):     0.7 ms …   1.3 ms    1340 runs

      Warning: Command took less than 5 ms to complete. Note that the results
      might be inaccurate because hyperfine can not calibrate the shell startup
      time much more precise than this limit. You can try to use the
      `-N`/`--shell=none` option to disable the shell completely.

这次，hyperfine 发现程序跑得很快，误差会比较大，并且建议你用 `-N` 参数来直接运行程序，
绕过启动 shell 的步骤。

### 额外的功能

除此之外，hyperfine 还有一些别的功能，比如参数化测试之类的东西。不过我感觉要参
数化的话与其用这一坨命令行参数，不如去写一个小小脚本……所以我没用过。如果有人感
兴趣的话可以试试。

改变输出格式以便与其他软件协作
------------------------------

hyperfine 的命令行界面很好看，有进度条还有颜色。在除命令行之外的地方，她也做得
很好。比如，hyperfine 可以直接用 `--export-markdown` 参数生成 markdown 表格，
接着你就可以直接把结果插进 README 里面。她还可以导出 json 格式的测试结果，方便
之后再用脚本处理，做些可视化什么的（hyperfine 的仓库就附带了许多可视化脚本，很
好玩）。

总结
----

测量程序性能的方式有很多。相比那些在函数调用上插桩（gprof）或读 PMC 寄存器
（perf）的东西来说，单纯的计时也许太简陋了一些。但是第一次参观 profiler，却并
不觉得震撼。因为我早已遇见，独属于我的 benchmarking tool。初遇你的那天起，齿轮
便开始转动，却无法阻止丧失的预感。尽管已经拥有了很多，但让我们再多加一个吧。
可以给我最后一个加速比吗？我不愿遗忘

