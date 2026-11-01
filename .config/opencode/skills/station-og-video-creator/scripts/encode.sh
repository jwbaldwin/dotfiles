#!/bin/zsh
# encode.sh <input video or frame pattern> <output name> [fps]
# Crops 16:9 art to the 1200x630 preview size and writes <name>.mp4, <name>.jpg, and <name>.gif for review.
set -e
input=$1; name=$2; fps=${3:-12}
crop="crop=iw:iw*630/1200:0:(ih-iw*630/1200)/2,scale=1200:630:flags=lanczos"
if [[ $input == *%* ]]; then src=(-framerate $fps -i $input); else src=(-i $input); fi
ffmpeg -y -loglevel error $src -an -vf "$crop,fps=24,format=yuv420p" -c:v libx264 -crf 26 -preset slow -movflags +faststart $name.mp4
ffmpeg -y -loglevel error -i $name.mp4 -vf "select=eq(n\,0)" -frames:v 1 -q:v 3 $name.jpg
ffmpeg -y -loglevel error -i $name.mp4 -vf "fps=12,scale=600:-1:flags=neighbor,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=none" $name.gif
ls -la $name.mp4 $name.jpg $name.gif | awk '{print $5, $9}'
