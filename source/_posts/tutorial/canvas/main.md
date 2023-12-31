---
title: 用盲文字符来在终端画黑白图像
date: 2023-10-01 17:48:39
tags:
---

# 用盲文字符来在终端画黑白图像

## 食用提示

如果这篇文章在您的设备上显示很多方框，或许是字体出了问题。请确保自己使用的字体可以正常显示盲文。

在我的设备上，无论怎么操作都无法使 urxvt （rxvt ， xterm ） 表现出我想要的样子。因此在不建议您进行实验时使用 urxvt （rxvt ， xterm ） 。

## 想法来源

有一天发现盲文就是一堆像素点，就想着用盲文文字在终端画图。

## 实现效果

![show1.png](https://cdn.luogu.com.cn/upload/image_hosting/lsp7f3e4.png)
![show2.png](https://cdn.luogu.com.cn/upload/image_hosting/1oy9pwhi.png)

## 分析

```plain
⠀⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏
⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟
⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯
⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿
⡀⡁⡂⡃⡄⡅⡆⡇⡈⡉⡊⡋⡌⡍⡎⡏
⡐⡑⡒⡓⡔⡕⡖⡗⡘⡙⡚⡛⡜⡝⡞⡟
⡠⡡⡢⡣⡤⡥⡦⡧⡨⡩⡪⡫⡬⡭⡮⡯
⡰⡱⡲⡳⡴⡵⡶⡷⡸⡹⡺⡻⡼⡽⡾⡿
⢀⢁⢂⢃⢄⢅⢆⢇⢈⢉⢊⢋⢌⢍⢎⢏
⢐⢑⢒⢓⢔⢕⢖⢗⢘⢙⢚⢛⢜⢝⢞⢟
⢠⢡⢢⢣⢤⢥⢦⢧⢨⢩⢪⢫⢬⢭⢮⢯
⢰⢱⢲⢳⢴⢵⢶⢷⢸⢹⢺⢻⢼⢽⢾⢿
⣀⣁⣂⣃⣄⣅⣆⣇⣈⣉⣊⣋⣌⣍⣎⣏
⣐⣑⣒⣓⣔⣕⣖⣗⣘⣙⣚⣛⣜⣝⣞⣟
⣠⣡⣢⣣⣤⣥⣦⣧⣨⣩⣪⣫⣬⣭⣮⣯
⣰⣱⣲⣳⣴⣵⣶⣷⣸⣹⣺⣻⣼⣽⣾⣿
```

这是 UTF-8 中的盲文字符。共有 256 个。每个盲文字符都由数个点组成。点最多的盲文字符（右下角）有 8 个点，它看起来像个实心黑框框；点最少的盲文字符有 0 个点（左上角），虽然它看上去像个空格，但它真的和空格不是一个东西。

稍微观察可以发现，一个盲文字符可以当成 4x2 的小形位图使用，如果能够良好组织，使盲文字符按某种方式排列，就可以拼出大一些的位图。

不同的 4x2 位图共有 2^8 = 256 个，而不同的盲文字符正好也有 256 个。这意味着盲文字符和 4x2 的位图之间有着一一对应的关系。为了方便盲文与位图的与相转化，我们需要设计一种编码方案。

上面列出的表显然是经过良好组织的，可以发现盲文字符的排布很有规律。找规律的过程略去不提，这里仅说编码方案。经过以下操作后，可以保证盲文字符和其对应的 4x2 位图有相同的编号：

盲文：将上表中的盲文从上到下，从左到右依次编号 0 到 255 。

位图：考虑搞一张权值表：

```plain
1  8
2  16
4  32
64 128
```

将表中所有对应位图黑色位置的权值加起来，得到的和即为位图的编号。

例如，字符 “⢫” ，其编号为 171 ，其位图为：

```plain
1 1
1 0
0 1
0 1
```

和权值表 py 后得到 1 + 8 + 2 + 32 + 128 = 171 ，和期待结果一致。

使用这个方法，可以将 4x2 的小位图和它所对应的盲文字符的编号对应起来。于是，我们就可以在终端画图了。

## 实现

首先对盲文字符打表：

```c
const char *magic_table[] = {
	"⠀", "⠁", "⠂", "⠃", "⠄", "⠅", "⠆", "⠇", "⠈", "⠉", "⠊", "⠋", "⠌", "⠍", "⠎", "⠏",
	"⠐", "⠑", "⠒", "⠓", "⠔", "⠕", "⠖", "⠗", "⠘", "⠙", "⠚", "⠛", "⠜", "⠝", "⠞", "⠟",
	"⠠", "⠡", "⠢", "⠣", "⠤", "⠥", "⠦", "⠧", "⠨", "⠩", "⠪", "⠫", "⠬", "⠭", "⠮", "⠯",
	"⠰", "⠱", "⠲", "⠳", "⠴", "⠵", "⠶", "⠷", "⠸", "⠹", "⠺", "⠻", "⠼", "⠽", "⠾", "⠿",

	"⡀", "⡁", "⡂", "⡃", "⡄", "⡅", "⡆", "⡇", "⡈", "⡉", "⡊", "⡋", "⡌", "⡍", "⡎", "⡏",
	"⡐", "⡑", "⡒", "⡓", "⡔", "⡕", "⡖", "⡗", "⡘", "⡙", "⡚", "⡛", "⡜", "⡝", "⡞", "⡟",
	"⡠", "⡡", "⡢", "⡣", "⡤", "⡥", "⡦", "⡧", "⡨", "⡩", "⡪", "⡫", "⡬", "⡭", "⡮", "⡯",
	"⡰", "⡱", "⡲", "⡳", "⡴", "⡵", "⡶", "⡷", "⡸", "⡹", "⡺", "⡻", "⡼", "⡽", "⡾", "⡿",

	"⢀", "⢁", "⢂", "⢃", "⢄", "⢅", "⢆", "⢇", "⢈", "⢉", "⢊", "⢋", "⢌", "⢍", "⢎", "⢏",
	"⢐", "⢑", "⢒", "⢓", "⢔", "⢕", "⢖", "⢗", "⢘", "⢙", "⢚", "⢛", "⢜", "⢝", "⢞", "⢟",
	"⢠", "⢡", "⢢", "⢣", "⢤", "⢥", "⢦", "⢧", "⢨", "⢩", "⢪", "⢫", "⢬", "⢭", "⢮", "⢯",
	"⢰", "⢱", "⢲", "⢳", "⢴", "⢵", "⢶", "⢷", "⢸", "⢹", "⢺", "⢻", "⢼", "⢽", "⢾", "⢿",

	"⣀", "⣁", "⣂", "⣃", "⣄", "⣅", "⣆", "⣇", "⣈", "⣉", "⣊", "⣋", "⣌", "⣍", "⣎", "⣏",
	"⣐", "⣑", "⣒", "⣓", "⣔", "⣕", "⣖", "⣗", "⣘", "⣙", "⣚", "⣛", "⣜", "⣝", "⣞", "⣟",
	"⣠", "⣡", "⣢", "⣣", "⣤", "⣥", "⣦", "⣧", "⣨", "⣩", "⣪", "⣫", "⣬", "⣭", "⣮", "⣯",
	"⣰", "⣱", "⣲", "⣳", "⣴", "⣵", "⣶", "⣷", "⣸", "⣹", "⣺", "⣻", "⣼", "⣽", "⣾", "⣿"
};
```

接着实现 canvas 结构体。这里用 ``unsigned char`` 数组当成 ``bool`` 数组使用。日后优化时，可以用 bitmap 节省空间。

```c
typedef struct canvas {
	int width;
	int height;
	void *buf;
} canvas;

int canvas_init(canvas *p, int width, int height)
{
	width = ((width - 1) / 2 + 1) * 2;
	height = ((height - 1) / 4 + 1) * 4;
	p->width = width;
	p->height = height;
	p->buf = malloc(sizeof(unsigned char) * width * height);
	if (p->buf == NULL)
		return 1;
	return 0;
}

void canvas_clear(canvas p)
{
	free(p.buf);
}

```

实现画像素点和打印功能：
```c
void canvas_draw(canvas p, int x, int y)
{
	((unsigned char (*)[p.width])p.buf)[y][x] = 1;
}

void canvas_erase(canvas p, int x, int y)
{
	((unsigned char (*)[p.width])p.buf)[y][x] = 0;
}

int canvas_test(canvas p, int x, int y)
{
	return ((unsigned char (*)[p.width])p.buf)[y][x];
}

void canvas_print(canvas p)
{
	int i, j, k, l;
	for (i = p.height; i > 0; i -= 4) {
		for (j = 0; j < p.width; j += 2) {
			int id = 0;
			for (l = 1; l >= 0; --l)
				for (k = 3; k >= 1; --k)
					id = (id << 1) | canvas_test(p, j + l, i - k);
			if (canvas_test(p, j, i - 4))
				id += 64;
			if (canvas_test(p, j + 1, i - 4))
				id += 128;
			printf("%s", magic_table[id]);
		}
		putchar('\n');
	}
}
```

实现完成。以下是函数功能与参数说明：

```plain
int canvas_init(canvas *p, int width, int height); 将 p 初始化为宽 width 高 height 的画布
void canvas_clear(canvas p); 销毁画布 p
void canvas_draw(canvas p, int x, int y); 在 p 的 (x, y) 位置画上一个像素点
void canvas_erase(canvas p, int x, int y); 擦除 p 中 (x, y) 位置上的像素点
int canvas_test(canvas p, int x, int y); 返回 p 中 (x, y) 上是否已经画过
void canvas_print(canvas p); 打印 p
```

## 实现示例中的效果

用 ImageMagick 的 convert 命令将图片文件转为只有 2 种颜色的 xpm 文件，写个傻瓜 xpm 解析器，配合上面的代码简单处理即可得到示例中的效果。傻瓜解析器的代码见：[doxpm.c](https://www.luogu.org/paste/npaqkp89) 。

在本机上，实现示例效果的命令为：

```bash
$ convert -colors 2 sample.png a.xpm
$ gcc doxpm.c -o doxpm
$ ./doxpm
$ # 如果需要彩色的话：
$ ./doxpm | lolcat
```

## 完

代码仅被用来说明想法，并没有想写成一个可用的库。所以码风略快糙猛请多包涵。

感谢 zrz\_orz 同学教我在洛谷日报上投稿，并提出大量修改意见。
