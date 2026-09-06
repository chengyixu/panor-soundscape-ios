#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v magick >/dev/null || {
  echo "ImageMagick is required: brew install imagemagick" >&2
  exit 1
}

source_logo="Soundscape-logo.svg"
output="Resources/Assets.xcassets/AppIcon.appiconset/Soundscape-AppIcon-1024.png"

test -f "$source_logo" || {
  echo "Missing source logo: $source_logo" >&2
  exit 1
}

# The supplied logo contains the Soundscape wordmark under the waveform.
# Crop to the upper vector artwork only: app icons use the three-wave shape,
# never lettering. Rendering to the SVG viewBox dimensions first keeps the
# crop stable across ImageMagick SVG delegates.
magick -background white "$source_logo" \
  -resize 400x270! \
  -crop 400x140+0+20 +repage \
  -resize 880x308 \
  -gravity center -background white -extent 1024x1024 \
  -alpha off -strip "$output"

echo "Generated $output"
