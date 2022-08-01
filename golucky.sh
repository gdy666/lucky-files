#!/bin/bash
# Copyright (C) gdy666
# http://192.168.31.70:9999/install_v2.sh
# wget -q -O /tmp/install.sh http://192.168.31.70:9999/install_v2.sh  && sh /tmp/install.sh 
#wget -q -O /tmp/install.sh https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main/golucky.sh  && sh /tmp/install.sh https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main 1.1.3


echo='echo -e' && [ -n "$(echo -e|grep e)" ] && echo=echo
#[ -z "$1" ] && test=0 || test=$1


luckPathSuff='lucky.daji'
cdnurl=$1
version=$2


luckyshMenu(){
	echo "************************************************"
	echo "**                 欢迎使用                    **"
	echo "**                Lucky 管理脚本               **"
	echo "**                             by  古大羊     **"
	echo "************************************************"
    echo -e " 1 \033[32m安装\033[0mLucky"
    echo -e " 2 \033[32m卸载\033[0mLucky"
    echo -----------------------------------------------
    echo -e " 0 \033[0m退出脚本\033[0m"
	read -p "请输入对应数字 > " num
    if [ -z "$num" ];then
    errornum
	exit 1;
    elif [ "$num" = 0 ]; then
		echo "退出脚本"
		exit 0;
		
	elif [ "$num" = 1 ]; then
		echo "安装Lucky..."
		install
	elif [ "$num" = 2 ]; then
		echo "卸载Lucky..."
		uninstall
	else
		errornum
		exit 1;
    fi
}

errornum(){
	echo -----------------------------------------------
	echo -e "\033[31m请输入正确的数字！\033[0m"
}

# dir_avail 查询路径可用空间
dir_avail(){
	df -h $1 |awk '{ for(i=1;i<=NF;i++){ if(NR==1){ arr[i]=$i; }else{ arr[i]=arr[i]" "$i; } } } END{ for(i=1;i<=NF;i++){ print arr[i]; } }' |grep Ava |awk '{print $2}'
}



webget(){
	#参数【$1】代表下载目录，【$2】代表在线地址
	#参数【$3】代表输出显示，【$4】不启用重定向
	if wget --version > /dev/null 2>&1;then
		[ "$4" = "rediroff" ] && redirect='--max-redirect=0' || redirect=''
		certificate='--no-check-certificate'
		timeout='--timeout=3'
		[ "$3" = "echoon" ] && progress=''
		[ "$3" = "echooff" ] && progress='-q'
		wget $progress $redirect $certificate $timeout -O $1 $2 
		[ $? -eq 0 ] && result="200"
	else 
		if curl --version > /dev/null 2>&1;then
			[ "$3" = "echooff" ] && progress='-s' || progress='-#'
			[ -z "$4" ] && redirect='-L' || redirect=''
			result=$(curl -w %{http_code} --connect-timeout 5 $progress $redirect -ko $1 $2)
			[ -n "$(echo $result | grep -e ^2)" ] && result="200"
		fi
	fi
}

getcpucore(){
	cputype=$(uname -ms | tr ' ' '_' | tr '[A-Z]' '[a-z]')
	[ -n "$(echo $cputype | grep -E "linux.*armv.*")" ] && cpucore="armv5"
	[ -n "$(echo $cputype | grep -E "linux.*armv7.*")" ] && [ -n "$(cat /proc/cpuinfo | grep vfp)" ] && [ ! -d /jffs/clash ] && cpucore="armv7"
	[ -n "$(echo $cputype | grep -E "linux.*aarch64.*|linux.*armv8.*")" ] && cpucore="arm64"
	[ -n "$(echo $cputype | grep -E "linux.*86.*")" ] && cpucore="i386"
	[ -n "$(echo $cputype | grep -E "linux.*86_64.*")" ] && cpucore="x86_64"
	if [ -n "$(echo $cputype | grep -E "linux.*mips.*")" ];then
		mipstype=$(echo -n I | hexdump -o 2>/dev/null | awk '{ print substr($2,6,1); exit}') #通过判断大小端判断mips或mipsle
		[ "$mipstype" = "0" ] && cpucore="mips_softfloat" || cpucore="mipsle_softfloat"
	fi
}

