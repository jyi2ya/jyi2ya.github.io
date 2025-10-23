Tue Oct 14 14:35:59 CST 2025

需要一个 COW 的沙盒用来分析软件行为，拿 proot 看看

希望能有一个类似 cow 的东西……读的时候读我的 rootfs，写的时候写到一个特定的文件夹里。

proot 疑似不行？官网没说

好像有一大家子 xxroot，proot chroot fakeroot fakechroot dchroot schroot ……好多哦

dchroot 已经弃用了，推荐用 schroot

schroot 主要是 sbuild 在用，看了下代码 sbuild 支持 unshare 和 schroot 两种 chroot 模式。

> Note  that this tool is only useful for the schroot backend.  Debian buildds have switched to the unshare backend in 2024.
