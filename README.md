有问题请到 https://github.com/gdy666/lucky 提issue反馈.最好顺手点个小星星

使用方式：
--
~确认路由器设备已经开启SSH并获取root权限（带GUI桌面的Linux设备可使用自带终端安装）<br>
~使用SSH连接工具（如putty，JuiceSSH，系统自带终端等）路由器或Linux设备的SSH管理界面或终端界面，并切换到root用户<br>
~确认设备已经安装curl或者wget下载工具。**如未安装**，LInux设备请[参考此处](https://www.howtoing.com/install-curl-in-linux)安装curl，基于OpenWrt（小米官方系统、潘多拉、高恪等）的设备请使用如下命令安装curl：<br>

```Shell
opkg update && opkg install curl #如已安装请忽略
```

~之后在SSH界面执行如下安装命令，并按照后续提示完成安装<br>

升级新版本只需重新运行安装指令,末尾参数改为最新版本号,安装完成后在后台设置页面重启程序即可.

（**如无法连接或出现SSL连接错误，请尝试更换各种不同的安装源！**）<br>

~**使用curl安装**：<br>
```Shell
#fastgit.org加速
curl -o /tmp/install.sh   https://raw.fastgit.org/gdy666/lucky-files/main/golucky.sh  && sh /tmp/install.sh https://raw.fastgit.org/gdy666/lucky-files/main 1.7.3
```



```shell
#jsDelivrCDN源
curl -o /tmp/install.sh  https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main/golucky.sh  && sh /tmp/install.sh https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main 1.7.3
```



~**使用wget安装**：<br>

```shell
#fastgit.org加速
wget -O /tmp/install.sh https://raw.fastgit.org/gdy666/lucky-files/main/golucky.sh  && sh /tmp/install.sh https://raw.fastgit.org/gdy666/lucky-files/main/ 1.7.3
```


```shell
#jsDelivrCDN源
wget -O /tmp/install.sh https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main/golucky.sh  && sh /tmp/install.sh https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main  1.7.3
```



~**使用低版本wget（提示不支持https）安装**：<br>



~**运行时的额外依赖**：<br>

> 大部分的设备/系统都已经预装了以下的大部分依赖，使用时如无影响可以无视之

```Text
bash/ash		必须		全部缺少时无法安装及运行脚本
curl/wget		必须		全部缺少时无法在线安装及更新，无法使用节点保存功能
systemd/rc.common	一般		全部缺少时只能使用保守模式,可能无法设置开机自动启动