setcpucore(){
	cpucore_list="armv5 armv7 arm64 i386 x86_64 mipsle_softfloat mipsle-hardfloat mips_softfloat"
	echo -----------------------------------------------
	echo -e "当前可供在线下载的处理器架构为："
	echo $cpucore_list | awk -F " " '{for(i=1;i<=NF;i++) {print i" "$i }}'
	echo -e "如果您的CPU架构未在以上列表中，请运行【uname -a】命令,并复制好返回信息"
	echo -e "之后联系作者"
	echo -----------------------------------------------
	read -p "请输入对应数字 > " num

	setcpucore=$(echo $cpucore_list | awk '{print $"'"$num"'"}' )
	if [ -z "$setcpucore" ];then
		echo -e "\033[31m请输入正确的处理器架构！\033[0m"
		sleep 1
		cpucore=""
	else
		cpucore=$setcpucore
	fi
}

getTargetFileURL(){
    #download_url=$cdnurl'/dist/lucky_'$version'_Linux_'$cpucore'.tar.gz'
	#https://fastly.jsdelivr.net/gh/gdy666/lucky-files@main/1.1.3/lucky_1.1.3_Linux_i386.tar.gz
	download_url=$cdnurl'/'$version'/lucky_'$version'_Linux_'$cpucore'.tar.gz'
    echo "目标文件下载链接:"$download_url
}


getLinuxSysType(){
[ -f "/etc/storage/started_script.sh" ] && systype=Padavan && initdir='/etc/storage/started_script.sh'
[ -d "/jffs" ] && systype="asusrouter" && { 
	[ -f "/jffs/.asusrouter" ] && initdir='/jffs/.asusrouter'
	[ -d "/jffs/scripts" ] && initdir='/jffs/scripts/init-start' 
	[ -z "$initdir" ] && initdir='/jffs/scripts/init-start' && mkdir -p '/jffs/scripts'
	}
[ -f "/data/etc/crontabs/root" -a "$(dir_avail /etc)" = 0 ] && systype=mi_snapshot


}

installStartDaemon(){
	echo "设为保守模式启动"
	type nohup >/dev/null 2>&1 && nohup=nohup
	$nohup $luckydir/lucky -c "$luckydir/lucky.conf" >/dev/null 2>&1 &
	cronset '#lucky保守模式守护进程' "*/1 * * * * test -z \"\$(pidof lucky)\" && $luckydir/lucky -c $luckydir/lucky.conf #lucky保守模式守护进程"
}

