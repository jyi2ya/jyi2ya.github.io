---
title: 从 zerotier 迁移到 headscale
date: 2024-02-25 19:28:48+08:00
tags:
---

## 前言

[zerotier][1.1] 是我正在用的虚拟局域网设施。它的主要特性就是能用 [UDP 打洞][1.2] 技术，在没有公网 IP 地址的情况下实现 [P2P][1.3] 连接。[tailscale][1.4] 是它的类似物。

今天从网上看到了一份 [评测][1.5] ，里面提到：

> * Tailscale: Download speed: 796.48 Mbps, Upload speed: 685.29 Mbps
> * ZeroTier: Download speed: 584.17 Mbps, Upload speed: 406.12 Mbps

看起来 tailscale 比 zerotier 快不少。于是决定把现有的 zerotier 网络迁移到 tailscale 上面去。

[1.1]: https://www.zerotier.com/
[1.2]: https://en.wikipedia.org/wiki/UDP_hole_punching
[1.3]: https://en.wikipedia.org/wiki/Peer-to-peer
[1.4]: https://tailscale.com/
[1.5]: https://www.e2encrypted.com/posts/tailscale-vs-zerotier-comprehensive-comparison/#tailscale-and-zerotier-performance

## 中继服务器 headscale 架设

想了想，现在的 zerotier 网络由于大陆没有中继服务器，打洞偶尔会非常不顺利。tailscale 和 zerotier 一样在大陆没有中继服务器，估计也会遇到一样的问题。最好的解决方案也许就是使用 tailscale 的开源实现，[headscale](https://github.com/juanfont/headscale) 自建一个中继服务器。

所以，决定自建 headscale 服务！

因为 headscale 服务需要在节点建立 P2P 连接时提供帮助，所以需要所有节点即使在没有 tailscale 网络时，也能连接到 headscale 服务。也就是说，headscale 服务需要一个公网 IP。因此，我只能在我的 VPS 上搭建服务。

为了保持现在依赖 zerotier 网络的服务依然能够运行，我需要保证新的 tailscale 网络里设备依然有它们原本在 zerotier 网络里时 的 IP。为了避免 IP 地址冲突，首先，删掉原来就有的 zerotier：

```plain
0 apt autoremove zerotier-one
[sudo] password for jyi:
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  zerotier-one
0 upgraded, 0 newly installed, 1 to remove and 0 not upgraded.
After this operation, 11.3 MB disk space will be freed.
Do you want to continue? [Y/n] Y
```

接着，参考 headscale 的 [Linux 安装指南](https://headscale.net/running-headscale-linux/)。我们的 VPS 是 Debian bookworm 发行版，amd64 架构。因此，我们先下载对应的 deb 包，然后安装：

```plain
wget https://github.com/juanfont/headscale/releases/download/v0.22.3/headscale_0.22.3_linux_amd64.deb
apt install ./headscale_0.22.3_linux_amd64.deb
```

接着来配置 headscale。因为端口很难记，所以我们先用 nginx 给它反向代理一下，让它可以使用酷炫的维尔薇爱好者特供域名和 SSL ：

```nginx
map $http_upgrade $connection_upgrade {
    default      keep-alive;
    'websocket'  upgrade;
    ''           close;
}

server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate  XXXXXXXXXXXXXXXXX;
        ssl_certificate_key XXXXXXXXXXX;
        ssl_protocols TLSv1.2 TLSv1.3;

        server_name headscale.villv.tech;

        location / {
                proxy_pass http://127.0.0.1:18002;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_set_header Host $server_name;
                proxy_redirect http:// https://;
                proxy_buffering off;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
                add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
        }
}
```

这样配好了以后，就可以用 headscale.villv.tech 访问我们监听 18002 端口的 headscale 服务了。我们再编辑 `/etc/headscale/config.yaml` 把 headscale 服务配好（配置文件中有详细的注释，不再给出示例）。

写 headscale 配置时发现它只支持 110.64.0.0/10 这一个网段，和原来 zerotier 的 172.27.0.0/16 完全不在一个段。它还不支持改网段，这下 zerotier 白删了。tailscale 给了个 [解释](https://tailscale.com/kb/1015/100.x-addresses) 说明为什么用这个段（ 但是没说为什么不支持改）。其中有句话特别好玩：

> The addresses are supposed to be used by Internet Service Providers (ISPs) rather than private networks. Philosophically, Tailscale is a service provider creating a shared network on top of the regular Internet. When packets leave the Tailscale network, different addresses are always used.

好耶，我现在也是个 ISP 了！

不管怎么样，总之 headscale，启动！

```plain
root:/etc/nginx/sites-enabled# systemctl enable --now headscale.service
Created symlink /etc/systemd/system/multi-user.target.wants/headscale.service → /lib/systemd/system/headscale.service.
root:/etc/nginx/sites-enabled#
```

## 客户端 tailscale 安装

首先，VPS 作为网关，肯定得加入我们的 headscale 网络，这样才能把流量转发到我们在 headscale 网络里的服务中。所以，先试着在 VPS 上安装。

注意，你可以需要辗转两个组织（headscale 和 tailscale）提供的文档，才能把它玩起来。

依照 tailscale 提供的 [安装指南](https://tailscale.com/download/linux/debian-bookworm) ：

```plain
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
apt update
apt install tailscale
```

接着，再依照 headscale 提供的 [接入指南](https://headscale.net/running-headscale-linux/#installation)

在 headscale 服务器上执行：

```plain
root:~# headscale users create jyi
User created
root:~# headscale --user jyi preauthkeys create --reusable --expiration 24h
XXXXXXXXXXXXXXXXX980f40768460b1025aXXXXXXXXXXXXX
```

获取到一个连接密钥。

接着在需要连接到 headscale 服务的 tailscale 客户端上执行，并且带上刚刚获取的连接密钥：

```plain
root:~# tailscale up --login-server https://headscale.villv.tech --authkey XXXXXXXXXXXXXce90980f4XXXXXXXXXXXXXXXXXXXXXXXXXX
root:~#
```

搞定！接下来检查一下自己是否已经拿到了 tailscale 的 IP 地址：

```plain
root:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:16:3e:03:0b:6e brd ff:ff:ff:ff:ff:ff
    altname enp0s5
    altname ens5
    inet 172.20.113.58/20 metric 100 brd 172.20.127.255 scope global dynamic eth0
       valid_lft 314157516sec preferred_lft 314157516sec
    inet6 fe80::216:3eff:fe03:b6e/64 scope link
       valid_lft forever preferred_lft forever
7: tailscale0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1280 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 100.64.0.1/32 scope global tailscale0
       valid_lft forever preferred_lft forever
    inet6 fd7a:115c:a1e0::1/128 scope global
       valid_lft forever preferred_lft forever
    inet6 fe80::84bd:1f32:8594:e3b/64 scope link stable-privacy
       valid_lft forever preferred_lft forever
```

发现，大功告成！

然后，我们再在另一台机器（我的 homelab）上做类似的事情，在上面配置好 tailscale 的客户端。

最后，试着 ping 一下：

```plain
warmhome 21:01 ~
0 tailscale ip
fd7a:115c:a1e0::2
100.64.0.2
warmhome 21:01 ~
0 ping 100.64.0.1
PING 100.64.0.1 (100.64.0.1) 56(84) bytes of data.
64 bytes from 100.64.0.1: icmp_seq=1 ttl=64 time=27.3 ms
64 bytes from 100.64.0.1: icmp_seq=2 ttl=64 time=26.9 ms
^C
--- 100.64.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 26.926/27.125/27.324/0.199 ms
```

好耶，ping 通了！而且通过 tailscale 网络 ping VPS 的延迟基本上和直接 ping VPS 的物理地址的延迟一样，感觉很不错。
