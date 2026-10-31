"""survey.py <station dir> — labeled contact sheet of every clip in <dir>/video with its moving share."""
import glob, subprocess, sys, tempfile
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw

station = Path(sys.argv[1])
tiles = []
for i, clip in enumerate(sorted(glob.glob(str(station / "video" / "*.mp4"))), 1):
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["ffmpeg", "-loglevel", "error", "-i", clip, "-t", "6", "-vf", "fps=4,scale=480:270", f"{tmp}/%02d.png"], check=True)
        frames = [Image.open(f).convert("L") for f in sorted(glob.glob(f"{tmp}/*.png"))]
        moving = Image.new("L", frames[0].size, 0)
        for frame in frames[1:]:
            moving = ImageChops.lighter(moving, ImageChops.difference(frames[0], frame).point(lambda v: 255 if v > 25 else 0))
        share = 100 * sum(1 for v in moving.getdata() if v) / (480 * 270)
        tile = Image.open(sorted(glob.glob(f"{tmp}/*.png"))[2]).convert("RGB")
    label = f"{i}. {Path(clip).stem}  moving {share:.1f}%"
    ImageDraw.Draw(tile).rectangle([0, 0, 230, 20], fill="black")
    ImageDraw.Draw(tile).text((5, 4), label, fill="white")
    tiles.append(tile)
    print(label)
cols = 3
sheet = Image.new("RGB", (cols * 480, -(-len(tiles) // cols) * 270))
for i, tile in enumerate(tiles):
    sheet.paste(tile, ((i % cols) * 480, (i // cols) * 270))
sheet.save(station / "sheet.png")