installSetInit(){
	#判断系统类型写入不同的启动文件
if [ -f /etc/rc.common ];then
        #设为init.d方式启动
        echo "设为init.d方式启动"
        cp -f $luckydir/scripts/luckyservice /etc/init.d/$luckPathSuff
        chmod 755 /etc/init.d/$luckPathSuff
		/etc/init.d/$luckPathSuff enable
		/etc/init.d/$luckPathSuff start
else
    [ -w /etc/systemd/system ] && sysdir=/etc/systemd/system
    [ -w /usr/lib/systemd/system ] && sysdir=/usr/lib/systemd/system
    if [ -n "$sysdir" ];then

        #设为systemd方式启动
        echo "设为systemd方式启动"
		echo "sysdir:"$sysdir
        mv $luckydir/scripts/lucky.service $sysdir/$luckPathSuff.service
        sed -i "s%/etc/lucky%$luckydir%g" $sysdir/$luckPathSuff.service
		chmod 000 $sysdir/$luckPathSuff.service
        systemctl daemon-reload
		if [  ! $? = 0 ];then
			echo "systemctl daemon-reload 出错， 转为保守模式..."
			installStartDaemon
		else
			systemctl enable $luckPathSuff.service
			systemctl start $luckPathSuff.service
		fi
    else
    #设为保守模式启动
	installStartDaemon
    fi
fi

    #华硕/Padavan额外设置,开机启动
	[ -n "$initdir" ] && { 
		echo "华硕/Padavan开机启动额外设置"$initdir
		sed -i '/Lucky启动/'d $initdir >/dev/null 2>&1
		if [ ! -e $initdir ];then
			touch $initdir
			echo "#!/bin/sh"  >> $initdir
		fi
		sed -i '/Lucky启动/'d $initdir 2>/dev/null
		echo "$luckydir/lucky -c $luckydir/lucky.conf >/dev/null& #Lucky启动脚本" >> $initdir
		chmod +x $initdir
		
		}
	#小米镜像化OpenWrt额外设置
	if [ "$systype" = "mi_snapshot" ];then
        echo '执行小米镜像化OpenWrt额外设置'
		chmod 755 $luckydir/scripts/misnap_init.sh
		uci set firewall.Lucky=include
		uci set firewall.Lucky.type='script'
		uci set firewall.Lucky.path='/data/lucky.daji/scripts/misnap_init.sh'
		uci set firewall.Lucky.enabled='1'
		uci commit firewall
	fi

}

installSetProfile(){
	[ -w /opt/etc/profile ] && profile=/opt/etc/profile
	[ -w /jffs/configs/profile.add ] && profile=/jffs/configs/profile.add
	[ -w ~/.bashrc ] && profile=~/.bashrc
	[ -w /etc/profile ] && profile=/etc/profile
	if [ -n "$profile" ];then
		sed -i '/alias lucky=*/'d $profile
		echo "alias lucky=\"$luckydir/lucky\"" >> $profile #设置快捷命令环境变量
		sed -i '/export luckydir=*/'d $profile
		echo "export luckydir=\"$luckydir\"" >> $profile #设置快捷命令环境变量
	else
		echo 无法写入环境变量！请检查安装权限！
		exit 1
	fi
	echo 'Profile:'$profile
}

checkRoot(){
    #检查root权限
if [ "$USER" != "root" -a -z "$systype" ];then
	echo 当前用户:$USER
	$echo "\033[31m请尽量使用root用户（不要直接使用sudo命令！）执行安装!\033[0m"
	echo -----------------------------------------------
	read -r -p  "仍要安装？可能会产生未知错误！(1/0) > " res
	[ "$res" != "1" ] && echo "Lukcy 安装脚本中止运行" && exit 1
fi

}

croncmd(){
	if [ -n "$(crontab -h 2>&1 | grep '\-l')" ];then
		crontab $1
	else
		crondir="$(crond -h 2>&1 | grep -oE 'Default:.*' | awk -F ":" '{print $2}')"
		[ ! -w "$crondir" ] && crondir="/etc/storage/cron/crontabs"
		[ ! -w "$crondir" ] && crondir="/var/spool/cron/crontabs"
		[ ! -w "$crondir" ] && crondir="/var/spool/cron"
		[ ! -w "$crondir" ] && echo "你的设备不支持定时任务配置"
		[ "$1" = "-l" ] && cat $crondir/$USER 2>/dev/null
		[ -f "$1" ] && cat $1 > $crondir/$USER
	fi
}

cronset(){
	# 参数1代表要移除的关键字,参数2代表要添加的任务语句
	tmpcron=/tmp/cron_$USER
	croncmd -l > $tmpcron 
	sed -i "/$1/d" $tmpcron
	sed -i '/^$/d' $tmpcron
	echo "$2" >> $tmpcron
	croncmd $tmpcron
	rm -f $tmpcron
}

