---
title: markdown 中使用图片但是不使用图床
date: 2023-10-01 17:48:39
tags:
---

# markdown 中使用图片但是不使用图床

起因是写博客要插入图片，但是懒得上传图片到图床。经过一番尝试后发现可以把图片 base64 编码后放进 markdown 语法中本应该放图片 url 的位置，直接将图片插进 markdown 文件里。

显然我们需要找出 markdown 中的图片。为了减少图片大小，还需要缩放和压缩。为了偷懒想找找有没有相关的项目可以实现功能。只找到了 [markdownImage](https://gitee.com/hujingnb/markdownImage)。但是这个图片压缩好像是调用一些网站的 api 来完成相关功能的，还有免费次数限制，并且并不提供图片缩放功能。感觉和需求出入有点大……

最后我写了个便利脚本来完成这项任务，需要机器上安装了 imagemagick、base64 和 tr。

（这个脚本问题还是比较多，比如没有区分代码块里格式类似图片链接的部分和真正的图片链接，某些情况，比如 markdown 教程估计会锅掉。但是总之还是能用的嘛）

会从标准输入和命令行文件中读取内容，处理后输出到标准输出。（在后面接一个 clip 剪贴板程序就可以直接准备发布到博客园啦）

```perl
#!/usr/bin/env perl

use v5.12;

sub process_image
{
	$_ = shift;
	if (/\.gif$/) {
		"data:image/gif;base64," .
		qx {
		convert -fuzz 15% -layers Optimize \Q$_\E - | base64 | tr -d '\n'
		}
	} else {
		"data:image/jpeg;base64," .
		qx {
		convert -resize \Q1280x960>\E -strip -quality 75% \Q$_\E jpeg:- | base64 | tr -d '\n'
		}
	}
}

while (defined(my $line = <>)) {
	for ($line =~ /!\[[^\]]*\]\([^)]*\)/g) {
		my ($mark, $desc, $file) = /(!\[([^\]]*)\]\(([^)]*)\))/;
		$file = process_image $file;
		$line =~ s/\Q$mark\E/![$desc]($file)/;
	}
	print $line;
}
```
