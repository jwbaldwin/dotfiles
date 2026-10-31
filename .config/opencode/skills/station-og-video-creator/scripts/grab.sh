#!/bin/zsh
# grab.sh <youtube id> <out.mp4> [start_seconds] [height] — 6 s of video; falls back to the live stream.
# Survey at height 480 to save time, then grab the picks at 1080.
id=$1; out=$2; start=${3:-120}; height=${4:-1080}
ytdlp=(${YTDLP:-yt-dlp} --js-runtimes node --no-warnings --socket-timeout 30)
$ytdlp --no-progress -q -f "bv*[height<=$height][vcodec^=avc1]/bv*[height<=$height]" \
  --download-sections "*$start-$((start + 6))" --ffmpeg-location "$(which ffmpeg)" \
  -o "$out" -- "$id" >/dev/null 2>&1
if [[ ! -s $out ]]; then
  url=$($ytdlp -g -f "bv*[height<=$height]/best[height<=$height]" -- "$id" 2>/dev/null | head -1)
  [[ $url == http* ]] && ffmpeg -y -loglevel error -i "$url" -t 6 -an -c:v libx264 -crf 16 "$out"
fi
[[ -s $out ]] && echo "$id ok" || echo "$id FAILED"
