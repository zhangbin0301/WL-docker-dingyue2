#!/bin/bash

# ===========================================设置相关参数=============================================
FLIE_PATH="/app/"
#设置参数
export SUB_KEY=${NEZHA_KEY:-'key123456'}
NEZHA_PORT=${NEZHA_PORT:-'443'}
NEZHA_TLS=${NEZHA_TLS:-'1'}

# 设置是否打印日志,no不打印 
RIZHI=${RIZHI:-'yes'}
PORT=${PORT:-'8080'}
#设置app参数
export SUB_NAME=${SUB_NAME:-'local'}
export UUID=${UUID:-'fd80f56e-93f3-4c85-b2a8-c77216c509a7'}
export VPATH=${VPATH:-'vls'}
export MPATH=${MPATH:-'vms'}
export SERVER_PORT=${SERVER_PORT:-'8010'}
if [ -n "$SPACE_HOST" ]; then
    export CF_IP=$SPACE_HOST
else
    export CF_IP=${CF_IP:-'ip.sb'}
fi
# ===========================================运行程序=============================================
# 运行nezha
run_nez() {
[ "${NEZHA_TLS}" = "1" ] && TLS='--tls'
if [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_KEY}" && -s "${FLIE_PATH}nezha.js" ]]; then
chmod +x ${FLIE_PATH}nezha.js
nohup ${FLIE_PATH}nezha.js -s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${TLS} >/dev/null 2>&1 &
fi
}
# 运行bot
run_bot() {
if [[ -z "${BOT}"  && -s "${FLIE_PATH}bot.js" ]]; then
chmod +x ${FLIE_PATH}bot.js
nohup ${FLIE_PATH}bot.js >/dev/null 2>&1 &
fi
}
# 运行argo
run_arg() {
[ -s ${FLIE_PATH}argo.log  ] && rm -rf ${FLIE_PATH}argo.log
if [[ -n "${TOK}" ]]; then
chmod +x ${FLIE_PATH}cff.js
TOK=$(echo ${TOK} | sed 's@cloudflared.exe service install ey@ey@g')
    if [[ "${TOK}" =~ TunnelSecret ]]; then
      echo "${TOK}" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > ${FLIE_PATH}tunnel.json
      cat > ${FLIE_PATH}tunnel.yml << EOF
tunnel: $(sed "s@.*TunnelID:\(.*\)}@\1@g" <<< "${TOK}")
credentials-file: ${FLIE_PATH}tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:8002
EOF
      cat >> ${FLIE_PATH}tunnel.yml << EOF
  - service: http_status:404
EOF
      nohup ${FLIE_PATH}cff.js tunnel --edge-ip-version auto --config ${FLIE_PATH}tunnel.yml run >/dev/null 2>&1 &
    elif [[ ${TOK} =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      nohup ${FLIE_PATH}cff.js tunnel --edge-ip-version auto --protocol http2 run --token ${TOK} >/dev/null 2>&1 &
    fi
else
 if [ -z "$SPACE_HOST" ]; then
   if [[ -z "${CF_DOMAIN}" ]]; then
   [ -s ${FLIE_PATH}argo.log  ] && rm -rf ${FLIE_PATH}argo.log
   nohup ${FLIE_PATH}cff.js tunnel --edge-ip-version auto --no-autoupdate --protocol http2 --logfile ${FLIE_PATH}argo.log --loglevel info --url http://localhost:8002 2>/dev/null 2>&1 &
   sleep 10

  [ -s ${FLIE_PATH}argo.log ] && export ARGO_DOMAIN=$(cat ${FLIE_PATH}argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)

  fi
 fi
  fi
}

# 运行nginx
run_nginx() {
sed -i 's#\${PORT}#'"${PORT}"'#g' ${FLIE_PATH}nginx.conf
sed -i 's#\${UUID}#'"${UUID}"'#g' ${FLIE_PATH}nginx.conf
sed -i 's#\${VPATH}#'"${VPATH}"'#g' ${FLIE_PATH}nginx.conf
sed -i 's#\${MPATH}#'"${MPATH}"'#g' ${FLIE_PATH}nginx.conf
sed -i 's#\${NEZHA_KEY}#'"${NEZHA_KEY}"'#g' ${FLIE_PATH}nginx.conf
sed -i 's#\${SERVER_PORT}#'"${SERVER_PORT}"'#g' ${FLIE_PATH}nginx.conf
cp -rf ${FLIE_PATH}ADSTERTRN6456Q65525421Q3ASFDA321.html ${FLIE_PATH}${UUID}.html
cp -rf ${FLIE_PATH}nginx.conf /etc/nginx/nginx.conf
nohup nginx -g 'daemon off;' >/dev/null 2>&1 &
}
# 运行app
run_app() {
chmod +x ${FLIE_PATH}app.js
nohup ${FLIE_PATH}app.js >/dev/null 2>&1 &
}

run_nez
run_bot
run_arg
sleep 10

if [ -n "$SPACE_HOST" ]; then
    export ARGO_DOMAIN=$SPACE_HOST
    export URL_HOST="https://$SPACE_HOST"
else
    export URL_HOST="空间网址"
fi
run_app
run_nginx
# ===================================
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "***************************************************"
[ "$RIZHI" = "yes" ] && echo "       ${URL_HOST}/${UUID}2 查看使用说明               "
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "       ${URL_HOST}/upload-${UUID} 订阅上传地址               "
[ "$RIZHI" = "yes" ] && echo "                                                 "

[ "$RIZHI" = "yes" ] && echo "       ${URL_HOST}/sub2-${NEZHA_KEY} 订阅地址               "
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "       ${URL_HOST}/info 系统信息               "
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "       ${URL_HOST}/listen 监听端口               "
[ "$RIZHI" = "yes" ] && echo "                                                 "
[ "$RIZHI" = "yes" ] && echo "***************************************************"

# 上传订阅
upload_url_data() {
    if [ $# -lt 3 ]; then
        return 1
    fi

    UPLOAD_URL="$1"
    URL_NAME="$2"
    URL_TO_UPLOAD="$3"

    # 检查curl命令是否存在
    if command -v curl &> /dev/null; then

       curl -s -o /dev/null -X POST -H "Content-Type: application/json" -d "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" "$UPLOAD_URL"

    # 检查wget命令是否存在
    elif command -v wget &> /dev/null; then

        echo "{\"URL_NAME\": \"$URL_NAME\", \"URL\": \"$URL_TO_UPLOAD\"}" | wget --quiet --post-data=- --header="Content-Type: application/json" "$UPLOAD_URL" -O -

    else
        echo "Both curl and wget are not installed. Please install one of them to upload data."
    fi
}

# ===========================================显示进程信息=============================================
if command -v ps -ef >/dev/null 2>&1; then
   fps='ps -ef'
elif command -v pgrep -lf >/dev/null 2>&1; then
   fps='pgrep -lf'
fi
#================运行进程守护程序===========
# 检测bot
function check_bot(){
  count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] &&  echo "----- 检测到bot未运行，重启应用...----- ."
  run_bot
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "bot is running......"
fi
}

# 检测CF
function check_cf (){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到Argo未运行，重启应用...----- ."
   run_arg
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "Argo is running......"
fi
}
# 检测nezha
function check_nezha(){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到nezha未运行，重启应用...----- ."
  run_nez
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "nezha is running......" 
fi
}
# 检测app
function check_app(){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到app未运行，重启应用...----- ."
  run_app
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "app is running......" 
fi
}

# 检测nginx
function check_nginx(){
 count=$(${fps} |grep $1 |grep -v "grep" |wc -l)
if [ 0 = $count ];then
  # count 为空
[ "$RIZHI" = "yes" ] && echo "----- 检测到nginx未运行，重启应用...----- ."
  run_nginx
else
  # count 不为空
[ "$RIZHI" = "yes" ] && echo "nginx is running......" 
fi
}

process_subscription() {
    local subscription_var="$1"
    local output_file="$2"
    if [[ -n "${!subscription_var}" ]]; then
        local xray_subscriptions="${!subscription_var}"
        local merged_subscription=""
        IFS=";" read -ra urls <<< "$xray_subscriptions"
        for url in "${urls[@]}"
        do
     if [[ "$url" == "vmess://"* ]]; then
         if [ -n "${CF_IP1}" ]; then
        encoded_url="${url#vmess://}"
        decoded_url=$(echo "$encoded_url" | base64 -d)
        modified_url="${decoded_url//YOUXUAN_IP/$CF_IP1}"
        modified_url="${modified_url//ip.sb/$CF_IP1}"
        echo "Modified URL: $modified_url"
        re_encoded_url=$(echo -n "$modified_url" | base64 -w 0)
        new_url="vmess://$re_encoded_url"
        echo "${new_url}" >> "/app/tmp${output_file}"
         else
          echo "${url}" >> "/app/tmp${output_file}"
          fi
          elif [[ "$url" == "https://"* || "$url" == "http://"* ]]; then         
                local subscription_content=$(curl -s -m 10 "$url")
                if [ -n "$subscription_content" ]; then
                local decoded_content=$(echo -n "$subscription_content" | base64 -d)
                  if [ -n "$decoded_content" ]; then
                   echo "${decoded_content}" >> "/app/tmp${output_file}"
                  else
                   echo "解码订阅地址 $url 内容失败"
                  fi
                else
                    echo "获取订阅地址 $url 内容失败"
                 fi
           else         
               echo "${url}" >> "/app/tmp${output_file}"
            fi
        done
        if [ -n "${CF_IP1}" ]; then
         sed -i "s#YOUXUAN_IP#${CF_IP1}#g" "/app/tmp${output_file}"
         sed -i "s#ip.sb#${CF_IP1}#g" "/app/tmp${output_file}"
        fi

        if [ -n "$SPACE_HOST" ]; then
        echo "${V_URL}" >> "/app/tmp${output_file}"
        fi
        sed -i 's/{PASS}-//g' "/app/tmp${output_file}"
        sed -i 's#{PASS}#vless#g' "/app/tmp${output_file}"
        # 对合并后的订阅内容进行Base64编码
        local encoded_merged_subscription=$(cat "/app/tmp${output_file}" | base64)
        echo -e "$encoded_merged_subscription" > "/app/${output_file}"
        rm -rf "/app/tmp${output_file}"
        echo "$1 订阅已更新于 $(date)"
    fi
}

generate_random_time() {
    local time_range=${1:-"10,30"} 
    IFS=',' read -ra range <<< "$time_range"
    local random_time=$((RANDOM % (${range[1]} - ${range[0]} + 1) + ${range[0]}))
    echo "$random_time"
}

get_sub() {
    GH_PAT=${GH_PAT:-''}
    GH_REPO=${GH_REPO:-''}
    BRANCH="main"
    LOCAL_REPO="/app/sub"

    if [ -n "$GH_PAT" ] && [ -n "$GH_REPO" ]; then
        REMOTE_REPO="https://${GH_PAT}@${GH_REPO}"
    elif [ -n "$GH_REPO" ]; then
        REMOTE_REPO="https://${GH_REPO}"
    fi

    git_pull() {
        if [ ! -d "$LOCAL_REPO/.git" ]; then
            # Clone the repository if it doesn't exist
            git clone -b "$BRANCH" "$REMOTE_REPO" "$LOCAL_REPO"
        else
            # Pull the latest changes if the repository exists
            git --git-dir="$LOCAL_REPO/.git" --work-tree="$LOCAL_REPO" pull origin "$BRANCH"
        fi
    }

    # Function to process sub2.yaml
    process_sub2_yaml() {
        SUB2=""
        while IFS= read -r line; do
            # Ignore lines starting with #
            if [[ $line != "#"* ]]; then
                SUB2="$SUB2$line;"
            fi
        done < "$LOCAL_REPO/sub2.yaml"

        # Remove trailing semicolon
        SUB2=${SUB2%;}
    }

    # Function to process cfip.yaml
    process_cfip_yaml() {
        CF_IP1=""
        if [ -f "$LOCAL_REPO/cfip.yaml" ]; then
            # Read the first line of cfip.yaml
            read -r CF_IP1 < "$LOCAL_REPO/cfip.yaml"
        fi
    }

    check_remote_changes() {
        git_pull
        process_sub2_yaml
        process_cfip_yaml
        echo "CF_IP: $CF_IP1"
    }
    if [ -n "$GH_REPO" ]; then
        check_remote_changes
    fi
}
get_sub
counter=0
while true
do
((counter++))
if [ $counter -eq 30 ]; then
   get_sub
   counter=0
fi
if [ -z "$SPACE_HOST" ]; then
CF_IP=${CF_IP1}
fi
if [[ -z "${TOK}" && -z "${CF_DOMAIN}" ]]; then
  [ -s ${FLIE_PATH}argo.log ] && export ARGO_DOMAIN=$(cat ${FLIE_PATH}argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi
V_URL="{PASS}://${UUID}@${CF_IP}:443?host=${ARGO_DOMAIN}&path=%2F${VPATH}%3Fed%3D2048&type=ws&encryption=none&security=tls&sni=${ARGO_DOMAIN}#${SUB_NAME}"

RESPONSE=$(curl -s http://localhost:${SERVER_PORT}/get-${UUID})


if [ $? -ne 0 ]; then
  echo "Curl request failed. Exiting."
fi


if [ -z "$RESPONSE" ]; then
  echo "Empty response received. Exiting."
fi

export SUB=$(echo "$RESPONSE" | jq -r '.urls[]' 2>/dev/null | paste -s -d ';')
export SUB_12=""
vars=("$SUB" "$SUB2")
for var in "${vars[@]}"; do
if [ -n "$var" ]; then
   if [ -n "$SUB_12" ]; then
       export SUB_12="$SUB_12;$var"
   else
      export SUB_12="$var"
   fi
fi
done
if [ -z "$SPACE_HOST" ]; then
export SUB_12="${V_URL};$SUB_12"
fi
# 设置检测间隔
interval=$(generate_random_time "$TIME")

# 处理订阅
process_subscription "SUB_12" "sub2.txt"
[ -s ${FLIE_PATH}bot.js ] && [ -z "${BOT}" ] && check_bot bot.js
  sleep 5
  if [ -z "$SPACE_HOST" ]; then
  [ -s ${FLIE_PATH}cff.js ] && [ -n "${TOK}" ] && check_cf cff.js
  fi
  sleep 5
  [ -s ${FLIE_PATH}nezha.js ] && [ -n "${NEZHA_KEY}" ] && check_nezha nezha.js
  sleep 5
  [ -s ${FLIE_PATH}app.js ] && check_app app.js
  sleep 5
  check_nginx nginx
[ "$RIZHI" = "yes" ] && echo "完成一轮检测，$interval秒后进入下一轮检测"
if [ -z "$SPACE_HOST" ]; then
[ -s ${FLIE_PATH}argo.log  ] && export ARGO_DOMAIN=$(cat ${FLIE_PATH}argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
fi
sleep "$interval"    
done
