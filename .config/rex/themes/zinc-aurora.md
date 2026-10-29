# Zinc Aurora

A dark Rex terminal theme: neutral zinc-gray surfaces with bright, cool "aurora" accents. The mint-green cursor is the signature color. James built it in Rex's theme editor. It's his dark theme, paired with Rex's built-in `merino-light` for light mode.

This file is the source of truth. Rex stores themes in its macOS preferences, not in `~/.config/rex`, so an agent has to install the theme on each machine using the steps below.

## Palette

Hex values are sRGB. Rex keeps Display P3 values for most colors, with these as the sRGB fallback, so use the JSON record below for an exact copy. Contrast ratios are measured against the background.

| Role | Hex | Contrast | Notes |
| --- | --- | --- | --- |
| Background | `#141414` | — | Pure neutral, no blue tint |
| Foreground | `#CFDAE2` | 13.0 | Cool blue-gray, not white |
| Cursor | `#6EF2B8` | 13.2 | Mint; the accent the theme is built around |
| Cursor text | `#101010` | 13.6 on cursor | |
| Selection background | `#323232` | — | Neutral gray, no tint |
| Selection foreground | `#E8F1F7` | 11.2 on selection | Same as bright white |

### ANSI colors

| # | Name | Normal | Contrast | # | Bright | Contrast |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | Black | `#1C1C1C` | 1.1 | 8 | `#526270` | 2.9 |
| 1 | Red | `#EE7189` | 6.5 | 9 | `#F78DA1` | 8.1 |
| 2 | Green | `#55DFA2` | 10.9 | 10 | `#79EEB9` | 12.9 |
| 3 | Yellow | `#E5C568` | 11.0 | 11 | `#F1D787` | 13.0 |
| 4 | Blue | `#5FA5E8` | 7.1 | 12 | `#82BCF2` | 9.2 |
| 5 | Magenta | `#A888EF` | 6.5 | 13 | `#BFA3F6` | 8.6 |
| 6 | Cyan | `#47D3D6` | 10.1 | 14 | `#6CE5E8` | 12.3 |
| 7 | White | `#A9BAC6` | 9.2 | 15 | `#E8F1F7` | 16.1 |

## Design

- **Neutral surfaces, cool text.** Background, selection, ANSI black, and cursor text are true grays (R = G = B). Every lighter neutral (foreground, white, bright black, bright white) leans toward slate blue. The chrome stays out of the way while text reads slightly cool.
- **Even accents.** The six hues (red 348°, green 153°, yellow 45°, blue 209°, magenta 259°, cyan 181°) sit at similar saturation (64–79%) and lightness (56–74% HSL), so no one color shouts. Red is a soft rose and magenta leans violet.
- **Bright = lighter, same hue.** Each bright color is a lighter tint of its normal color, not a different hue.
- **Readable.** Every normal and bright accent passes WCAG AA (4.5:1) on the background. The lowest is red at 6.5.
- **Known low-contrast slots.** ANSI 0 (`#1C1C1C`) is nearly invisible on the background, which is normal for dark themes. Bright black (`#526270`, 2.9) is dim, so dimmed text and autosuggestions stay quiet. Tools that print body text in bright black will be hard to read.
- Rex's `paletteHarmonious` and `paletteGenerate` flags are on. These are editor settings and don't change the stored colors.

## Rex settings

| Preference key | Value |
| --- | --- |
| `Workspace.customThemes` | JSON array of theme records, stored as plist data |
| `Workspace.darkThemeID` | `custom-3CDFFB57-3E04-481B-B1B1-D901B902E36A` |
| `Workspace.lightThemeID` | `merino-light` |
| `Workspace.appearance` | `dark` |
| `Workspace.interfaceStyle` | `blendTheme` (window chrome takes its colors from the theme) |

Domain: `com.superlogical.rex` (`~/Library/Preferences/com.superlogical.rex.plist`). App: `/Applications/Rex Beta.app`.

## Install on another Mac

