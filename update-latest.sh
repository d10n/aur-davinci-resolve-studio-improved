#!/usr/bin/env bash
# Maintainer helper: bump PKGBUILD to the latest stable DaVinci Resolve Studio
# for Linux, then refresh checksums and .SRCINFO.
#   GET /api/support/latest-stable-version/davinci-resolve-studio/linux -> downloadId + version
#
# Usage: ./update-latest.sh [--check]   (--check only prints the latest version)
set -euo pipefail
cd "$(dirname "$0")"

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

ua='Mozilla/5.0 (X11; Linux x86_64; rv:156.0) Gecko/20100101 Firefox/156.0'
info=$(curl -fsS -A "$ua" -H 'Accept: application/json' \
  'https://www.blackmagicdesign.com/api/support/latest-stable-version/davinci-resolve-studio/linux' | jq -e .linux)
download_id=$(jq -r .downloadId <<<"$info")
# Vendor file names drop a zero release number: 21.2, but 21.1.1
version=$(jq -r 'if .releaseNum == 0 then "\(.major).\(.minor)" else "\(.major).\(.minor).\(.releaseNum)" end' <<<"$info")
[[ $download_id =~ ^[0-9a-f]{32}$ && $version =~ ^[0-9]+(\.[0-9]+)+$ ]] \
  || { echo "unexpected API response: $info" >&2; exit 1; }

current=$(sed -n 's/^pkgver=//p' PKGBUILD)
echo "latest: $version (build $(jq -r .build <<<"$info"), downloadId $download_id); PKGBUILD: $current"
[[ ${1:-} == --check ]] && exit 0

if [[ $version == "$current" ]] && grep -q "^_downloadid='$download_id'$" PKGBUILD; then
  echo "already up to date"
  exit 0
fi

sed -i -e "s/^pkgver=.*/pkgver=$version/" \
       -e "s/^_downloadid=.*/_downloadid='$download_id'/" PKGBUILD
[[ $version == "$current" ]] || sed -i 's/^pkgrel=.*/pkgrel=1/' PKGBUILD

updpkgsums          # downloads the new zip through the blackmagic:// agent
makepkg --printsrcinfo > .SRCINFO
echo "updated to $version; review with: git diff"
