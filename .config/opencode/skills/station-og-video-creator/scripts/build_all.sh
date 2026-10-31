#!/bin/zsh
# build_all.sh <station dir> — one loop candidate per clip, letterbox removed, plus a seam report.
dir=$1; mkdir -p $dir/out
here=${0:A:h}; py=${PYTHON:-python3}
for clip in $dir/video/*.mp4; do
  id=${clip:t:r}
  fps=$(ffprobe -v error -show_entries stream=r_frame_rate -of csv=p=0 $clip | head -1); fps=$(( ${fps%/*} / ${fps#*/} ))
  read w h x y <<< $(ffmpeg -loglevel info -i $clip -t 3 -vf cropdetect=24:2:0 -f null - 2>&1 | grep -o "crop=[0-9:]*" | tail -1 | sed 's/crop=//;s/:/ /g')
  cw=$(( h * 1200 / 630 )); if (( cw > w )); then cw=$w; fi
  ch=$(( cw * 630 / 1200 ))
  cx=$(( x + (w - cw) / 2 )); cy=$(( y + (h - ch) / 2 ))
  rm -rf $dir/frames-$id
  $py -I $here/footage_loop.py $clip $dir/frames-$id $cx $cy $cw 4 1 $fps || continue
  (cd $dir/out && $here/encode.sh "../frames-$id/%04d.png" $id $fps >/dev/null)
done
$py -I - $dir <<'PY'
import glob, sys
from PIL import Image, ImageChops, ImageStat
def d(a, b): return sum(ImageStat.Stat(ImageChops.difference(Image.open(a).convert('RGB').resize((400, 210)), Image.open(b).convert('RGB').resize((400, 210)))).mean) / 3
for frames in sorted(glob.glob(sys.argv[1] + '/frames-*')):
    fs = sorted(glob.glob(frames + '/*.png'))
    steps = [d(fs[i], fs[i + 1]) for i in range(0, len(fs) - 1, 2)]
    print(frames.split('frames-')[1], 'typical %.2f max %.2f seam %.2f' % (sum(steps) / len(steps), max(steps), d(fs[-1], fs[0])))
PY
