#!/usr/bin/env bash
# makepkg download agent for blackmagic://<downloadId> sources.
# Uses the "Download only" flow of blackmagicdesign.com (no registration):
#   POST /api/register/<country>/download/<downloadId> -> signed URL (~3h expiry)
#   GET  <signed URL>
#
# Usage (from DLAGENTS): blackmagic-download.sh blackmagic://<downloadId> <output>
set -euo pipefail

url=${1:?missing url}
out=${2:?missing output file}
download_id=${url#blackmagic://}
download_id=${download_id%%/*}
[[ $download_id =~ ^[0-9a-f]{32}$ ]] || { echo "invalid download id: $download_id" >&2; exit 1; }

country=${BLACKMAGIC_COUNTRY:-gb}
ua='Mozilla/5.0 (X11; Linux x86_64; rv:156.0) Gecko/20100101 Firefox/156.0'
base='https://www.blackmagicdesign.com'

body='{"platform":"Linux","policy":true,"product":{"name":"DaVinci Resolve Studio"},"country":"'"$country"'","downloadOnly":true,"origin":"www.blackmagicdesign.com"}'

signed=$(curl -fsS -A "$ua" \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Content-Type: application/json;charset=utf-8' \
  -H "Origin: $base" -H "Referer: $base/products/davinciresolve" \
  --data "$body" "$base/api/register/$country/download/$download_id")
[[ $signed == https://* ]] || { echo "unexpected response from Blackmagic: $signed" >&2; exit 1; }

exec curl -fL -C - --retry 3 --retry-delay 3 -A "$ua" --referer "$base/" -o "$out" "$signed"
