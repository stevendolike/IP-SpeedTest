#!/bin/bash

# 定义颜色和符号
reset="\033[0m"
red="\033[1;91m"
green="\033[1;32m"
yellow="\033[1;33m"
cyan="\033[1;36m"
blue="\033[1;34m"
check="✓"
error="✗"
arrow="➜"
separator="===================================="  # 分隔线

# 日志函数
log_error() { echo -e "${red}${error} $1${reset}"; }
log_success() { echo -e "${green}${check} $1${reset}"; }
log_info() { echo -e "${cyan}${arrow} $1${reset}"; }

# 定义 GitHub 参数
GH_TOKEN="ghp_ggsgsg6778r6eetetyettrwg"
GH_EMAIL="123abc@hotmail.com"
GH_USER="yutianqq"
GH_REPO="iptest"
GH_BRANCH="main"

# 定义文件路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
speedcsv_dir="${SCRIPT_DIR}/csv"

# 检查 speedcsv_dir 是否存在且包含有效的 CSV 文件
if [ ! -d "$speedcsv_dir" ] || [ -z "$(ls -A "$speedcsv_dir"/ip*.csv 2>/dev/null)" ]; then
    log_error "文件夹 $speedcsv_dir 或测速 csv 文件不存在或为空，请检查输入文件"
    exit 1
fi

# 验证必要参数
if [ -z "$GH_TOKEN" ] || [ -z "$GH_USER" ] || [ -z "$GH_REPO" ] || [ -z "$GH_BRANCH" ]; then
    log_error "必要的 GitHub 参数未设置"
    exit 1
fi

# 上传测速结果到 GitHub
upload_csv() {
    echo -e "${blue}${separator}${reset}"
    log_info "当前脚本所在的目录是: $SCRIPT_DIR"
    log_info "测速文件目录为: $speedcsv_dir"

    # 配置 Git 用户信息
    git config --global user.email "${GH_EMAIL}"
    git config --global user.name "${GH_USER}"

    # 创建临时目录
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    cd "$tmp_dir" || { 
        log_error "无法进入临时目录"
        return 1
    }

    # 克隆指定的仓库
    clone_url="https://x-access-token:${GH_TOKEN}@github.com/${GH_USER}/${GH_REPO}.git"
    log_info "正在克隆仓库: https://github.com/${GH_USER}/${GH_REPO}"

    if ! git clone --depth 1 --branch "$GH_BRANCH" "$clone_url" 2>&1; then
        log_error "克隆失败，请检查仓库变量或网络连接"
        return 1
    fi

    # 进入仓库目录
    cd "$GH_REPO" || { 
        log_error "无法进入仓库目录"
        return 1
    }

    # 复制所有测速文件
    for csv_file in "$speedcsv_dir"/ip*.csv; do
        filename=$(basename "$csv_file")
        log_info "正在上传文件: $filename"
        cp -f "$csv_file" .
        git add "$filename"
    done

    # 检查暂存区是否有变化并提交
    if git diff --cached --quiet; then
        log_success "没有更改可提交"
    else
        if ! git commit -m "更新测速文件 $(date +'%Y-%m-%d %H:%M:%S')"; then
            log_error "Git 提交失败"
            return 1
        fi

        # 推送到指定分支
        if ! git push origin "$GH_BRANCH"; then
        log_error "上传到 GitHub 仓库失败"
            return 1
        fi
        
        log_success "测速文件已推送"
    fi

    return 0
}

# 执行上传函数
upload_csv

# 检查执行结果
if [ $? -ne 0 ]; then
    log_error "上传失败，请检查网络连接"
    exit 1
else
    log_success "上传完成"
    exit 0
fi