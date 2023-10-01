#ifndef CANVAS_H_
#define CANVAS_H_

#include <stdio.h>
#include <stdlib.h>

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

typedef struct canvas {
	int width;
	int height;
	void *buf;
} canvas;

int canvas_init(canvas *p, int height, int width)
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

void canvas_draw(canvas p, int y, int x)
{
	((unsigned char (*)[p.width])p.buf)[y][x] = 1;
}

void canvas_erase(canvas p, int y, int x)
{
	((unsigned char (*)[p.width])p.buf)[y][x] = 0;
}

int canvas_test(canvas p, int y, int x)
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
					id = (id << 1) | canvas_test(p, i - k, j + l);
			if (canvas_test(p, i - 4, j))
				id += 64;
			if (canvas_test(p, i - 4, j + 1))
				id += 128;
			printf("%s", magic_table[id]);
		}
		putchar('\n');
	}
}
#endif /* CANVAS_H_ */

#include <string.h>

int main(void)
{
	int col, line, colors, width;
	int ch1;
	int i, j;
#include "a.xpm"

	canvas p;
	sscanf(a[0], "%d%d%d%d", &col, &line, &colors, &width);
	if (colors > 2 || width > 1) {
		puts("Syntax error");
		return 1;
	}
	ch1 = a[1][0];
	canvas_init(&p, line, col);
	for (j = 0; j < line; ++j)
		for (i = 0; i < col; ++i) {
			if (a[j + 3][i] == ch1)
				canvas_draw(p, line - j - 1, i);
			else
				canvas_erase(p, line - j - 1, i);
		}
	canvas_print(p);
	canvas_clear(p);
	return 0;
}
