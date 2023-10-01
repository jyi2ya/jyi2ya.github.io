---
title: 友链
date: 2023-10-01 17:48:39
tags:
---

# 友链

cyx 吃夜宵：https://yxchen.net/
hjx 喝喜酒：https://honeta.site/
zwd 朝闻道：https://vaaandark.top/
lxy 灵犀玉：https://ccviolett.github.io/
ljm 逻辑门：https://watari.xyz/
ljh 梁家河：https://www.newuser.top/
lg 蓝狗：https://ligen.life/
yxt 游戏厅：https://blog.just-plain.fun/
lyt 老樱桃：https://i.lyt.moe/
dekrt 不知道谁：https://dekrt.cn/

用来方便在博客园上传链接的便利脚本：
```bash
IFS="
"
for i in $(awk -F： '/：.*\/$/ { print $1" "$2"\n"$2 }' a.md); do
	echo "$i"
	echo "$i" | clip
	read _
done
```
