# 需要：CF_API_TOKEN 已 export 到環境
#

# --- 基本參數檢查 ------------------------------------------------------------
if [[ -z "$1" ]]; then
  echo "Usage: $0 <IPv4_or_IPv6>"
  exit 1
fi
IP="$1"

# ------------------------------------------------------------------
set -euo pipefail

# --- 2. 取出所有 Zone ID（自動翻頁） -------------------------------
list_zone_ids() {
  local page=1 total_pages=1

  while (( page <= total_pages )); do
    # 取得當前頁
    RESP=$(curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
            "https://api.cloudflare.com/client/v4/zones?page=${page}&per_page=50")

    printf '[%s] Fetched page %d/%d \n' "$(date +%T)" "$page" "$total_pages" >&2

    # 輸出這一頁的所有 Zone ID
    echo "$RESP" | jq -r '.result[].id'

    # 第一頁時讀出總頁數（result_info.total_pages）
    if (( page == 1 )); then
      total_pages=$(echo "$RESP" | jq '.result_info.total_pages')
    fi

    (( page++ ))
  done
}

list_zone_ids | while read -r ZONE_ID; do
  printf '[%s] Fetched zone %s \n' "$(date +%T)" "$ZONE_ID" >&2
  curl -s -H "Authorization: Bearer $CF_API_TOKEN" \
       "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&content=${IP}" |
  jq -r '.result[] | [.name, .content] | @tsv'
done | column -t
