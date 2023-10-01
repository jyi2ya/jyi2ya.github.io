---
title: urxvt 跑得比 alacritty 还快，为什么呢？
date: 2023-10-01 17:48:39
tags:
---

# urxvt 跑得比 alacritty 还快，为什么呢？

## 答案

答案是 urxvt 并没有老老实实地绘制其内程序输出的每一个字符，而是通过一些非常取巧的方法，减少了屏幕渲染的内容数量。

具体来说，是用了以下两个优化：

* jump scroll：如果短时间内需要渲染很多行，那么 urxvt 仅会在收到的行能充满一屏时尝试刷新。
* skip scroll：在 jump scroll 的基础上，限制刷新率为 60 Hz。

开启这两个优化之后，urxvt 收到的很多内容实际上都被直接扔进历史记录里了，根本没在屏幕上出现过。同时，因为人的眼睛是非常低速的设备，所以即使这些内容没有在屏幕上出现，也不会影响使用体验。

如果禁用掉这些小优化，urxvt 的速度大概仅是 alacritty 的 1/2 到 1/3。

## alacritty 与 urxvt 的简介

urxvt 本身是个二十多年前的老东西，使用了很多奇怪的 X 特性。配置文件和 xterm 一样非常奇怪，可能是 Xorg 给世界留下的遗产之一……使用 C 和 C++ 编写，用 Perl 扩展。rxvt 的可扩展性很强，对标准支持也很好，各种 corner case 处理相对比较完善。

alacritty 是个很新的项目，号称要成为最快的终端。使用超级炒作语言 rust 开发，并且实现了 GPU 加速。他们一度声称自己是 “Fastest Terminal Emulator in Existence（现存最快终端）”。但是在 2020 年末的 [一次提交][cm] 中不知道为什么他们换了说法，甚至连大家炒作时最爱的 “Blazing Fast” 也干没了。可能是开发者开发地表最速终端的梦想在现实里撞车了。非常快乐，大家快去围观。总之，相比项目早期的自述，现在的自述温和了很多。

[cm]: https://github.com/alacritty/alacritty/commit/3d7b16d4b0d867268c315f421904f3a2dc81a72d

两个都是非常好的终端。我之前是在 Windows 下用 alacritty，在 Linux 下用 urxvt。

## 为什么需要关注终端速度

……其实意义也不是很大，因为大家在输出内容太长的时候都会 `| less` 一下，用 pager 分页来看，终端速度对使用体验的影响很小。

但是既然速度是个能比的项目，那总会有人抱着一种宝可梦对决的心态来研究两个终端谁快谁慢，这也促进了这篇水帖的诞生！

## urxvt 的小优化相关代码

摘自 urxvt 代码仓库 `src/command.C` 的第 2267 行。

    if (ecb_unlikely (ch == C0_LF || str >= eol))
      {
        if (ch == C0_LF)
          nlines++;

        refresh_count++;

        if (!option (Opt_jumpScroll) || refresh_count >= nrow - 1)
          {
            refresh_count = 0;

            if (!option (Opt_skipScroll) || ev_time () > ev::now () + 1. / 60.)
              {
                refreshnow = true;
                ch = NOCHAR;
                break;
              }
          }

大概就是它用一堆错综复杂的条件变量实现了上面提到的小优化，整段代码唯一的注释的是这样的：

    /*
     * If there have been a lot of new lines, then update the screen
     * What the heck we'll cheat and only refresh less than every page-full.
     * if skipScroll is enabled.
     */

摆了。这啥 GNU-style 的神秘老代码看得我头疼……