1. Quit Rex first. Rex holds its preferences in memory and overwrites outside edits when it quits.
2. Merge the record below into `Workspace.customThemes` by `id`. Keep any other custom themes on that machine. Keep the `id` unchanged so `darkThemeID` resolves and repeat installs replace the theme instead of adding a copy.
3. Set the theme IDs, then reopen Rex.

```sh
osascript -e 'quit app "Rex Beta"'

python3 - <<'PY'
import json, pathlib, plistlib, re, subprocess
doc = pathlib.Path.home() / ".config/rex/themes/zinc-aurora.md"
theme = json.loads(re.search(r"```json\n(.*?)\n```", doc.read_text(), re.S).group(1))
domain, key = "com.superlogical.rex", "Workspace.customThemes"
read = subprocess.run(["defaults", "export", domain, "-"], capture_output=True)
prefs = plistlib.loads(read.stdout) if read.returncode == 0 else {}
themes = json.loads(prefs[key]) if key in prefs else []
themes = [t for t in themes if t["id"] != theme["id"]] + [theme]
blob = json.dumps(themes, separators=(",", ":")).encode()
subprocess.run(["defaults", "write", domain, key, "-data", blob.hex()], check=True)
subprocess.run(["defaults", "write", domain, "Workspace.darkThemeID", theme["id"]], check=True)
PY

defaults write com.superlogical.rex Workspace.lightThemeID merino-light
defaults write com.superlogical.rex Workspace.interfaceStyle blendTheme
open -a "Rex Beta"
```

Check: `defaults read com.superlogical.rex Workspace.darkThemeID` prints the ID above, and Rex shows a mint cursor on a `#141414` background.

If James later edits the theme in Rex, re-export this record from `Workspace.customThemes` and update the tables above to match.

## Theme record

The exact record from Rex. `createdAt` uses Apple's reference date (seconds since 2001-01-01).

