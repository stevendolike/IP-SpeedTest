#!/bin/bash

# 定义颜色和状态符号
green="\033[1;32m"  # 绿色（成功状态）
blue="\033[1;34m"   # 蓝色（信息提示）
cyan="\033[1;36m"   # 青色（进度信息）
purple="\033[1;35m" # 紫色（分隔线）
red="\033[1;31m"    # 红色（错误状态）
reset="\033[0m"     # 重置颜色
error="✗"           # 错误符号
tick="✔"           # 成功符号
arrow="➜"          # 进度符号
separator="===================================="  # 分隔线

# 日志函数
log_error() { echo -e "${red}${error} $1${reset}"; }
log_success() { echo -e "${green}${tick} $1${reset}"; }
log_info() { echo -e "${cyan}${arrow} $1${reset}"; }

# 导出日志函数，以便在子进程中调用
export -f log_error log_success log_info

# 定义输入和输出文件夹路径
input_folder="ip"
output_folder="ip2"
origin_txt="ip-443.txt"
merge_txt="ip-443-2.txt"

# 检查输入文件夹是否存在且包含有效的文件
if [ ! -d "$input_folder" ] || [ -z "$(ls -A "$input_folder"/ip-*.txt 2>/dev/null)" ]; then
    log_error "文件夹 $input_folder 不存在或为空，请检查输入文件"
    exit 1
fi

# 如果输出文件夹不存在，则创建
if [ ! -d "$output_folder" ]; then
    mkdir -p "$output_folder"
    log_success "创建输出文件夹: $output_folder"
fi

# 定义格式化函数
format_file() {
    local input_file="$1" output_file="$2"
    > "$output_file"  # 清空或创建输出文件
    log_info "正在处理文件: $(basename "$input_file") -> $(basename "$output_file")"

    local total_lines=$(wc -l < "$input_file") processed_lines=0
    if [ "$total_lines" -eq 0 ]; then
        log_error "文件 $(basename "$input_file") 为空，跳过处理"
        return
    fi

    while IFS= read -r line; do
        line=$(echo "$line" | tr -d '\r\n')
        echo "$(cut -d ':' -f 1 <<< "$line") $(cut -d ':' -f 2 <<< "$line" | cut -d '#' -f 1)" >> "$output_file"
        processed_lines=$((processed_lines + 1))
        local progress=$((processed_lines * 100 / total_lines))
        # 绘制进度条
        local bar_length=20
        local filled_length=$((progress * bar_length / 100))
        local bar=$(printf "%-${bar_length}s" | tr ' ' '=')
        printf "${cyan}${arrow} 文件 $(basename "$input_file") 处理进度: [${bar:0:filled_length}>${bar:filled_length}] ${progress}%%（${processed_lines}行/${total_lines}行）\r${reset}"
    done < "$input_file"

    log_success "文件 $(basename "$input_file") 格式化完成，已生成 $(basename "$output_file")"
    echo -e "${purple}${separator}${reset}"
}

# 导出格式化函数，以便在子进程中调用
export -f format_file

# 使用 xargs 并行处理文件
find "$input_folder" -name "ip-*.txt" ! -name "$origin_txt" -print0 | xargs -0 -n 1 -P 16 bash -c '
    input_file="$1"
    output_file="'"$output_folder"'/$(basename "${1%.txt}2.txt")"
    format_file "$input_file" "$output_file"
' _

# 合并并去重所有输出文件，生成 ip-443-2.txt
merge_file="$output_folder/$merge_txt"
log_info "正在合并并去重所有输出文件，生成: $(basename "$merge_file")"
find "$output_folder" -name "ip-*.txt" ! -name "$merge_txt" -print0 | xargs -0 cat | sort -u > "$merge_file"

# 检查合并文件是否成功生成
if [ -f "$merge_file" ]; then
    log_success "文件 $(basename "$merge_file") 已成功生成，共 $(wc -l < "$merge_file") 行"
else
    log_error "文件 $(basename "$merge_file") 生成失败"
fi

# 输出最终结果
log_success "所有文件处理完成！"
log_info "输出文件已保存到: $output_folder"
log_info "分地区 IP 库:"
find "$output_folder" -name "ip-*.txt" ! -name "$merge_txt" -print0 | xargs -0 -n 1 basename | while read -r file; do
    log_info "$output_folder/$file"
done
echo -e "${purple}${separator}${reset}"
log_info "合并后的 IP 库: $output_folder/$merge_txt"