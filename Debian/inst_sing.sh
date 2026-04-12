#!/usr/bin/env bash
set -euo pipefail

CERT_DIR="/etc/sing-box/certs"
CONFIG_DIR="/etc/sing-box"
CONFIG_FILE="${CONFIG_DIR}/config.json"
SERVICE_FILE="/etc/systemd/system/sing-box.service"
ACME_HOME="${HOME}/.acme.sh"
ACME_SH="${ACME_HOME}/acme.sh"

red()    { echo -e "\033[31m$*\033[0m"; }
green()  { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

check_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    red "请使用 root 运行此脚本。"
    exit 1
  fi
}

check_system() {
  if ! command -v apt >/dev/null 2>&1; then
    red "当前系统不是 Debian/Ubuntu 系，无法使用 apt 自动安装依赖。"
    exit 1
  fi
}

read_inputs() {
  read -rp "请输入用于 ACME 注册的邮箱: " EMAIL
  read -rp "请输入 Cloudflare API Token: " CF_TOKEN
  read -rp "请输入要申请证书的域名: " DOMAIN

  EMAIL="${EMAIL//[$'\r\n']}"
  CF_TOKEN="${CF_TOKEN//[$'\r\n']}"
  DOMAIN="${DOMAIN//[$'\r\n']}"

  if [[ -z "${EMAIL}" || -z "${CF_TOKEN}" || -z "${DOMAIN}" ]]; then
    red "邮箱、Token、域名都不能为空。"
    exit 1
  fi
}

validate_domain() {
  if [[ ! "${DOMAIN}" =~ ^[A-Za-z0-9.-]+$ ]]; then
    red "域名格式看起来不正确：${DOMAIN}"
    exit 1
  fi
}

install_deps() {
  green "安装依赖..."
  apt update
  apt install -y curl socat cron wget ufw

  systemctl enable cron >/dev/null 2>&1 || true
  systemctl restart cron >/dev/null 2>&1 || true

  ufw allow 443/tcp >/dev/null 2>&1 || true
  ufw allow 443/udp >/dev/null 2>&1 || true
  ufw allow 31052/tcp >/dev/null 2>&1 || true
  ufw allow 31052/udp >/dev/null 2>&1 || true
  ufw allow 20811/udp >/dev/null 2>&1 || true
  echo "y" | ufw enable

  if ufw status 2>/dev/null | grep -q "Status: active"; then
    ufw reload
  else
    yellow "UFW 未启用，已跳过 reload。"
  fi
}

install_singbox() {
  green "安装 sing-box ..."
  curl -fsSL https://sing-box.app/install.sh | sh

  SBIN="$(command -v sing-box || true)"
  if [[ -z "${SBIN}" ]]; then
    red "未找到 sing-box 可执行文件。"
    exit 1
  fi

  mkdir -p "${CONFIG_DIR}"
  mkdir -p /var/log/singbox

  UUID="$("${SBIN}" generate uuid)"
  USERNAME="$("${SBIN}" generate rand 8 --base64 | sed 's/=//g')"
  PASSWORD="$("${SBIN}" generate rand 10 --base64 | sed 's/=//g')"

  KEY_FILE="${CERT_DIR}/${DOMAIN}.key"
  CERT_FILE="${CERT_DIR}/${DOMAIN}.fullchain.cer"

  cat > "${CONFIG_FILE}" <<EOF
{
  "log": {
    "level": "trace",
    "output": "/var/log/singbox/sing-box.log",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google-dns",
        "type": "udp",
        "server": "8.8.8.8"
      }
    ]
  },
  "inbounds": [
    {
      "type": "hysteria2",
      "tag": "hy2-in",
      "listen": "::",
      "listen_port": 20811,
      "users": [
        {
          "name": "${USERNAME}",
          "password": "${PASSWORD}"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${DOMAIN}",
        "certificate_path": "${CERT_FILE}",
        "key_path": "${KEY_FILE}"
      },
      "masquerade": "https://bing.com"
    },
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": 31052,
      "users": [
        {
          "uuid": "${UUID}",
          "alterId": 0
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "${DOMAIN}",
        "certificate_path": "${CERT_FILE}",
        "key_path": "${KEY_FILE}"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    }
  ],
  "route": {
    "rules": [
      {
        "inbound": [
          "hy2-in",
          "vmess-in"
        ],
        "outbound": "direct"
      }
    ]
  }
}
EOF

  green "sing-box 配置文件已生成：${CONFIG_FILE}"
  yellow "请保存以下客户端信息："
  echo "  Hysteria2 用户名: ${USERNAME}"
  echo "  Hysteria2 密码: ${PASSWORD}"
  echo "  VMess UUID: ${UUID}"
}

