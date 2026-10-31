"""pixelate.py <frames dir> <out dir> <block size> [colors=48] [saturation=1.0] [mediancut|octree|none] — pixel-art pass with one palette for the whole loop.

Every frame shrinks to a grid of <block>-pixel cells, snaps to a palette built from frames across the
loop (so colors don't flicker), then scales back to 1200x630 with hard edges.
"""
import glob, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance

src, out = Path(sys.argv[1]), Path(sys.argv[2])
block = int(sys.argv[3])
colors = int(sys.argv[4]) if len(sys.argv) > 4 else 48
saturation = float(sys.argv[5]) if len(sys.argv) > 5 else 1.0
method = {"mediancut": Image.Quantize.MEDIANCUT, "octree": Image.Quantize.FASTOCTREE, "none": None}[sys.argv[6] if len(sys.argv) > 6 else "mediancut"]
out.mkdir(parents=True, exist_ok=True)
frames = sorted(glob.glob(str(src / "*.png")))
grid = (round(1200 / block), round(630 / block))

def shrink(path):
    frame = Image.open(path).convert("RGB").resize((grid[0] * block, grid[1] * block), Image.LANCZOS)
    small = np.asarray(frame.resize(grid, Image.LANCZOS), dtype=np.float32)
    # A snowflake or spark is far smaller than a block, so averaging erases it. Where a block holds a
    # point much brighter than the block's average, pull the block toward that point's color.
    cells = np.asarray(frame, dtype=np.float32).reshape(grid[1], block, grid[0], block, 3).transpose(0, 2, 1, 3, 4).reshape(grid[1], grid[0], block * block, 3)
    luma = cells @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    # Score by brightness plus colorfulness, so a red bulb keeps its red instead of its white-hot center.
    chroma = cells.max(axis=3) - cells.min(axis=3)
    brightest = np.take_along_axis(cells, (luma + chroma).argmax(axis=2)[..., None, None], axis=2)[:, :, 0]
    lift = np.clip((luma.max(axis=2) - luma.mean(axis=2) - 55) / 60, 0, 1)[..., None]
    small = small * (1 - lift) + brightest * lift
    return ImageEnhance.Color(Image.fromarray(small.clip(0, 255).astype(np.uint8))).enhance(saturation)

samples = [shrink(f) for f in frames[:: max(1, len(frames) // 8)]]
strip = Image.new("RGB", (grid[0], grid[1] * len(samples)))
for i, s in enumerate(samples):
    strip.paste(s, (0, i * grid[1]))
palette = strip.quantize(colors=colors, method=method, dither=Image.Dither.NONE) if method is not None else None

for f in frames:
    small = shrink(f)
    if palette is not None:
        small = small.quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB")
    small.resize((grid[0] * block, grid[1] * block), Image.NEAREST).crop((0, 0, 1200, 630)).save(out / Path(f).name)
