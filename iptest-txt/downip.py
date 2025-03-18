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
API_ID = '65665665'
API_HASH = '6657dgdhjgt75757ufhfhfhfh'
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

def log(color, symbol, message):
    """日志函数"""
    print(f"{COLORS[color]}{SYMBOLS[symbol]} {message}{COLORS['reset']}")

async def main():
    """主逻辑优化版"""
    # 初始化环境
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    today = datetime.now().strftime("%Y%m%d")
    yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y%m%d")
    
    async with TelegramClient('tg_session', API_ID, API_HASH, proxy=PROXY) as client:
        # 获取频道消息
        channel = await client.get_entity(CHANNEL)
        log('cyan', 'arrow', f"已连接频道：{channel.title}")

        downloaded = await fetch_files(client, channel, today, yesterday)  # 下载有效文件
        await rename_files(downloaded, today, yesterday)  # 处理文件重命名
        await merge_all_files()  # 合并所有ip库
        await clean_files()  # 清理残留文件

async def fetch_files(client, channel, today, yesterday):
    """智能下载文件"""
    downloaded = set()
    
    async for msg in client.iter_messages(channel, limit=300):
        if not (msg.document and (file_info := extract_file_info(msg))): 
            continue
            
        fname, date, region = file_info
        if date in (today, yesterday) and region in REGION_MAP:
            path = os.path.join(DOWNLOAD_DIR, fname)
            if not os.path.exists(path):
                await client.download_media(msg, path)
                log('green', 'check', f"下载完成：{fname}")
            downloaded.add(fname)
    
    return downloaded

def extract_file_info(message_or_filename):
    """提取文件名信息"""
    if isinstance(message_or_filename, str):
        fname = message_or_filename
    else:
        if not (attr := next((a for a in message_or_filename.document.attributes 
                            if isinstance(a, DocumentAttributeFilename)), None)):
            return None
        fname = attr.file_name
    
    # 匹配文件名中的日期和地区信息
    match = re.match(r"([\u4e00-\u9fa5]+)(\d{8})", fname)
    return (fname, match.group(2), match.group(1)) if match and fname.endswith('.txt') else None

async def rename_files(downloaded, today, yesterday):
    """重命名文件：优先使用当前日期文件，否则使用前一天日期文件"""
    for region in REGION_MAP.keys():
        today_file = next((f for f in downloaded if extract_file_info(f)[1] == today and extract_file_info(f)[2] == region), None)
        yesterday_file = next((f for f in downloaded if extract_file_info(f)[1] == yesterday and extract_file_info(f)[2] == region), None)
        
        target = f"ip-{REGION_MAP[region]}.txt"
        target_path = os.path.join(DOWNLOAD_DIR, target)
        
        # 优先重命名当前日期的文件
        if today_file:
            if os.path.exists(target_path):
                os.remove(target_path)
            os.rename(os.path.join(DOWNLOAD_DIR, today_file), target_path)
            log('green', 'check', f"已重命名：{today_file} -> {target}")
            # 删除前一天日期的文件（如果存在）
            if yesterday_file and os.path.exists(os.path.join(DOWNLOAD_DIR, yesterday_file)):
                os.remove(os.path.join(DOWNLOAD_DIR, yesterday_file))
                log('yellow', 'warning', f"已删除前一天文件：{yesterday_file}")
        # 如果当前日期文件不存在，则重命名前一天日期的文件
        elif yesterday_file:
            if os.path.exists(target_path):
                os.remove(target_path)
            os.rename(os.path.join(DOWNLOAD_DIR, yesterday_file), target_path)
            log('green', 'check', f"已重命名：{yesterday_file} -> {target}")

async def merge_all_files():
    """合并所有最终文件，但保留原始地区文件"""
    merge_path = os.path.join(DOWNLOAD_DIR, IP_MERGE)
    log('cyan', 'arrow', f"开始合并最终文件到 {IP_MERGE}...")
    
    try:
        with open(merge_path, 'w', encoding='utf-8') as merge_f:
            # 获取所有地区文件（排除合并文件自身）
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

async def clean_files():
    """清理非目标文件，但保留地区文件"""
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