install_acme() {
  if [[ -x "${ACME_SH}" ]]; then
    yellow "检测到 acme.sh 已安装，跳过安装。"
  else
    green "安装 acme.sh ..."
    curl https://get.acme.sh | sh -s email="${EMAIL}"
  fi

  if [[ ! -x "${ACME_SH}" ]]; then
    red "acme.sh 安装失败：未找到 ${ACME_SH}"
    exit 1
  fi

  "${ACME_SH}" --version
}

save_cf_token() {
  local profile_file="/root/.acme_cf_env"

  green "保存 Cloudflare Token 到 ${profile_file} ..."
  cat > "${profile_file}" <<EOF
export CF_Token='${CF_TOKEN}'
EOF

  chmod 600 "${profile_file}"
  yellow "以后手动续期前可执行：source ${profile_file}"
}

issue_cert() {
  green "设置默认 CA 为 Let's Encrypt ..."
  "${ACME_SH}" --set-default-ca --server letsencrypt

  export CF_Token="${CF_TOKEN}"

  green "开始为 ${DOMAIN} 申请证书..."
  "${ACME_SH}" --issue --dns dns_cf -d "${DOMAIN}"
}

install_cert() {
  local key_file="${CERT_DIR}/${DOMAIN}.key"
  local cert_file="${CERT_DIR}/${DOMAIN}.fullchain.cer"

  green "准备证书目录..."
  mkdir -p "${CERT_DIR}"
  chmod 755 "${CERT_DIR}"

  touch "${key_file}" "${cert_file}"
  chown root:root "${key_file}" "${cert_file}"
  chmod 600 "${key_file}"
  chmod 644 "${cert_file}"

  green "安装证书到 ${CERT_DIR} ..."
  "${ACME_SH}" --install-cert -d "${DOMAIN}" \
    --key-file "${key_file}" \
    --fullchain-file "${cert_file}" \
    --reloadcmd "systemctl restart sing-box"

  green "证书安装完成。"
  echo "证书路径: ${cert_file}"
  echo "私钥路径: ${key_file}"
}

config_singbox_service() {
  local sbin
  sbin="$(command -v sing-box || true)"

  if [[ -z "${sbin}" ]]; then
    red "未找到 sing-box，无法生成 service。"
    exit 1
  fi

  cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=${sbin} run -c ${CONFIG_FILE}
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload

  green "检查 sing-box 配置..."
  "${sbin}" check -c "${CONFIG_FILE}"

  systemctl enable sing-box
  systemctl restart sing-box
  systemctl --no-pager --full status sing-box || true
}

main() {
  check_root
  check_system
  read_inputs
  validate_domain
  install_deps
  install_singbox
  install_acme
  save_cf_token
  issue_cert
  install_cert
  config_singbox_service

  green "全部完成。"
  echo "证书文件: ${CERT_DIR}/${DOMAIN}.fullchain.cer"
  echo "私钥文件: ${CERT_DIR}/${DOMAIN}.key"
  echo "配置文件: ${CONFIG_FILE}"
  echo "service 文件: ${SERVICE_FILE}"
}

main "$@"