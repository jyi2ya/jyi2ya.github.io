---
title: CPC 2023 简明总结
date: 2023-10-01 17:48:39
tags:
---

# CPC 2023 简明总结

记录我印象里的 CPC 2023 的大概流程。想着 BBHust 上面的大家不一定都对并行编程很感兴趣，所以省略了大部分纠结与调试的故事，只留下了好玩的部分。

比赛要和其他选手比拼技术，所以算是 “竞技”。因为经常睡不好，考验身体素质，所以也是某种很新的 “体育”。四舍五入 CPC 也是竞技体育。

## 比赛简介

CPC 是 “国产 CPU 并行应用挑战赛” 的简称。赛制大概是，主办方给出一个程序，让选手在特定架构的机器上优化，最后谁的程序跑得快谁就赢了。

今年主办方给的机器是一台名叫 “神威·问海一号” 的超级计算机，它是 “神威·太湖之光” 的后继者，国产超级计算机的明星之一。关于超级计算机，大家简单地理解成 “在上面用某些华丽的技巧编程，写出来的程序可以跑得很快” 的奇特电脑就可以了。

遗憾地是，这个国产超级计算机的硬件设计有很多不足。整个问海一号的架构被我们称为 “硬件设计友好型架构” —— 硬件工程师设计时自己怎么偷懒怎么来，给软件工程师（嗨呀，这是我）造成了诸多限制，使得我们在这个架构上编程难度颇大。同时，问海一号的现象还比较反常识，许多指令的加速效果远远不如它们在 x86 上的等价物。

我愿称其为 **超算原神** 。

## 初赛

初赛的任务是优化一个大程序中的小部分，和我们平时做的东西挺像。

我负责的部分是数据划分。就是把一个巨大的矩阵，切成很多个小小矩阵，让我的队友们写的代码来做后续处理。它只要满足划分出的任务量尽可能负载均衡、队友使用我的划分结果足够方便、缓存十分友好、能够适应不同的数据规模大小、不带来额外的数据转换开销等等条件的基础上跑得足够快就好了。最后我就写了这么一个东西。

> “我什么都做得到！” —— 我，于七边形活动室，写完这部分代码之后

初赛的代码全是用 C 和 C++ 写的，很友好。我能很轻松地把一部分模块抽出来放到 x86 的架构上优化，再把优化后的代码给缝到原来的项目里面。这样原来自己熟悉的 perf 等等工具链就都可以用了。相比性能分析工具都要自己写的神威架构，x86 简直是天堂。

比赛后期队友 P 同学发挥奇思妙想，参考 OpenGL 的双缓冲技术，设计了一组面向 DMA 操作的双缓冲数据结构与 API，成功地将数据传输的开销掩盖在了计算下面，获得了巨量的性能提升。堪称最有想象力的一集。

还有个非常欢乐的事情是，神威架构上的 512 位浮点 SIMD 加速比仅有 1.8x 左右。经过我的仔细思考，我觉得可能神威在实现 SIMD 的时候就是单纯地给前端解码加了条指令，后端实际还是逐个逐个元素计算的……相当于仅省略了解码开销。不知道是不是真的但是很符合我对神威的想像。

很遗憾，初赛到现在已经过了两个多月了，期间经历了期末考试、构造动画片电视台、升级重构 bot、研究跨平台包管理器、无聊的并行计算课、学 vscode、学习怎么逛街、配置全新网络文件系统、研究 AMD ROCm、打工以及最终暑假结束了也没找到女朋友等诸多好玩的事情，具体初赛时发生了什么我已经几乎忘光了（其实暑假做了什么我也几乎忘掉了，这个列表是参考 bash history 和 bot 聊天记录写出来的），只留下了印象最深的一点点事情。也许应该发展一下写日记的习惯……或者用 bot 代劳写日记的习惯。

## 决赛

决赛的任务是优化一个巨大的 Fortran 项目，和我们平时做的东西一点也不像。

决赛刚刚开始的几天我恰好开始实习，就拿到了一份任务列表。拿着做了两三天发现自己要是想跟上任务表的进度，每天都会很累，回到酒店后根本就没啥精力和心情来搓 CPC 的傻逼 Fortran 代码。于是研究了一下换人的可能性。但是就在换人讨论的后一天上班时，无意间发现自己拿到的好像是一个月量的任务表，但是自己把它当成一周的量来做了。本来还以为是什么万恶扒皮公司压榨实习生的剧情，结果现在直接做上了做一休三的悠闲生活。因为突然多出了不少空闲时间，我就接着打 CPC 比赛了。

实习公司的网络管制很严格，要和它的防火墙斗智斗勇才能成功打洞连上比赛的集群。比赛开打的前几天，网络相关的知识猛增……

决赛集齐了 Fortran、神威、大项目 等多种我们的短板，所以游戏体验并不良好。大量时间被花在了无意义的代码调试上，欢乐的事情很少很少……每天最快乐的事情就是骂骂神威。

之前大家还是一直认为 “Machine is always right” 的，但是在神威上编了几个月程，遇到了一堆问题后，最后几天调试代码我都有点开始相信风水了。总之，在神威机器上编程的时候，遇到问题除了排查自己的代码中出现的问题外，还要排查编译器本身的选项、从核同步性等一系列本应由编译器开发人员和硬件设计人员给我们弄好的问题。烦烦烦。

## 决赛现场

决赛的前一天半夜，队友突然发现比赛集群上的环境疑似被主办方重置了，导致大家的 git 被回滚到了旧版本，某些功能没法用。作为成熟稳重可靠万能的超算队前辈（嗨呀，突然发现参赛小队里只有一个勉强能算后辈，怎么回事呢），我就连夜给它重新装了一个。

现场照片：

决赛比较无聊，到后面有点垃圾时间的意味。于是……

> 原神，启动！ —— 某不知名 P 同学
>
> 星铁，启动！ —— 某不知名 H 同学

以及畅想讨论怎么把比赛现场的 NVidia 的计算卡偷走的时候及时发现后面路过的（名义上的）我们队的指导老师。

## 神秘收获

感觉这次算是第一次遇到自己没法单刷的比赛，确定了自己并不是什么都做得到。之前因为比赛的工程量都比较小，想了想反正可以单刷就几乎没管过团队合作的事情。但是这次比赛拿到题时就知道这不太是一个人可以搞定的东西，再加上队长和队友都很积极，于是点了一些协作方面的技能。通过交流让四个人达成共识，并一起完成同一件事，感觉是某种很新的体验。
