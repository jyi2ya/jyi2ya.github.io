为 markdown 写的文章生成目录，使其在博客园上可用。

# 完整代码

```perl
use v5.12;
use utf8;
use open ':utf8';
use open ':std', ':utf8';

my @subtitle_number;
say "# 目录";
while (<>) {
    next if /^```/ ... /^```/;
    if (/^(#+)\s*(.*?)\s*$/) {
        my ($level, $title) = (length($1), $2);

        my $indent = "  " x $level;

        my $id = $title;
        $id =~ s/[^_[:^punct:]]//g;
        $id =~ s/[[:space:]]/-/g;
        $id = lc $id;

        @subtitle_number = splice @subtitle_number, 0, $level;
        $subtitle_number[$level - 1] += 1;
        my $subtitle_number = join ".", @subtitle_number;

        say "$indent+ $subtitle_number [$title](#$id)";
    }
}
say "";
```

这是一个 Perl 脚本，从 stdin 或者参数中读取文章，输出一份 markdown 代码，是文章的目录。可以直接复制粘贴使用，也可以和其他工具集成使用。

# 使用示例

使用这样的命令：

```sh
$ perl toc.pl main.md
```

可以得到这样的结果：

```plain
# 目录
  + 1 [完整代码](#完整代码)
  + 2 [使用示例](#使用示例)
  + 3 [原理](#原理)
    + 3.1 [HTML 的链接语法](#html-的链接语法)
    + 3.2 [markdown 列表缩进](#markdown-列表缩进)
  + 4 [代码详解](#代码详解)
    + 4.1 [使用「现代」Perl](#使用现代perl)
    + 4.2 [支持 utf8 编码](#支持-utf8-编码)
    + 4.3 [主循环](#主循环)
      + 4.3.1 [跳过 markdown 的代码片段](#跳过-markdown-的代码片段)
      + 4.3.2 [匹配标题](#匹配标题)
      + 4.3.3 [设置缩进](#设置缩进)
      + 4.3.4 [从标题名字中获得其 id](#从标题名字中获得其-id)
      + 4.3.5 [获取标题的编号](#获取标题的编号)

```

# 原理

## HTML 的链接语法

在大多数网页上，markdown 的链接语法会被编译成 HTML 的 `<a>` 标签。通常 `<a>` 标签会有 `href` 属性，内容是点击标签时跳转的目的地址。

有些页内元素带有 `id` 属性，比如这个例子：

```html
<h3 id="interactive-shell">interactive shell</h3>
```

在这个例子里 `<h3>` 标签有 `id` 属性，值是 `interactive-shell`。这个值同样可以用作 `<a>` 标签的目的地址。

当目的地址是页内元素的 `id` 时，点击 `<a>` 标签时便会跳转到该元素的位置。博客园给每个标题都自动分配了一个 `id`，利用这几点，就可以实现「点击目录项目跳转到对应章节」的功能。

## markdown 列表缩进

在 markdown 中，列表以 `+` `-` 和 `*` 开头。如果这些符号前面有空白字符，那么这些空白字符会被当成缩进，最终会体现在列表展示结果上，缩进越多的列表项目展示时会越靠右，缩进相同的列表项目会左对齐。利用这一点，可以实现目录的层次结构。

# 代码详解

## 使用「现代」Perl

```perl
use v5.12;
```

Perl 是个老古董语言，为了保持兼容性，有许多好玩/有用的特性默认没有打开。不过我们可以使用 `use vX.YY` 的 pragma 来指定自己想使用的 Perl 的版本号，从而开启这些好玩的特性。

## 支持 utf8 编码

```perl
use utf8;
use open ':utf8';
use open ':std', ':utf8';
```

同上，因为 Perl 是个老古董语言，所以默认全世界都用 ASCII 编码。我们要开启它对 utf8 的支持。