install(){
	getTargetFileURL
	setdir	#设置安装路径
	getFilesFromNetwork #下载解压设置权限
	installSetProfile #设置环境变量
	installSetInit #设置开机启动
	
	i=0
	while [ "$i" -lt 10 ];do
		sleep 1
		PID=$(pidof lucky) && [ -n "$PID" ] && echo "lucky已成功运行" && exit 0 && i=10 ||  i=$((i+1))
	done

	echo "检测超时，请自行检查lucky运行情况"



}

uninstall(){
	uninstallgetdir #获取lucky安装路径


	systemctl stop $luckPathSuff.service >/dev/null 2>&1 &

	#结束进程
	PID=$(pidof lucky) && [ -n "$PID" ] &&  kill -9 $PID >/dev/null 2>&1

	if [ -z $luckydir ];then
		echo "找不到lucky文件夹，卸载中止"
		exit 0
	fi

	echo "删除 "$luckydir" 所有文件"
	read -p "确认删除？"$luckydir"所有文件(1/0) > " res
	if [ -z $res ];then
		echo 卸载已取消
		exit 1;
	elif [ "$res" = "1"  ];then
		rm -rf $luckydir
	else
		echo 卸载已取消
		exit 1;
	fi

	[ -n "$initdir" ] && { #删除开机启动
		sed -i '/Lucky启动/'d $initdir 2>/dev/null
	}


	if [ "$systype" = "mi_snapshot" ];then ##删除开机启动
		uci del firewall.Lucky
		uci commit firewall
	fi

	/etc/init.d/$luckPathSuff stop >/dev/null 2>&1
	rm -rf /etc/init.d/$luckPathSuff

	sed -i '/alias lucky=*/'d $profile
	sed -i '/export luckydir=*/'d $profile

	cronset '#lucky保守模式守护进程' #删除保守模式定时

}


