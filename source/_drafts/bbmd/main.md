# 预处理 markdown 的小工具

## 背景

我喜欢把帖子先在本地编辑好，再复制粘贴到 BBHust 上发表。因为可以用我最爱的编辑器和文本处理小工具。但是这样写图文混排的内容时很烦。想要发表图文混排的文章时，需要先复制粘贴一段文字，再复制粘贴一些图片，然后又复制粘贴一些文字……非常繁琐。这也是 **阻止我写东湖游记的直接原因** （不是因为懒，是因为 BBHust 太不好用了！）

所以，我觉得我需要一个小工具，来把 markdown 预处理一下。它应该先把写好的 markdown 文件里面所有图片提取出来，接着把图片上传到某个地方 X，然后把所有的链接给换成指向 X 中图片的链接。这样一来，我就只要把预处理之后的文件贴到 BBHust 的编辑区里，再点一下 “发布” 就可以发布帖子了。

最好还要能生成目录！

于是就有了这个小工具。这个小工具做的就是上面提到的工作。

## 依赖

* [imagemagick][im] 里的 `convert(1)` 命令
* `curl(1)`
* `perl(1)`
* `sh(1)`

[im]: https://imagemagick.org/

## 功能

* 替换图片链接
* 生成目录

## 局限性

* 只能在 Linux 上使用（BSD 也不可以）
* 没有完整实现 markdown 语法，而是用了很多 tricky 的正则表达式
* 只是能用而已……也许也不一定能用

## 使用方法

1. 把下面的代码复制下来，保存成 `bbmd.pl`。
2. 假设你的 markdown 文件叫 `XXX.md`，运行 `perl bbmd.pl XXX.md`。
3. 然后程序会在标准输出流输出预处理过后的 markdown 文本。之后是接着连别的小工具还是直接复制粘贴到编辑区发布……就随便了

一个典型的命令：

```plain
perl bbmd.pl XXX.md | xclip -selection clipboard
```

将 `XXX.md` 预处理之后直接复制到剪贴板。然后用浏览器粘贴就好了。

要是 BBHust 有终端版就好了，最好能直接 `perl bbmd.pl XXX.md | xclip -selection clipboard | submit` 这样，一键发布……

## 代码

```perl
#!/usr/bin/env perl

use v5.12;
use utf8;
use Encode qw/decode_utf8/;
binmode STDOUT, ':encoding(utf8)';

sub process_image
{
	$_ = shift;
    my $filename;
    my $uuid = `tr -d '[[:space:]]' < /proc/sys/kernel/random/uuid`;
	if (/\.gif$/) {
        $filename = "$uuid.gif";
	} elsif (/\.png$/) {
        $filename = "$uuid.png";
    } else {
        $filename = "$uuid.jpg";
	}
    system 'convert', $_, "/tmp/$filename";
    system 'curl', '-F', "path=@/tmp/$filename", 'http://110.41.5.30:6788/upload?path=/';
    unlink "/tmp/$filename";
    "http://110.41.5.30:6788/$filename"
}

my @lines = map { decode_utf8 $_ } (<>);

my @title_count;
say "# 目录";
for (@lines) {
    next if /^```/ ... /^```/;
    if (/^(#+)\s*(.*?)\s*$/) {
        my ($level, $title) = (length($1), $2);
        my $indent = "  " x $level;
        my $url = $title;
        $url =~ s/[^_[:^punct:]]//g;
        $url =~ s/[[:space:]]/-/g;
        $url = lc $url;
        @title_count = splice @title_count, 0, $level;
        $title_count[$level - 1] += 1;
        my $index = join ".", @title_count;
        say "$indent+ $index [$title](#$url)";
    }
}

say "";

for my $line (@lines) {
    if ($line =~ /^```/ ... $line =~ /^```/) {
        print $line;
    } else {
        for ($line =~ /!\[[^\]]*\]\([^)]*\)/g) {
            my ($mark, $desc, $file) = /(!\[([^\]]*)\]\(([^)]*)\))/;
            $file = process_image $file;
            $line =~ s/\Q$mark\E/![]($file)/;
        }
        print $line;
    }
}
```
