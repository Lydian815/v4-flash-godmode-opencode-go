#!/usr/bin/env bash
set -euo pipefail

# dsh-router-flash 安装脚本
# 把 preset 复制到 ~/.dsh/.agent-presets/router-flash

TARGET="${HOME}/.dsh/.agent-presets/router-flash"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/preset"

if [ ! -f "${SRC}/agent.cordis.yml" ]; then
  echo "错误：找不到 preset/agent.cordis.yml，请在仓库根目录运行本脚本" >&2
  exit 1
fi

mkdir -p "${HOME}/.dsh/.agent-presets"
if [ -d "${TARGET}" ]; then
  echo "已存在 ${TARGET}，将覆盖其中文件"
fi
cp -r "${SRC}" "${TARGET}"

echo "✅ 已安装到 ${TARGET}"
echo ""
echo "接下来请手动编辑 ~/.dsh/settings.yaml，确认包含："
echo ""
echo "  agent-default-model:"
echo "    provider: opencode-go"
echo "    model: deepseek-v4-flash"
echo "    reasoningEffort: max"
echo "  agent-presets:"
echo "    default: router-flash"
echo ""
echo "然后重启 dsh。"
