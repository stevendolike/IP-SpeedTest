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
separator="===================================="

# 日志函数
log_error() { echo -e "${red}${error} $1${reset}"; }
log_success() { echo -e "${green}${check} $1${reset}"; }
log_info() { echo -e "${cyan}${arrow} $1${reset}"; }

# 测速软件下载地址
iptest_url="https://pan.811520.xyz/cdn/iptest-windows-amd64.zip"

# 定义文件结构
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ip_dir="${SCRIPT_DIR}/ip2"
tools_dir="${SCRIPT_DIR}/tools"
iptest_file="$tools_dir/iptest.exe"
speedcsv_dir="${SCRIPT_DIR}/csv"
merged_csv="$speedcsv_dir/ip443.csv"

mkdir -p "$tools_dir" "$speedcsv_dir"

# 定义测速参数（保留）
speedtest="3"
speedlimit="5"
delay="220"
speedtesturl="spurl.api.030101.xyz/50mb"

# 检查必要的环境
check_environment() {
    log_info "正在检查环境..."
    if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
        log_error "错误：需要安装 curl 或 wget"
        exit 1
    fi
    log_success "环境检查完成"
}

# 封装下载函数
download_file() {
    local url="$1"
    local output="$2"
    local filename="$3"
    log_info "下载地址: $url"
    log_info "保存到: $output/$filename"
    
    if command -v curl &>/dev/null; then
        curl -L -s "$url" -o "$output/$filename" || { log_error "curl 下载 $filename 失败，改用 wget 下载"; return 1; }
    elif command -v wget &>/dev/null; then
        wget -q "$url" -O "$output/$filename" || { log_error "wget 下载 $filename 失败"; return 1; }
    else
        log_error "$filename 下载失败，请检查下载地址或网络连接"
        return 1
    fi
    log_success "$filename 下载成功"
}

# 检查是否已有 iptest.exe，如果没有，则下载最新版
download_iptest() {
    [ -f "$iptest_file" ] && { log_success "$iptest_file 文件已存在，跳过下载"; return 0; }
    log_error "未找到 $iptest_file, 尝试从 GitHub 下载..."

    [ ! -d "$tools_dir" ] && mkdir -p "$tools_dir"
    local iptestzip="iptest.zip"
    download_file "$iptest_url" "$tools_dir" "$iptestzip" || { log_error "文件不存在，下载失败，请手动下载并解压到 $tools_dir"; exit 1; }

    log_info "正在解压文件..."
    unzip -o "$tools_dir/$iptestzip" -d "$tools_dir" >/dev/null 2>&1
    if [ -f "$iptest_file" ]; then
        chmod +x "$iptest_file" || { log_error "设置执行权限失败"; return 1; }
        log_success "iptest 解压完成"
    else 
        log_error "iptest 解压失败"
        return 1
    fi
    rm -f "$tools_dir/$iptestzip"
}

# 测速函数
speed_test() {
    local input_file="$1"
    local output_file="$2"
    log_info "正在对文件 $input_file 进行测速..."
    "$iptest_file" -file="$input_file" -max=300 -speedtest="$speedtest" -delay="$delay" -speedlimit="$speedlimit" -url="$speedtesturl" -outfile="$output_file"
    [ $? -ne 0 ] && { log_error "测速失败: $input_file"; return 1; }
    log_success "测速完成: $input_file -> $output_file"
}

# 合并所有 CSV 文件
merge_csv() {
    > "$merged_csv"  # 清空目标文件
    local first_csv=$(ls "$speedcsv_dir"/ip-*2.csv 2>/dev/null | head -n 1)

    # 如果找到第一个 CSV 文件，将其标题行写入目标文件
    if [ -f "$first_csv" ]; then
        head -n 1 "$first_csv" >> "$merged_csv"
    fi

    # 遍历所有符合条件的 CSV 文件，# 排除 $merged_csv 文件，将其内容（跳过标题行）追加到目标文件
    for csv_file in "$speedcsv_dir"/ip-*2.csv; do
        if [ -f "$csv_file" ] && [ "$csv_file" != "$merged_csv" ]; then
            tail -n +2 "$csv_file" >> "$merged_csv"
            rm "$csv_file"  # 删除已合并的 CSV 文件
        fi
    done

    log_success "所有 CSV 文件已合并为: $merged_csv"
}

# 主程序执行
echo -e "${blue}${separator}${reset}"
check_environment
download_iptest

# 检查 ip_dir 是否存在且包含有效的 IP 文件
if [ ! -d "$ip_dir" ] || [ -z "$(ls -A "$ip_dir"/ip-*-2.txt 2>/dev/null)" ]; then
    log_error "文件夹 $ip_dir 不存在或为空，请检查输入文件"
    exit 1
fi

log_error "即将开始本地测速，请先关闭代理软件！"
read -p "按回车键继续测速，按其他任意键退出..." -n 1 key
echo
[ "$key" != "" ] && { log_error "用户取消操作"; exit 0; }
log_success "开始进行本地测速，请稍候..."

for input_file in "$ip_dir"/ip-*-2.txt; do
    filename=$(basename "$input_file")
    csv_file="$speedcsv_dir/${filename%.txt}.csv"
    speed_test "$input_file" "$csv_file"
done

log_success "所有文件测速完成！"
log_success "测速结果已保存到: $speedcsv_dir"
merge_csv
echo -e "${blue}${separator}${reset}"