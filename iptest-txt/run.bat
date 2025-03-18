@echo off
chcp 65001 >nul

rem 检查 Git 是否安装
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未找到 Git，请先安装 Git。
    pause
    exit /b 1
)

rem 检查 Python 是否安装
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误：未找到 Python，请先安装 Python。
    pause
    exit /b 1
)

rem 下载IP库
echo 正在下载IP库...
py "./downip.py"
if %errorlevel% neq 0 (
    echo 下载IP库失败，请检查以下内容：
    echo 1. 确保 downip.py 脚本存在且可执行。
    echo 2. 检查网络连接是否正常。
    echo 3. 确认 Telegram 频道的 API 配置是否正确。
    pause
    exit /b 1
)
timeout /t 5 /nobreak >nul

rem 格式化IP库
echo 正在格式化IP库...
"D:\Program Files\Git\bin\bash.exe" -c "./formatip.sh"
if %errorlevel% neq 0 (
    echo 格式化IP库失败，请检查以下内容：
    echo 1. 确保 formatip.sh 脚本存在且可执行。
    echo 2. 确认输入文件夹 ip 是否存在且包含有效的文件。
    pause
    exit /b 1
)
timeout /t 5 /nobreak >nul

rem 开始测速
echo 正在测速...
"D:/Program Files/Git/bin/bash.exe" -c "./ipspeedtest.sh"
if %errorlevel% neq 0 (
    echo 测速失败，请检查以下内容：
    echo 1. 确保 ipspeedtest.sh 脚本存在且可执行。
    echo 2. 检查网络连接是否正常。
    pause
    exit /b 1
)
timeout /t 5 /nobreak >nul

rem 提示用户确认是否执行上传脚本
:confirm_prompt
set /p confirm=是否将测速结果文件提交到 git (Y/N)? 
if "%confirm%" == "" (
    echo 输入无效，请输入 Y 或 N。
    goto confirm_prompt
)
set confirm=%confirm:~0,1%
if /i "%confirm%" == "Y" (
    echo 正在上传测速结果...
    "D:/Program Files/Git/bin/bash.exe" -c "./uploadcsv.sh"
    if %errorlevel% neq 0 (
        echo 上传失败，请检查以下内容：
        echo 1. 确保 uploadcsv.sh 脚本存在且可执行。
        echo 2. 检查网络连接是否正常。
        echo 3. 确认 GitHub Token 和仓库配置是否正确。
    ) else (
        echo 提交成功！
    )
) else if /i "%confirm%" == "N" (
    echo 已取消提交操作。
) else (
    echo 输入无效，请输入 Y 或 N。
    goto confirm_prompt
)

echo.
echo 按任意键退出...
pause >nul