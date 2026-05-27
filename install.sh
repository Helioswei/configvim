#!/bin/bash
#########通用的功能函数 begin#########
#常用的日志打印
function echoLog()
{
    text="$1"
    color="31m"
    if [ -z "$2" ];then color="30m"
    else
        color="$2"
    fi
    if [ -z "$text" ];then
        echo -e "\033[$color [line: `caller 0 |awk '{print $1}'`] please input your log \033[0m" 
        exit
    fi
    echo -e "\033[$color [line: `caller 0 |awk '{print $1}'`] $text \033[0m"
}

function exitLog()
{
    echoLog "$1" "31m"
    exit
}

#检查常用的命令是否存在
function checkCmd()
{
    cmd=$1
    if [ -z "$cmd" ];then
        exitLog "please input your cmd that need to check"
    fi
    which "$cmd" >/dev/null 2>&1
    if [ $? -eq 0 ];then
        echoLog "cmd $cmd is exist"
        return 0
    else
        exitLog "cmd $cmd is not exist, please install first"
    fi
}

#检查当前是什么系统ubuntu,centos,mac
#0:mac;1:ubuntu;2:centos
function checkSys()
{
    os=`uname -s`
    if [ ${os} == "Darwin" ];then
        return 0
    elif [ ${os} == "Linux" ];then
        source /etc/os-release
        case $ID in
            debian|ubuntu|devuan)
                return 1
                ;;
            centos|fedora|rhel)
                yumdnf="yum"
                if test "$(echo "$VERSION_ID >= 22" | bc)" -ne 0;
                then
                    yumdnf="dnf"
                fi
                return 2
                ;;
            *)
                exit 1
                ;;
        esac
    else
        exitLog "Other os: ${os}"
    fi
}

#########通用的功能函数 end#########
curlExist=0
wgetExist=0
workDir=$(cd $(dirname $0);pwd)
#检查网络是否正常
function checkNet()
{
    checkCmd ping
    #ping 2次结束
    ping baidu.com -c 2
    if [[ $? != 0 ]];then
        echo "请检查你的网络状态，当前无法连接网络"
        exit
    fi
    clear
}
#检查网络工具是否存在，如curl，wget等
function checkNetTool()
{
    #check curl
    checkCmd curl
    if [ $? -eq 0 ];then
        curlExist=1;
    else
        checkCmd wget
        if [ $? -eq 0 ];then
             wgetExist=1;
        fi
    fi
}

#检查必要的软件，和网络
function check()
{
    checkNet
    checkNetTool
}

function currentDir()
{
    cd $workDir
}
function copyVimrc()
{
    #先备份本地已经存在的
    userDir="$HOME"
    mv $userDir/.vimrc $userDir/.vimrc.bak
    cp -rf .vimrc $userDir/.vimrc
}
function installPlug()
{
    #如果已经下载了则不需要下载
    if [ -f "$HOME/.vim/autoload/plug.vim" ];then
        help 0
        return
    fi
    ret=1

    if [ "$curlExist" = "1" ];then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        ret=$?
    fi 

    if [ "$wgetExist" = "1" ];then
        userDir="$HOME"
        mkdir -p $userDir/.vim/autoload/
        cd $userDir/.vim/autoload/
        wget https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        ret=$?
        cd $workDir
    fi
    help $ret
}
function help()
{
    if [ $1 -eq 0 ];then
        echoLog "Successful! 请在Vim命令行模式下，使用命令 :PlugInstall 可安装vim配置文件中所有配置的vim插件" "34m"
    else
	    rm -rf $HOME/.vimrc
        exitLog "Failed! please read log and retry install"
    fi
}

function installTool()
{
    checkSys
    case $? in
        0)
            #mac
            brew install clang #autoformat的依赖
            brew install ctags #tagbar的依赖
            brew install astyle
            ;;
        1)
            #ubuntn
            apt-get install clang
            apt-get install ctags
            apt-get install astyle
            ;;
        2)
            #centos
            yum install -y clang
            yum install -y ctags
            yum install -y astyle
            ;;
        *)
            exit 1
            ;;
    esac
}

function usage()
{
    echo "你确定需要安装vim的相关插件的配置吗？"
    echo "通过本脚本安装的配置全部在~/.vimrc文件中"
    echo "如果你确定的话则本地的配置会备份在~/.vimrc.bak中哦"
    echo "请输入yes or no 决定你的操作:"
    while true
    do
        read usageValue
        if [[ $usageValue == "yes" ]];then
            break
        elif [[ $usageValue == "no" ]];then
            exit 0
        else
            echo -n "请输入yes or no:"
        fi
    done
}

function checkSudo()
{
    #Check if the script was started as root or with sudo 
    user=`id -u`
    set -e
    [ "$user" != "0" ] && echo "++ Must be root/sudo ++" && exit
}

function main()
{
    checkSudo
    usage
    currentDir
    copyVimrc
    check
    #安装包管理工具
    installPlug
    #安装一些软件库
    installTool
}

main
exit 0
