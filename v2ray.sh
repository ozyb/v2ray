#!/bin/bash

systemctl stop firewalld
systemctl disable firewalld
systemctl stop ufw
systemctl disable ufw
#安装v2
bash <(curl -L -s https://install.direct/go.sh)

#生成随机整数，用来生成端口
rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))  
}

#获取本机外网ip
serverip=$(curl ipv4.icanhazip.com)
cd /etc/v2ray
rm -f /etc/v2ray/config.json
rm -f /etc/v2ray/meConfig.json

cat > /etc/v2ray/config.json<<-EOF
{
  "log" : {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 11234,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "aaaa",
          "level": 1,
          "alterId": 64
        }
      ]
    },
     "streamSettings": {
     "network": "mkcp",
     "kcpSettings": {
        "mtu": 1350,
        "tti": 20,
        "uplinkCapacity":10,
        "downlinkCapacity": 100,
        "congestion": false,
        "readBufferSize": 2,
        "writeBufferSize": 2,
        "header": {
          "type": "srtp"
        }
      }
    }
  },
  "inboundDetour": [            
  {
    "port": 11234,
    "protocol": "vmess",
    "settings": {
       "clients": [
        {
          "id": "bbbb",
          "level": 1,
          "alterId": 64
        }
     ]
    },
	"streamSettings": {
      "network": "tcp",
      "tcpSettings": {
        "header": { 
          "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": ["application/octet-stream", "application/x-msdownload", "text/html", "application/x-shockwave-flash"],
                "Transfer-Encoding": ["chunked"],
                "Connection": ["keep-alive"],
                "Pragma": "no-cache"
              }
            }
        }
      }
    }
  }
 ],
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  }
}
EOF

#生成并替换uuid，kcp、tcp各一个
kcpuuid=$(cat /proc/sys/kernel/random/uuid)
tcpuuid=$(cat /proc/sys/kernel/random/uuid)
sed -i "s/aaaa/$kcpuuid/;s/bbbb/$tcpuuid/;" config.json

#生成并修改端口
port=$(rand 10000 60000)
sed -i "s/11234/$port/" config.json

#重启prov
systemctl restart v2ray.service

#输出配置到文件
cat > /etc/v2ray/meConfig.json<<-EOF
{
===========KCP配置=============
地址：${serverip}
端口：${port}
uuid：${kcpuuid}
额外id：64
加密方式：aes-128-gcm
传输协议：kcp
别名：mykcp
伪装类型：srtp

===========TCP配置=============
地址：${serverip}
端口：${port}
uuid：${tcpuuid}
额外id：64
加密方式：aes-128-gcm
传输协议：tcp
别名：mytcp
伪装类型：http
}
EOF


#输出配置信息
clear
echo
echo "安装已经完成，开启了kcp和tcp两种模式，客户端可任意选择对应的配置"
echo 
echo "===========KCP配置============="
echo "地址：${serverip}"
echo "端口：${port}"
echo "uuid：${kcpuuid}"
echo "额外id：64"
echo "加密方式：aes-128-gcm"
echo "传输协议：kcp"
echo "别名：mykcp"
echo "伪装类型：none"
echo 
echo "===========TCP配置============="
echo "地址：${serverip}"
echo "端口：${port}"
echo "uuid：${tcpuuid}"
echo "额外id：64"
echo "加密方式：aes-128-gcm"
echo "传输协议：tcp"
echo "别名：mytcp"
echo "伪装类型：none"
echo


