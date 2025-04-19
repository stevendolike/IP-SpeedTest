import os
import sys
import asyncio
import re
from datetime import datetime, timedelta
from collections import defaultdict
from telethon import TelegramClient
from telethon.tl.types import DocumentAttributeFilename

# Windows 事件循环策略
if sys.platform == 'win32':
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# ================= 配置区域 =================
API_ID = '25867287'
API_HASH = '5d1de8b1faf87d6dbc55614714417ef0'
CHANNEL = 'Marisa_kristi'
PROXY = ('socks5', '127.0.0.1', 10808, True)
DOWNLOAD_DIR = 'ip'
IP_MERGE = 'ip-443.txt'
# ============================================

REGION_MAP = {
    '亚洲': 'as', '欧洲': 'eu', '美洲': 'am',
    '美国': 'us', '台湾': 'tw', '香港': 'hk', '新加坡': 'sg', '日本': 'jp', '韩国': 'kr'
}

# 定义颜色和符号
COLORS = {
    'red': '\033[91m', 'green': '\033[92m', 'yellow': '\033[93m',
    'blue': '\033[94m', 'magenta': '\033[95m', 'cyan': '\033[96m',
    'white': '\033[97m', 'reset': '\033[0m'
}
SYMBOLS = {'check': '✓', 'warning': '⚠', 'arrow': '➜', 'error': '✗'}

# 日志函数
def log(color, symbol, message):
    print(f"{COLORS[color]}{SYMBOLS[symbol]} {message}{COLORS['reset']}")

# 主逻辑
async def main():
    os.makedirs(DOWNLOAD_DIR, exist_ok=True) # 初始化环境
    async with TelegramClient('tg_session', API_ID, API_HASH, proxy=PROXY) as client:
        channel = await client.get_entity(CHANNEL) # 获取频道消息
        log('cyan', 'arrow', f"已连接频道：{channel.title}")

        downloaded = await fetch_files(client, channel)  # 下载文件
        await rename_files(downloaded)  # 重命名文件
        await merge_all_files()  # 合并ip库
        await clean_files()  # 清理残留文件

# 下载匹配 欧洲*ip*.txt、美洲*ip*.txt、亚洲*ip*.txt 的文件
async def fetch_files(client, channel):
    downloaded = set()
    target_regions = ['欧洲', '美洲', '亚洲']
    found_regions = set()
    # 遍历频道消息(最多300条)
    async for msg in client.iter_messages(channel, limit=300):
        if len(found_regions) == len(target_regions):
            break  # 已找到所有目标文件
            
        if not (msg.document and (file_info := extract_file_info(msg))):
            continue
            
        fname, region = file_info
        if region in target_regions and region not in found_regions:
            beijing_time = msg.date + timedelta(hours=8)
            log('blue', 'arrow', f"消息时间: {beijing_time.strftime('%Y-%m-%d %H:%M:%S')} 文件名: {fname}")
            path = os.path.join(DOWNLOAD_DIR, fname)
            if not os.path.exists(path):
                await client.download_media(msg, path)
                log('green', 'check', f"下载完成：{fname}")
            downloaded.add(fname)
            found_regions.add(region)
    
    return downloaded

# 提取文件名信息
def extract_file_info(message_or_filename):
    if isinstance(message_or_filename, str):
        fname = message_or_filename
    else:
        attr = next((a for a in message_or_filename.document.attributes 
                   if isinstance(a, DocumentAttributeFilename)), None)
        if not attr:
            return None
        fname = attr.file_name
    
    # 文件匹配：包含地区名、包含ip、以.txt结尾
    for region in ['欧洲', '美洲', '亚洲']:
        if (region in fname and 
            'ip' in fname.lower() and 
            fname.lower().endswith('.txt')):
            return (fname, region)
    return None

# 重命名文件
async def rename_files(downloaded):
    for fname in downloaded:
        file_info = extract_file_info(fname)
        if not file_info:
            continue
            
        fname, region = file_info
        target = f"ip-{REGION_MAP[region]}.txt"
        target_path = os.path.join(DOWNLOAD_DIR, target)
        
        if os.path.exists(target_path):
            os.remove(target_path)
        os.rename(os.path.join(DOWNLOAD_DIR, fname), target_path)
        log('green', 'check', f"已重命名：{fname} -> {target}")

# 合并所有文件，但保留原始地区文件
async def merge_all_files():
    merge_path = os.path.join(DOWNLOAD_DIR, IP_MERGE)
    log('cyan', 'arrow', f"开始合并最终文件到 {IP_MERGE}...")
    
    try:
        with open(merge_path, 'w', encoding='utf-8') as merge_f:
            # 遍历目录中所有ip-开头的txt文件(排除合并文件自身)
            for fname in os.listdir(DOWNLOAD_DIR):
                if fname.endswith('.txt') and fname.startswith('ip-') and fname != IP_MERGE:
                    file_path = os.path.join(DOWNLOAD_DIR, fname)
                    with open(file_path, 'r', encoding='utf-8') as region_f:
                        if content := region_f.read().strip():
                            merge_f.write(content + '\n')
                    log('green', 'check', f"已合并：{fname}")
        
        log('cyan', 'arrow', "成功合并所有地区文件")
        
    except Exception as e:
        log('red', 'error', f"文件合并失败: {str(e)}")
        # 清理不完整文件
        if os.path.exists(merge_path):
            os.remove(merge_path)

# 清理不符合命名规则的txt文件
async def clean_files():
    for fname in os.listdir(DOWNLOAD_DIR):
        if fname.endswith('.txt') and not fname.startswith('ip-'):
            try:
                os.remove(os.path.join(DOWNLOAD_DIR, fname))
                log('yellow', 'warning', f"已清理：{fname}")
            except Exception as e:
                log('red', 'error', f"清理失败：{fname} - {str(e)}")

if __name__ == '__main__':
    log('cyan', 'arrow', "开始下载ip库...")
    asyncio.run(main())
    log('green', 'check', f"任务完成！文件保存在：{os.path.abspath(DOWNLOAD_DIR)}")
