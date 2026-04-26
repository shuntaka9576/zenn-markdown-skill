#!/usr/bin/env bash
# zenn-embed.sh <url>
#
# 1 行 1 URL を引数または stdin で受け取り、対応する Zenn 埋め込み記法に変換して出力する。
#
# Zenn の埋め込みは「裸 URL を単独行に置けば自動で埋め込みになるサービス」と
# 「@[サービス](URL) で明示する必要があるサービス」と「@[サービス](id) のように
# URL から id を取り出す必要があるサービス」の 3 種類がある。
#
#   裸 URL のままで OK : Twitter / X / YouTube / GitHub
#   @[…](URL) 必要     : CodePen / JSFiddle / StackBlitz / Figma / Gist
#   id 取得必要        : SpeakerDeck（oEmbed で embed_id を取得）
#
# 未対応の URL はそのまま素通し（Zenn のリンクカードにレンダリングされる）。
#
# usage:
#   scripts/zenn-embed.sh https://speakerdeck.com/<user>/<deck>
#   echo https://twitter.com/<user>/status/<id> | scripts/zenn-embed.sh
#   awk '/^https?:/' draft.md | scripts/zenn-embed.sh   # 単独行 URL を一括変換
#
# exit codes:
#   0  すべての URL を処理した（SpeakerDeck で oEmbed 失敗時は元 URL を素通し）
#   2  引数も stdin も与えられなかった

set -euo pipefail

err() { printf '%s\n' "$*" >&2; }

convert_one() {
  local url="$1"
  local host id encoded oembed
  host=$(printf '%s\n' "$url" | awk -F/ 'NF >= 3 { print tolower($3) }')

  case "$host" in
    speakerdeck.com)
      encoded=$(printf '%s' "$url" | jq -sRr '@uri')
      oembed=$(curl -sS --max-time 10 "https://speakerdeck.com/oembed.json?url=$encoded" 2>/dev/null || true)
      id=$(printf '%s' "$oembed" \
        | jq -r '.html // empty' 2>/dev/null \
        | grep -oE '/player/[a-f0-9]+' \
        | head -1 \
        | sed 's|^/player/||')
      if [ -n "$id" ]; then
        printf '@[speakerdeck](%s)\n' "$id"
      else
        err "warn: speakerdeck oEmbed failed for $url — leaving URL as-is"
        printf '%s\n' "$url"
      fi
      ;;
    twitter.com|x.com|mobile.twitter.com|mobile.x.com)
      # Twitter / X は単独行 URL でそのまま埋め込みになる
      printf '%s\n' "$url"
      ;;
    www.youtube.com|youtube.com|m.youtube.com|youtu.be)
      # YouTube も単独行 URL で自動埋め込み
      printf '%s\n' "$url"
      ;;
    codepen.io)
      printf '@[codepen](%s)\n' "$url"
      ;;
    www.figma.com|figma.com)
      printf '@[figma](%s)\n' "$url"
      ;;
    gist.github.com)
      printf '@[gist](%s)\n' "$url"
      ;;
    jsfiddle.net)
      printf '@[jsfiddle](%s)\n' "$url"
      ;;
    stackblitz.com)
      printf '@[stackblitz](%s)\n' "$url"
      ;;
    github.com)
      # GitHub のファイル URL は単独行のままで Zenn が埋め込みレンダリングする
      printf '%s\n' "$url"
      ;;
    *)
      # 不明なホスト → そのまま（Zenn のリンクカード扱い）
      printf '%s\n' "$url"
      ;;
  esac
}

if [ "$#" -gt 0 ]; then
  for u in "$@"; do
    convert_one "$u"
  done
elif [ ! -t 0 ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    convert_one "$line"
  done
else
  err "usage: $0 <url> [<url> ...]   # or pipe URLs on stdin"
  exit 2
fi
