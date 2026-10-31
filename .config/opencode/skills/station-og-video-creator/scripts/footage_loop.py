"""Seamless preview loop from real footage: crop, then blend the clip's tail into its head.

usage: footage_loop.py <clip.mp4> <out_dir> <x> <y> <width> [loop_seconds=4] [blend_seconds=1] [fps=25]
"""
import subprocess, sys, tempfile
from pathlib import Path
from PIL import Image

clip, out_dir = sys.argv[1], Path(sys.argv[2])
x, y, w = map(int, sys.argv[3:6])
loop_s = float(sys.argv[6]) if len(sys.argv) > 6 else 4
blend_s = float(sys.argv[7]) if len(sys.argv) > 7 else 1
FPS = int(sys.argv[8]) if len(sys.argv) > 8 else 25
h = round(w * 630 / 1200)
out_dir.mkdir(parents=True, exist_ok=True)

with tempfile.TemporaryDirectory() as raw:
    subprocess.run(["ffmpeg", "-loglevel", "error", "-i", clip, "-t", str(loop_s + blend_s),
                    "-vf", f"fps={FPS},crop={w}:{h}:{x}:{y},scale=1200:630:flags={'neighbor' if w < 1200 else 'lanczos'}",
                    f"{raw}/%04d.png"], check=True)
    frames = sorted(Path(raw).glob("*.png"))
    loop, blend = int(loop_s * FPS), int(blend_s * FPS)
    assert len(frames) >= loop + blend, f"clip too short: {len(frames)} frames"
    for t in range(loop):
        frame = Image.open(frames[t]).convert("RGB")
        if t < blend:
            frame = Image.blend(Image.open(frames[t + loop]).convert("RGB"), frame, t / blend)
        frame.save(out_dir / f"{t:04d}.png")
