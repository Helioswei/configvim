# configvim

一套跨平台的 Vim/C++ 开发环境配置，支持 **macOS、Ubuntu/Debian、CentOS/RHEL**。

## 安装

```bash
git clone https://github.com/helioswei/configvim.git
cd configvim
./install.sh
```

## 一键安装做了什么

| 步骤 | 说明 |
|------|------|
| 备份旧配置 | `~/.vimrc` → `~/.vimrc.bak`（已有备份则追加时间戳） |
| 安装配置 | 将仓库中的 `.vimrc` 拷贝到 `~/.vimrc` |
| 安装插件管理器 | [vim-plug](https://github.com/junegunn/vim-plug)，失败自动重试并切换镜像 |
| 安装系统依赖 | `clang`、`ctags`、`astyle`（macOS 通过 Xcode CLT + Homebrew，Linux 通过 apt/yum） |
| 安装 Vim 插件 | 自动执行 `:PlugInstall`，下载 `.vimrc` 中配置的所有插件 |

> 整个过程无需 root 权限（系统包管理器调用时会提示 sudo）。

## 插件列表

### 代码导航

| 插件 | 说明 |
|------|------|
| [nerdtree](https://github.com/preservim/nerdtree) | 文件树浏览器 |
| [tagbar](https://github.com/majutsushi/tagbar) | 标签栏，显示类/方法/变量结构 |
| [vim-gutentags](https://github.com/ludovicchabant/vim-gutentags) | 自动生成 ctags 标签 |
| [a.vim](https://github.com/vim-scripts/a.vim) | `.h` / `.cpp` 文件快速切换 |

### 代码编辑

| 插件 | 说明 |
|------|------|
| [vim-cpp-enhanced-highlight](https://github.com/octol/vim-cpp-enhanced-highlight) | C++ 增强语法高亮 |
| [auto-pairs](https://github.com/jiangmiao/auto-pairs) | 括号/引号自动配对 |
| [vim-autoformat](https://github.com/vim-autoformat/vim-autoformat) | 代码格式化 |
| [vim-protodef](https://github.com/derekwyatt/vim-protodef) | 从头文件生成函数实现框架 |
| [vim-fswitch](https://github.com/derekwyatt/vim-fswitch) | 头文件与实现文件快速切换 |
| [mark.vim](https://github.com/mbriggs/mark.vim) | 文本高亮标记 |
| [vim-glsl](https://github.com/tikhomirov/vim-glsl) | GLSL 语法支持 |

## 快捷键

| 按键 | 功能 |
|------|------|
| `F2` | `.h` / `.cpp` 文件切换 |
| `F3` | 开关 NERDTree 文件树 |
| `F4` | JSON 格式化 |
| `F8` | 开关 Tagbar 标签栏 |
| `F1` | 代码格式化（astyle） |
| `\s` | 头文件与实现文件快速切换（vim-fswitch） |
| `Ctrl + ]` | 跳转定义（不自动选择，多个结果时列出） |

## 手动管理插件

```vim
:PlugInstall   " 安装所有插件
:PlugUpdate    " 更新所有插件
:PlugClean     " 清理已删除的插件
:PlugDiff      " 查看插件差异
```

## 基础配置说明

```vim
set number          " 显示行号
set ruler           " 显示光标位置
set laststatus=2    " 始终显示状态栏
set tabstop=4       " Tab 宽度为 4 空格
set expandtab       " Tab 展开为空格
set incsearch       " 实时搜索
set hlsearch        " 高亮搜索结果
set wildmenu        " 命令行智能补全
syntax enable       " 语法高亮
filetype on         " 文件类型检测
```
