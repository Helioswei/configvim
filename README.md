# configvim

### 介绍

vim在centos7，ubuntu，mac下的配置脚本，个人用于c++的开发。

### 安装

```
git clone https://gitee.com/helioswei/configvim.git
cd configvim
./install.sh
```

### 配置介绍

#### 插件管理

我们的vim的插件管理通过使用vim-plug来进行管理，[详细介绍](https://vimjc.com/vim-plug.html)。下载安装如下：

```shell
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

##### 插件的安装

目前需要在Vim命令行模式下，使用命令 `:PlugInstall` 可安装vim配置文件中所有配置的vim插件。

`todo:直接将已经下载好的插件的目录拷贝过去,预防因为网络的原因导致下载失败`

#### 基础的配置

```
" 插入模式下删除
" set backspace=indent,eol,start
set backspace=2
" 开启文件类别侦测
filetype on
" 根据侦测到的不同类型加载对应的插件
filetype plugin on

" 开启实时搜索功能
set incsearch
" 搜索时大小写不敏感
set ignorecase
" 关闭兼容模式
set nocompatible
" vim 自身命令行模式智能补全
set wildmenu
" 设置自动换行
" set wrap

" 总是显示状态栏
set laststatus=2
" 显示光标当前位置
set ruler
" 高亮显示当前行/列
"set cursorline
"set cursorcolumn
" 高亮显示搜索结果
set hlsearch
" 设置默认显示行号
set number
" 开启语法高亮功能
syntax enable

" 代码缩进
" 自适应不同语言的智能缩进
filetype indent on
" 将制表符扩展为空格
set expandtab
" 设置编辑时制表符占用的空格数
set tabstop=4
" 设置格式化时制表符占用的空格数
set shiftwidth=4
" 让vim把连续数量的空格视为一个制表符
"set softtabstop=4
```

#### 代码格式化

我们使用插件vim-autoformat/vim-autoformat来进行[代码格式化](https://aiezu.com/article/linux_vim_plugin_autoformat_install.html)`@todo:autoformat的详细介绍`。在使用的时候需要添加一些依赖的库，例如c++的clang等

#### 代码跳转

我们使用的是插件majutsushi/tagbar来进行的，需要依赖ctags来进行

### 常用命令

#### 内部移动

- k：上移

- j：下移

- h：左移

- l：右移

#### 行内移动

    利用f命令搜索某字符方式 ，f表示向后移动到某字符；

-  **fa表示向后移动到字符a处**

-   **Fa表示向前移动到字符a处**


