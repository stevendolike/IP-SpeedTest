# 修改说明
在原版基础上增加了 delay 延迟参数，默认值为 220ms，超过该延迟的 ip 将跳过测速   

## 项目简介
这是一个用于测试 IP 地址延迟和下载速度的工具。它可以从指定的文件中读取 IP 地址和端口，并发进行 TCP 连接测试和 HTTP 请求测试，筛选低于延迟阈值的 IP 并进行下载速度测试，也可通过参数设置仅测延迟不测速。最终将结果写入 CSV 文件。

## 核心功能
- **高并发支持**：可设置并发请求的最大协程数，提高检测效率。
- **数据中心位置识别**：通过 Cloudflare 的 cdn-cgi/trace 接口获取数据中心位置信息。
- **延迟阈值**：支持对 IP 进行延迟测试，并筛选低于默认延迟阈值的数据。（**在原版基础上新增的功能**）
- **下载速度测试**：支持对符合条件的 IP 地址进行下载速度测试。
- **结果导出**：将测试结果导出为 CSV 文件，包含 IP 地址、端口、数据中心、地区、国家、城市、延迟和下载速度等信息（全中文化）。

## 安装说明
### 自行编译
确保你已经安装了 Go 环境，然后使用以下命令编译程序：

```bash
git clone https://github.com/yutian81/IP-SpeedTest.git
cd IP-SpeedTest
go build -o iptest main.go
```

### 下载编译好的软件
根据系统和CPU架构选择：  
https://github.com/yutian81/IP-SpeedTest/releases

## 使用说明
### 全参数运行示例
```bash
./iptest -file=ip.txt -outfile=ip.csv -max=100 -speedtest=5 -speedlimit=10 -delay=220 -url=speed.cloudflare.com/__down?bytes=500000000 -tls=true -tcpurl=www.speedtest.net
```

### 推荐运行示例
```bash
./iptest -file=ip.txt -outfile=ip.csv -max=300 -speedtest=3 -speedlimit=5 -delay=200 -url=spurl.api.030101.xyz/50mb
```

### 参数说明
| 参数 | 描述 |	默认值 |
| ---- | ---- |	----- |
-file	| IP 地址文件名称，格式为 ip port，IP 和端口之间用空格隔开	| ip.txt |
-outfile | 输出文件名称 | ip.csv | 
-max | 并发请求最大协程数 | 100 | 
-delay | 延迟阈值（ms） | 220 | 
-speedtest | 下载测速协程数量，设为 0 禁用测速 | 5 | 
-speedlimit | 最低下载速度（MB/s），低于该速度不写入结果 csv 文件 | 0 | 
-url | 测速文件地址，不需要http或https协议头 | speed.cloudflare.com/__down?bytes=500000000 | 
-tls | 是否启用 TLS | true | 
-tcpurl | TCP 请求地址，不需要http或https协议头 | www.speedtest.net | 

### 关于 -file
**-file**：指定包含 IP 地址和端口的文件路径，默认为 `ip.txt`。  
文件格式为每行一个 `IP 地址和端口`，用`空格`分隔，例如：
```
1.1.1.1 80
2.2.2.2 443
3.3.3.3 8080
```

### 关于 -outfile
**-outfile**：测速后输出的 csv 文件，默认为 `ip.csv`。  
输出内容已全部`中文化`（内置在代码中，不依赖外部 `location.json` 文件 ）示例输出：
```csv
IP地址,端口,TLS,数据中心,地区,国际代码,国家,城市,网络延迟,下载速度MB/s
192.168.1.1,443,true,LAX,北美洲,US,美国,洛杉矶,50 ms,12.34
192.168.1.2,80,false,SIN,亚太,SG,新加坡,新加坡,100 ms,8.76
```

## 注意事项
- 文件描述符限制：在 Linux 系统上，如果以 root 用户运行，程序会尝试提升文件描述符的上限。如果你遇到文件描述符不足的问题，请确保以 root 用户运行程序。
- 测速文件：默认使用的是 Cloudflare 500m 的测速文件，为了提高测速效率，可以使用其他测速地址，如mingyu大佬的`spurl.api.030101.xyz/50mb`。
- 延迟阈值：通过 `-delay` 参数可以过滤掉延迟较高的 IP 地址，确保只测试低延迟的 IP。

## 依赖
Go 1.16 或更高版本。

## 许可证
本项目基于 MIT 许可证开源。  
本软件按 "原样" 提供，没有任何形式的明示或暗示保证，包括但不限于适销性保证、特定用途适用性保证和非侵权保证。在任何情况下，作者或版权所有者均不对任何索赔、损害或其他责任负责，无论是在合同、侵权或其他方面，由于或与软件或使用或其他交易中的软件产生或与之相关的操作。
