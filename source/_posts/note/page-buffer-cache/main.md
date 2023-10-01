---
title: Page/Buffer Cache 是什么？
date: 2023-10-01 17:48:39
tags:
---

Page/Buffer Cache 是什么？

# 简介

## Page Cache

+ 试图最小化磁盘 IO

+ 本质上是一堆内存页面

> 内存页面（Page）：一小段连续内存，是操作系统管理内存的最小单位

+ 包含了很多最近访问过的**文件的内容**
    - 意思是不包括 inode、目录等东西！

> 对于 inode 和目录来说，他们的 page cache 的类似物分别叫做 inode cache 和 directory entry cache。其中 directory entry cache 又由 inode cache 组织而来。

+ 用途广泛，用于 file-backed mmap、buffered io，甚至 swap。

+ 需要文件系统支持

## Buffer Cache

+ 试图最小化磁盘 IO

+ 本质上是内存里的一堆块

> 块：操作系统对磁盘操作的基本单位，在 Linux 中要求大小为 2 的整数次幂，且比 sector 大，比 page 小

> sector：磁盘读写数据的最小单位，由磁盘决定。

+ 包含了最近访问过的块

+ 用途不多，基本上只用来加速块设备

> 块设备（Block Device）：支持随机读写的设备。典型的比如磁盘。

+ 不需要文件系统

> 比如，文件系统的 superblock 一般会躺在 buffer cache 里面

## 两者的关系

可以参考下图（从 [usenix](https://www.usenix.org/legacy/publications/library/proceedings/usenix01/full_papers/kroeger/kroeger_html/node8.html) 上面偷的）：

![overview.png](overview.png)

> **考古时间**
>
> 为什么 page cache 是一堆内存页面，而 buffer cache 是一堆块呢？
>
> 最开始 Linux 上面只有 buffer cache，此时 buffer cache 仅仅用于加速 buffered io 操作，向上与 read/write 交互，向下与磁盘交互。所以 buffer cache 设计成一堆块是很合适的。
>
> page cache 则是为了支持 mmap，在 2.2 版本中引入的。由于它和内存关系比较紧密，所以设计成一堆内存页的形式。不过此时 buffered io 仍然只与 buffer cache 交互，不与 page cache 交互。要等两个 cache 合并之后才会出现大家所熟知的「调用 read/write 之后会写 page cache，过一会儿由操作系统把脏页写回磁盘」这种模式。

# 一些比较复杂的东西

## page cache 和 buffer cache 其实是一个东西？

虽然逻辑上还是可以将他们分为两个东西，但是其实两者只是同一套数据的不同组织方式。

```plain
+---------------------------------------+
| page                                  |
|+-------+ +--------+ +--------++------+|
||buffer1| | buffer2| |buffer3 ||buffer||
||       | |        | |        ||  4   ||
|+-------+ +--------+ +--------++------+|
+---------------------------------------+
```

（没找到合适的图所以画了个）

每个 buffer 可以通过 `buffer_head` 结构体中的 `b_page` 字段获取自己对应的 page，同时 page 也可以通过 `page` 结构体中的 `buffers` 字段来得到自己所拥有的一组 buffer。

## 既然 page cache 与 buffer cache 合并了……

那如果我在 A 进程对 `/dev/sda1` 上的一个文件 F 的一个连续区域做 shared mmap，再在 B 进程对 `/dev/sda` 本身做 shared mmap，两个进程映射的实际磁盘空间一致，那 A 进程与 B 进程能映射到同一个 page 吗？

答案是不行 :3。因为 A 进程的 page 是文件系统给的，而 B 进程得到的东西更像是一堆 buffer 组合成的 page。

此时数据组织大概是这样的：

```plain
+---------------------------------------+  +---------------------------------------+
| A page                                |  | B page                                |
|                                       |  |                                       |
|                                       |  |                                       |
|    o         o          o           o |  |   o       o          o         o      |
|    |         |          |           | |  |   |       |          |         |      |
+----|---------|----------|-----------|-+  +---|-------+----------+---------+------+
     v         v          v           v        |       |          |         |
 +-------+ +--------+ +--------+   +------+    |       |          |         |
`|buffer1| | buffer2| |buffer3 |   |buffer|    |       |          |         |
 |       | |        | |        |   |  4   |    |       |          |         |
 +---^---+ +---^----+ +---^----+   +--^---+    |       |          |         |
     +---------+----------|-----------+--------+       |          |         |
               +----------|-----------+----------------+          |         |
                          +-----------+---------------------------+         |
                                      +---------------------------+---------+

```

# 一些好玩的接口

## 来点文件预读

除了缓存已经读过/写过的数据之外，猜测程序要读什么从而提前把它们读进 page cache 中，也能加快程序！

+ posix_fadvise(2): `POSIX_FADV_SEQUENTIAL` 参数可以暗示内核自己将要顺序读文件。
+ madvise(2): `MADV_SEQUENTIAL` 参数可以暗示内核自己将顺序使用一些内存，配合 `mmap(2)` 使用。

+ readahead(2)：简单直接地告诉内核，偷偷多读一些东西（感觉这是个没用的屑调用……）。

## 掉落擦车

可以通过 `/proc/sys/vm/drop_caches` 来告知内核扔掉一些 cache 数据。可以通过 `echo X > /proc/sys/vm/drop_caches` 来使用。其中 X 的取值可以为 1, 2 或 3。当 X 为 1 时意思是让内核扔掉所有 page cache 里面的数据。2 和 3 代表什么，不知道 :3。

在测试一些 io-bounded 的程序时，为了防止 page cache 对测量结果造成干扰，可以在测试前运行一下。

# 未解之谜

发现自己还是不太看得懂 `free(1)`。

```plain
               total        used        free      shared  buff/cache   available
Mem:            13Gi       4.4Gi       3.2Gi       135Mi       6.5Gi       9.1Gi
```
