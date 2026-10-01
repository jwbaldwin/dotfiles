#!/usr/bin/env bash
# Render-check HTML artifacts with headless Chrome.
# Usage: qa.sh <site-dir> [page.html ...]   (defaults to every *.html in site-dir)
# Prints diagram/error counts per page, broken internal links, and writes
# light + dark screenshots to $SHOTS (default: $TMPDIR/html-artifacts-shots).
set -euo pipefail

CH="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
SITE="$(cd "${1:?site dir}" && pwd)"; shift || true
SHOTS="${SHOTS:-${TMPDIR:-/tmp}/html-artifacts-shots}"
mkdir -p "$SHOTS"
cd "$SITE"
PAGES=("$@"); [ ${#PAGES[@]} -eq 0 ] && PAGES=(*.html)

status=0
for p in "${PAGES[@]}"; do
  dom="$("$CH" --headless=new --disable-gpu --virtual-time-budget=25000 --dump-dom "file://$SITE/$p" 2>/dev/null)"
  d=$(grep -c 'aria-roledescription' <<<"$dom" || true)
  e=$(grep -c 'render error' <<<"$dom" || true)
  printf '%-24s diagrams=%-3s errors=%s\n' "$p" "$d" "$e"
  [ "$e" -gt 0 ] && status=1
  for scheme in 1:light 0:dark; do
    "$CH" --headless=new --disable-gpu --hide-scrollbars --blink-settings=preferredColorScheme=${scheme%%:*} \
      --window-size=1440,2400 --virtual-time-budget=15000 \
      --screenshot="$SHOTS/${p%.html}-${scheme##*:}.png" "file://$SITE/$p" 2>/dev/null || true
  done
done

python3 - "$SITE" <<'PY' || status=1
import os, re, sys
site = sys.argv[1]
pages = {f for f in os.listdir(site) if f.endswith('.html')}
ids = {f: set(re.findall(r'id="([^"]+)"', open(os.path.join(site, f)).read())) for f in pages}
bad = []
for f in pages:
    for page, anchor in re.findall(r'href="([^"#:]*\.html)?(#[^"]*)?"', open(os.path.join(site, f)).read()):
        if (page and page not in pages) or (len(anchor) > 1 and anchor[1:] not in ids.get(page or f, set())):
            bad.append(f"{f} -> {page}{anchor}")
print("broken links:", ", ".join(bad) if bad else "none")
sys.exit(1 if bad else 0)
PY

echo "screenshots: $SHOTS (read them; fix overflow, unreadable diagrams, empty bands)"
exit $status