```json
{
  "source": {
    "manual": {}
  },
  "id": "custom-3CDFFB57-3E04-481B-B1B1-D901B902E36A",
  "palette": {
    "background": {
      "colorSpace": "srgb",
      "green": 0.0784313725490196,
      "alpha": 1,
      "red": 0.0784313725490196,
      "blue": 0.0784313725490196
    },
    "paletteBase": {},
    "paletteOverrides": {},
    "foreground": {
      "colorSpace": "display-p3",
      "green": 0.853654,
      "srgbFallback": {
        "red": 0.811765,
        "green": 0.854902,
        "alpha": 1,
        "colorSpace": "srgb",
        "blue": 0.886275
      },
      "alpha": 1,
      "red": 0.818999,
      "blue": 0.883658
    },
    "selectionForeground": {
      "colorSpace": "display-p3",
      "green": 0.944199,
      "srgbFallback": {
        "red": 0.909804,
        "green": 0.945098,
        "alpha": 1,
        "colorSpace": "srgb",
        "blue": 0.968627
      },
      "alpha": 1,
      "red": 0.915153,
      "blue": 0.967252
    },
    "selectionBackground": {
      "colorSpace": "srgb",
      "green": 0.19607843137254902,
      "alpha": 1,
      "red": 0.19607843137254902,
      "blue": 0.19607843137254902
    },
    "paletteHarmonious": true,
    "ansi": [
      {
        "colorSpace": "srgb",
        "green": 0.10980392156862745,
        "alpha": 1,
        "red": 0.10980392156862745,
        "blue": 0.10980392156862745
      },
      {
        "colorSpace": "display-p3",
        "green": 0.423284,
        "srgbFallback": {
          "red": 0.933333,
          "green": 0.443137,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.537255
        },
        "alpha": 1,
        "red": 0.919743,
        "blue": 0.522653
      },
      {
        "colorSpace": "display-p3",
        "green": 0.890863,
        "srgbFallback": {
          "red": 0.333333,
          "green": 0.87451,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.635294
        },
        "alpha": 1,
        "red": 0.364705,
        "blue": 0.618213
      },
      {
        "colorSpace": "display-p3",
        "green": 0.775163,
        "srgbFallback": {
          "red": 0.898039,
          "green": 0.772549,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.407843
        },
        "alpha": 1,
        "red": 0.887507,
        "blue": 0.418804
      },
      {
        "colorSpace": "display-p3",
        "green": 0.64008,
        "srgbFallback": {
          "red": 0.372549,
          "green": 0.647059,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.909804
        },
        "alpha": 1,
        "red": 0.424342,
        "blue": 0.903674
      },
      {
        "colorSpace": "display-p3",
        "green": 0.529938,
        "srgbFallback": {
          "red": 0.658824,
          "green": 0.533333,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.937255
        },
        "alpha": 1,
        "red": 0.640774,
        "blue": 0.932129
      },
      {
        "colorSpace": "display-p3",
        "green": 0.836409,
        "srgbFallback": {
          "red": 0.278431,
          "green": 0.827451,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.839216
        },
        "alpha": 1,
        "red": 0.304583,
        "blue": 0.860677
      },
      {
        "colorSpace": "display-p3",
        "green": 0.727474,
        "srgbFallback": {
          "red": 0.662745,
          "green": 0.729412,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.776471
        },
        "alpha": 1,
        "red": 0.674465,
        "blue": 0.772317
      },
      {
        "colorSpace": "display-p3",
        "green": 0.38285,
        "srgbFallback": {
          "red": 0.321569,
          "green": 0.384314,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.439216
        },
        "alpha": 1,
        "red": 0.330578,
        "blue": 0.438028
      },
      {
        "colorSpace": "display-p3",
        "green": 0.53344,
        "srgbFallback": {
          "red": 0.968627,
          "green": 0.552941,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.631373
        },
        "alpha": 1,
        "red": 0.961639,
        "blue": 0.617853
      },
      {
        "colorSpace": "display-p3",
        "green": 0.944238,
        "srgbFallback": {
          "red": 0.47451,
          "green": 0.933333,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.72549
        },
        "alpha": 1,
        "red": 0.51304,
        "blue": 0.716819
      },
      {
        "colorSpace": "display-p3",
        "green": 0.845261,
        "srgbFallback": {
          "red": 0.945098,
          "green": 0.843137,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.529412
        },
        "alpha": 1,
        "red": 0.939135,
        "blue": 0.525743
      },
      {
        "colorSpace": "display-p3",
        "green": 0.731641,
        "srgbFallback": {
          "red": 0.509804,
          "green": 0.737255,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.94902
        },
        "alpha": 1,
        "red": 0.547027,
        "blue": 0.94521
      },
      {
        "colorSpace": "display-p3",
        "green": 0.63666,
        "srgbFallback": {
          "red": 0.74902,
          "green": 0.639216,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.964706
        },
        "alpha": 1,
        "red": 0.73336,
        "blue": 0.961585
      },
      {
        "colorSpace": "display-p3",
        "green": 0.904216,
        "srgbFallback": {
          "red": 0.423529,
          "green": 0.898039,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.909804
        },
        "alpha": 1,
        "red": 0.456611,
        "blue": 0.926609
      },
      {
        "colorSpace": "display-p3",
        "green": 0.944199,
        "srgbFallback": {
          "red": 0.909804,
          "green": 0.945098,
          "alpha": 1,
          "colorSpace": "srgb",
          "blue": 0.968627
        },
        "alpha": 1,
        "red": 0.915153,
        "blue": 0.967252
      }
    ],
    "cursorText": {
      "colorSpace": "srgb",
      "green": 0.06274509803921569,
      "alpha": 1,
      "red": 0.06274509803921569,
      "blue": 0.06274509803921569
    },
    "cursor": {
      "colorSpace": "display-p3",
      "green": 0.957722,
      "srgbFallback": {
        "red": 0.431373,
        "green": 0.94902,
        "alpha": 1,
        "colorSpace": "srgb",
        "blue": 0.721569
      },
      "alpha": 1,
      "red": 0.492254,
      "blue": 0.715429
    },
    "paletteGenerate": true
  },
  "createdAt": 814978110.916623,
  "appearance": "dark",
  "name": "Zinc Aurora"
}
```
