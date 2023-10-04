#!/bin/bash



BOT_API="6561669929:AAEQ4OAI5t-Nbb7cLs2lI002n6GCzuyBod8"
CHATID="6127364024"
TIME=10
NOW=$(date +"%Y-%m-%d %T")
PKG="vnstat"
ARG1="-tr"
ARG2="--json"
ARG3="cut -d. -f1"
ARG4="cut -d ' ' -f2"
RATE="Mbit/s"
MB="MiB"
GB="GiB"
TB="TiB"
LIMIT_TB=3
LIMIT_GB=500
STATUS_TB="on"
STATUS_GB="on"
STATUS_MB="off"
JSON_RX="jq -r .rx.ratestring"
JSON_TX="jq -r .tx.ratestring"
MYIP=$(wget -qO- ipinfo.io/ip)


function Sys_Init() {
cat > /etc/systemd/system/bw-usage.service <<-END
[Unit]
Description=bw-usage by Potato
After=syslog.target network-online.target

[Service]
User=root
ExecStart=/etc/bw-usage
Restart=on-failure

[Install]
WantedBy=multi-user.target
END
}

function File_Sys() {
  if [[ ! -e /etc/systemd/system/bw-usage.service ]]; then
cat > /etc/bw-usage <<-END
#!/bin/bash

for (( ; ; ))
do
  bw-usage
  sleep 6h
done
END
    chmod 777 /etc/bw-usage
    Sys_Init
    systemctl daemon-reload
    systemctl -q enable bw-usage
    systemctl -q start bw-usage
  fi
}

function sendToBotUwu() {
  TEXT="Traffic at ${NOW}
================
IP : ${MYIP}
================
RX    : ${RX}
TX    : ${TX}
----------------
TOTAL : ${TOTAL}
Quota : 3 TB
================
TRAFFIC RX : ${TRAFFIC_RX}
TRAFFIC TX : ${TRAFFIC_TX}
================"
  URL="https://api.telegram.org/bot${BOT_API}/sendMessage"
  curl -s --max-time ${TIME} -d "chat_id=${CHATID}&disable_web_page_preview=1&text=${TEXT}&parse_mode=html" ${URL} >/dev/null
}

function Check_Usage() {
  TOTAL=$(vnstat --oneline | cut -d ';' -f6)
  RX=$(vnstat --oneline | cut -d ';' -f4)
  TX=$(vnstat --oneline | cut -d ';' -f5)
  TRAFFIC_RX=$(${PKG} ${ARG1} ${TIME} ${ARG2} | ${JSON_RX})
  TRAFFIC_TX=$(${PKG} ${ARG1} ${TIME} ${ARG2} | ${JSON_TX})
  sendToBotUwu
}

function This_Is_A_Limit() {
  File_Sys
  Check_Usage
  sleep 10
  if [[ ${STATUS_TB} == 'on' ]]; then
    STAT=$(vnstat --oneline | cut -d ';' -f6 | cut -d ' ' -f2)
    if [[ ${STAT} == ${TB} ]]; then
      STAT=$(vnstat --oneline | cut -d ';' -f6 | cut -d. -f1)
      if [[ ${STAT} -gt ${LIMIT_TB} ]]; then
        poweroff
        echo "ente set aja di sini mau shutdown atau engga"
        echo "man shutdown"
      fi
    fi
  fi
}


This_Is_A_Limit
