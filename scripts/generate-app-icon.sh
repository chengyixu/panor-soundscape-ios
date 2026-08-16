#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v magick >/dev/null || {
  echo "ImageMagick is required: brew install imagemagick" >&2
  exit 1
}

output="Resources/Assets.xcassets/AppIcon.appiconset/Soundscape-AppIcon-1024.png"

contour_points() {
  local baseline="$1"
  local amplitude="$2"
  local phase="$3"
  awk -v baseline="$baseline" -v amplitude="$amplitude" -v phase="$phase" 'BEGIN {
    pi = atan2(0, -1)
    for (x = -64; x <= 1088; x += 12) {
      y = baseline + amplitude * sin((x + phase) * 2 * pi / 560)
      printf "%s%.0f,%.0f", separator, x, y
      separator = " "
    }
  }'
}

magick -size 1024x1024 "canvas:#F4EFE5" \
  -fill none -stroke '#252823' -strokewidth 18 -draw "polyline $(contour_points 196 68 0)" \
  -strokewidth 15 -draw "polyline $(contour_points 302 59 38)" \
  -strokewidth 13 -draw "polyline $(contour_points 408 51 74)" \
  -strokewidth 12 -draw "polyline $(contour_points 514 45 108)" \
  -strokewidth 13 -draw "polyline $(contour_points 620 51 140)" \
  -strokewidth 15 -draw "polyline $(contour_points 726 59 174)" \
  -strokewidth 18 -draw "polyline $(contour_points 832 68 208)" \
  -stroke '#C85B43' -strokewidth 8 -draw 'circle 512,512 898,512' \
  -strokewidth 12 -stroke '#D98A78' -draw 'line 242,513 782,513' \
  -strokewidth 34 -stroke '#C85B43' \
  -draw 'line 282,513 387,513 line 387,513 433,410 line 433,410 492,650 line 492,650 548,356 line 548,356 607,603 line 607,603 657,474 line 657,474 704,513 line 704,513 758,513' \
  -alpha off -strip "$output"

echo "Generated $output"