这里第一行是让 Perl 用 utf8 的方式来解释这份源代码（有点像 python2 里面的 `# -*- coding: utf-8 -*-` 的 pragma）。

第二行是让 Perl 读所有文件时，读后解码 utf8；写所有文件时，写前编码 utf8。Perl 中为了方便数据处理，存在 IO Layer 的概念。layer 可以看做数据的转换器，数据在进行输入/输出时，会经过这些 layer 逐层处理。常用的 layer 有 `:crlf`（读时将 `CR-LF` 序列转换成 `CR`，写时反过来，用来对付 Windows 系统）和 `:encoding`（用来编解码文件）。还有些邪恶的 layer 可以实现自动压缩解压、base16 编码等功能。所以有时遇到输出到 stdout 和输出到文件中，内容不一致的情况，可以检查一下是不是用的 layer 不同造成的。

第三行是在设置 stdio 的 layer。因为 stdio 在 Perl 程序运行前就已经打开了，所以需要单独设置一下。

## 主循环

就是那个巨大的 `while` 循环。它每次会从输入中读取一行数据并放到 `$_` 里面，直到读到文件结束。

```perl
while (<>) {
```

可以发现我们并没有处理命令行参数，这是因为 `<>` 这个操作符会替我们完成这项工作。`<>` 操作符的意思是，如果有命令行参数，那么就把命令行参数当做文件名打开文件，并且将文件内容作为输入；否则就把 stdin 作为输入。每调用一次 `<>` 操作符会读取一行，返回这一行的内容。如果没有变量来接收 `<>` 操作符的返回值，那么 `<>` 操作符会把返回值存在特殊变量 `$_` 中。

### 跳过 markdown 的代码片段

```perl
    next if /^```/ ... /^```/;
```

这一行用来跳过 markdown 的代码片断。是一种被称为 flip-flop 的语法。上面代码的意思是，「如果在两个代码标记之间，那么执行 `next` 语句」。大概和下面的东西等价：

```perl
# 这句在循环外头
my $in_codeblock = 0;

# 这下面的在循环里头
if ($in_codeblock) {
    next;
}

if (/^```/ && $in_codeblock == 0) {
    $in_codeblock = 1;
}

if (/^```/ && $in_codeblock == 1) {
    $in_codeblock = 0;
}
```

flip-flop 是一种很方便的语法，可以让人少写很多代码。最重要的是不需要对那一堆烦人的标志变量命名了。

### 匹配标题

用一个正则表达式来匹配标题并且获得需要的信息：

```perl
    if (/^(#+)\s*(.*?)\s*$/) {
        my ($level, $title) = (length($1), $2);
```

这个意思是，如果遇到「开头是若干个 `#`，中间有一堆字符」这种模式，就认为匹配到标题了。`$level` 和 `$title` 分别是标题的层级和名称。因为正则表达式在 Perl 中用的特别多，所以直接做进语言里面去了，可以随手写，不需要另外调库。

### 设置缩进

```perl
        my $indent = "  " x $level;
```

`$level` 总是个整数。这里用字符串重复操作符 `x`，来获得与 `$level` 成正比的缩进长度。

### 从标题名字中获得其 id

```perl
        my $id = $title;
        $id =~ s/[^_[:^punct:]]//g;
        $id =~ s/[[:space:]]/-/g;
        $id = lc $id;
```

博客园会根据标题名称来设置其 HTML 标签的 id。有人托梦告诉我说，id 就是标题去掉所有标点符号但是保留下划线 `_`，把空白字符换成连字符 `-`，并且把所有字母变为小写之后的结果。所以用正则表达式写了一个。

### 获取标题的编号

```perl
        @subtitle_number = splice @subtitle_number, 0, $level;
        $subtitle_number[$level - 1] += 1;
        my $subtitle_number = join ".", @subtitle_number;
```

生成的目录里面会有类似 `X.Y.Z.W` 这样的标题编号。这一部分代码就用来处理标题编号的生成问题。懒得写了……
