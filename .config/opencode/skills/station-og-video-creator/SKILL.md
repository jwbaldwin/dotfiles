---
name: station-og-video-creator
description: Make the animated pixel-art link preview (og:image plus og:video loop) for a Vibes station, from finding source footage through shipping it to production. Use when James asks for a station's OG image or video, a share preview or link preview for a station, preview options for a station, or to pixelate or redo a station's preview art.
---

# Station OG Video Creator

Each Vibes station shares as `vibes.jwbaldwin.com/<slug>`. Its preview is two files in the Vibes repo:

- `priv/static/images/og/<slug>.jpg`: frame 0, the still image
- `priv/static/images/og/<slug>.mp4`: a 4 s seamless loop, 1200×630, played by iMessage

`VibesWeb.SharePreview` picks them up when they exist and links them through digested static paths, so a replaced file skips Cloudflare's stale copy. No code changes are needed to add or swap art.

## James's look

His standard style, "the goto vibe", is real ambient footage pixelated at **6 px blocks, 96 colors, octree palette, saturation 1.0**:

```sh
$PYTHON -I $S/pixelate.py frames-<id> px6-<id> 6 96 1.0 octree
```

What he liked and rejected:

- Real footage from long YouTube ambience videos, not generated art or thumbnails. Thumbnails carry overlays, such as a heart, that the video itself doesn't have.
- Motion must survive the pixelation: fire, snow, steam, blinking lights, rain. Prefer clips where 5–15% of the frame moves.
- Cozy and specific: a warm interior looking out on weather, a lit street or a city at night. For Christmas, "vintage 90s": colored bulbs, a decorated tree, a fireplace, and a snowy village through the window.
- No suggestive content, even in the background. He turned down a Blade Runner corridor for that.
- Pixel art at the source (lofi channels) can skip pixelation. Footage gets it.

## Workflow

Work in `/tmp/og-work/<slug>/` with `video/`, `frames-<id>/`, `px6-<id>/` and `out/`. Set `S=~/.config/opencode/skills/station-og-video-creator/scripts`.

1. **Find candidates.** Search YouTube for long ambience videos that match the station, and check the station's own lineup first:
   ```sh
   $YTDLP --js-runtimes node --flat-playlist --print "%(id)s %(duration)s %(title)s" "ytsearch20:90s christmas living room ambience fireplace"
   ```
2. **Survey.** Grab 6 s of each at 480p a few minutes in, then make a labeled contact sheet with each clip's moving share:
   ```sh
   $S/grab.sh <id> video/v_<id>.mp4 300 480
   $PYTHON -I $S/survey.py /tmp/og-work/<slug>    # writes sheet.png
   ```
3. **Build loops.** Regrab the best 6–8 at 1080p, then make a loop per clip. `build_all.sh` crops off letterboxing, centers a 1200×630 crop, blends the last second into the first, encodes, and prints a seam score next to each clip's typical frame change. A seam well above the typical score shows as a jump.
   ```sh
   $S/build_all.sh /tmp/og-work/<slug>
   ```
   To frame a scene by hand (to cut an overlay, say): `$S/footage_loop.py <clip> <frames dir> <x> <y> <width> 4 1 25`.
4. **Pixelate and encode** each candidate:
   ```sh
   $PYTHON -I $S/pixelate.py frames-v_<id> px6-v_<id> 6 96 1.0 octree
   (cd out && $S/encode.sh "../px6-v_<id>/%04d.png" px6-v_<id> 25)
   ```
   `encode.sh` writes `<name>.mp4`, `<name>.jpg`, and a `<name>.gif` for review.
5. **Present options.** Show 6–7 GIFs inline (`![X1](/tmp/og-work/<slug>/out/px6-v_<id>.gif)`), each labeled with a code (X1, W8…) and a one-line description of the scene and its motion. Name your pick and why. James refines by code: "W8 at 6px", "more options like X3".
6. **Ship the pick** (his pick counts as approval to deploy this art):
   ```sh
   cp out/px6-v_<id>.jpg <vibes>/priv/static/images/og/<slug>.jpg
   cp out/px6-v_<id>.mp4 <vibes>/priv/static/images/og/<slug>.mp4
   ```
   Commit with jj ("added the pixelated <scene> preview for the <station> station"), `jj git fetch`, `jj bookmark set main -r @-`, `jj git push -b main`. The push runs CI and deploys. Wait for the run with `gh run watch <id> --exit-status`.
7. **Verify in production.** Pull the `og:video` URL from `https://vibes.jwbaldwin.com/<slug>`, download it, and compare its `shasum` with the committed file. Tell James to test by texting the link with `?v=N`, which skips iMessage's cached preview.
8. **Credit the source.** Give James the video title, channel and link for each option he asks about.

If James wants the source video in the station's playlist too, add it with an append-only migration (like `20261031120000_add_90s_living_rooms_to_christmas.exs`), and update `priv/repo/station_seed_data.exs` to match. Set `duration_seconds` from yt-dlp, `start_seconds: 30` and `tune_in: true`, and check that `playable_in_embed` is true.

## Pixelation notes

`pixelate.py` downscales with Lanczos, then lifts any block that holds a point much brighter than its average toward that point. Without the lift, 6 px blocks erase snowflakes, sparks and bulbs. It picks the lifted point by brightness plus colorfulness, so a red bulb stays red instead of turning into its white center. It builds one palette from frames across the loop, so colors don't flicker.

- Octree keeps small patches of strong color. Median cut washes colored bulbs to white and gold.
- Fewer than about 48 colors turns snow tan. 96 is the default.
- Raising saturation turns fire yellow. Leave it at 1.0.
- If snowy trees look noisy, raise the lift threshold (now 55).
- Small text, such as a camcorder date stamp, won't survive 6 px blocks.

## Setup and gotchas

- Tools: ffmpeg (the brew build has no `drawtext`, so draw labels with Pillow), a Python with Pillow and numpy (`python3 -m venv /tmp/venv-img && /tmp/venv-img/bin/pip install pillow numpy`, then `PYTHON=/tmp/venv-img/bin/python`), and yt-dlp. `brew install yt-dlp` can hang. Download the standalone `yt-dlp_macos` from its GitHub releases instead and set `YTDLP` to it.
- yt-dlp needs `--js-runtimes node` for YouTube. Direct googlevideo URLs return 403. The scripts use `--download-sections` for normal videos and `-g` for live streams.
- YouTube IDs can start with `-`. Pass them after `--` and prefix file names with `v_`, or ffmpeg reads the name as a flag.
- jj won't snapshot new files over 1 MiB. `encode.sh` uses CRF 26, which keeps a 4 s loop around 200–800 KB. If one is still too big, raise the CRF.
- Port 4000 may belong to another project. Run Vibes locally with `PORT=4010`.
- Other platforms may ignore `og:video` and show the jpg, so frame 0 must work as a still on its own.