getFilesFromNetwork(){
    #开始下载
    webget /tmp/lucky.tar.gz $download_url 
    [ "$result" != "200" ] && echo "文件下载失败,请尝试使用其他安装源！" && exit 1
    echo -----------------------------------------------
	echo 开始解压文件！
    mkdir -p $luckydir > /dev/null
	tar -zxvf '/tmp/lucky.tar.gz' -C $luckydir/
	[ $? -ne 0 ] && echo "文件解压失败！" && rm -rf /tmp/lucky.tar.gz && exit 1 
    echo 已解压到 $luckydir
	chmod +x $luckydir/lucky
	chmod +x $luckydir/scripts/*
	rm -rf /tmp/lucky.tar.gz
}

setdir(){
if [ -n "$systype" ];then
	[ "$systype" = "Padavan" ] && dir=/etc/storage
	[ "$systype" = "asusrouter" ] && dir=/jffs
	[ "$systype" = "mi_snapshot" ] && dir=/data
else
	echo -----------------------------------------------
	$echo "\033[33m安装lucky至少需要预留约3MB的磁盘空间\033[0m"	
	$echo " 1 在\033[32m/etc目录\033[0m下安装(适合root用户)"
	$echo " 2 在\033[32m/usr/share目录\033[0m下安装(适合Linux设备)"
	$echo " 3 在\033[32m当前用户目录\033[0m下安装(适合非root用户)"
	$echo " 4 手动设置安装目录"
	$echo " 0 退出安装"
	echo -----------------------------------------------
	read -p "请输入相应数字 > " num
	#设置目录
	if [ -z $num ];then
		echo 安装已取消
		exit 1;
	elif [ "$num" = "1" ];then
		dir=/etc
	elif [ "$num" = "2" ];then
		dir=/usr/share
	elif [ "$num" = "3" ];then
		dir=~/.local/share
	elif [ "$num" = "4" ];then
		echo -----------------------------------------------
		echo '可用路径 剩余空间:'
		df -h | awk '{print $6,$4}'| sed 1d 
		echo '路径是必须带 / 的格式，注意写入虚拟内存(/tmp,/opt,/sys...)的文件会在重启后消失！！！'
		read -p "请输入自定义路径 > " dir
		if [ -z "$dir" ];then
			$echo "\033[31m路径错误！请重新设置！\033[0m"
			setdir
		fi
	else
		echo 安装已取消！！！
		exit 1;
	fi
fi



if [ ! -w $dir ];then
	$echo "\033[31m没有$dir目录写入权限！请重新设置！\033[0m" && sleep 1 && setdir
else
	$echo "目标目录\033[32m$dir\033[0m空间剩余：$(dir_avail $dir)"
	read -p "确认安装？(1/0) > " res
	if [ -z $res ];then
		echo 安装已取消
		exit 1;
	elif [ "$res" = "1"  ];then
		luckydir=$dir/$luckPathSuff 
		echo "luckdir:"$luckydir
	else
		echo 安装已取消
		exit 1;
	fi
fi
}

uninstallgetdir(){

[ -w /opt/etc/profile ] && profile=/opt/etc/profile
[ -w /jffs/configs/profile.add ] && profile=/jffs/configs/profile.add
[ -w ~/.bashrc ] && profile=~/.bashrc
[ -w /etc/profile ] && profile=/etc/profile

luckydir=$(cat $profile | grep luckydir | awk -F "\"" '{print $2}')


if [ -n "$luckydir" ];then
	return 
fi

if [ -n "$systype" ];then
	[ "$systype" = "Padavan" ] && dir=/etc/storage
	[ "$systype" = "asusrouter" ] && dir=/jffs
	[ "$systype" = "mi_snapshot" ] && dir=/data
	luckydir=$dir/$luckPathSuff 
fi

# if [ -n "$systype" ];then
# [ "$systype" = "Padavan" ] && dir=/etc/storage
# [ "$systype" = "asusrouter" ] && dir=/jffs
# [ "$systype" = "mi_snapshot" ] && dir=/data
# else
# 	echo -----------------------------------------------
# 	$echo " 1 \033[32m/etc\033[0m"
# 	$echo " 2 \033[32m/usr/share\033[0m"
# 	$echo " 3 \033[32m当前用户目录\033[0m"
# 	$echo " 4 手动指定安装目录"
# 	$echo " 0 退出卸载"
# 	echo -----------------------------------------------
# 	read -p "请输入相应数字 > " num
# 	#设置目录
# 	if [ -z $num ];then
# 		echo 卸载已取消
# 		exit 1;
# 	elif [ "$num" = "1" ];then
# 		dir=/etc
# 	elif [ "$num" = "2" ];then
# 		dir=/usr/share
# 	elif [ "$num" = "3" ];then
# 		dir=~/.local/share
# 	elif [ "$num" = "4" ];then
# 		echo -----------------------------------------------
# 		read -p "请输入自定义路径 > " dir
# 		if [ -z "$dir" ];then
# 			$echo "\033[31m路径错误！请重新设置！\033[0m"
# 			uninstallgetdir
# 		fi
# 	else
# 		echo 卸载已取消！！！
# 		exit 1;
# 	fi
# fi

# luckydir=$dir/$luckPathSuff 
}

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------

#获取CPU结构
getcpucore

if [ -z "$cpucore" ];then
    echo '未能正确识别当前系统CPU架构,请与作者联系'
    exit 1
fi 

echo "当前CPU架构:"$cpucore


#判断linux环境, $systype ,$initdir
getLinuxSysType

[ -n "$initdir" ]  && echo 'initdir:'$initdir
[ -n "$systype" ] && echo '当前处于路由器运行环境[' $systype']!'


luckyshMenu #显示菜单


#wget -q -O /tmp/install.sh http://192.168.31.70:9999/install_v2.sh  && sh /tmp/install.sh http://192.168.31.70:9999 1.1.3
#  apt-get install --reinstall systemd

#根据cdn,版本,cpu架构 拼接生成文件下载链接 $download_url
#getTargetFileURL

