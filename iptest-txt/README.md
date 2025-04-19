## 一键测速并上传到git仓库

### 先安装依赖库
```py
pip install telethon pysocks
```

### linux 系统
```bash
python3 downip.py && bash formatip.sh && bash ipspeedtest.sh && bash uploadcsv.sh && echo "✅ 所有任务执行完成！"
```

### win 系统
安装依赖 `pip install telethon pysocks`
先安装 gitbash 和 curl
再运行 run.bat  

### IP 库
ip库来自tg频道：https://t.me/Marisa_kristi

### 测速软件
https://github.com/bh-qt/Cloudflare-IP-SpeedTest  
测速结果 csv 文件全汉化
