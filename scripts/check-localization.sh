#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

failures=0

english_leaks=$(awk '
  /private var en: String/ { in_english=1; next }
  /private var zhHant: String/ { in_english=0 }
  in_english { print }
' Sources/Soundscape/Shared/Localization/SoundscapeLocale.swift | rg -n '[\p{Han}]' || true)
if [[ -n "$english_leaks" ]]; then
  printf 'FAIL English localization contains Han characters:\n%s\n' "$english_leaks"
  failures=$((failures + 1))
else
  echo 'PASS English localization contains no Han characters'
fi

source_leaks=$(rg -n --glob '*.swift' \
  --glob '!**/SoundscapeLocale.swift' \
  --glob '!**/LocaleManager.swift' \
  --glob '!**/SoundscapeCategory.swift' \
  --glob '!**/ResonanceLexicon.swift' \
  '[\p{Han}]' Sources/Soundscape || true)
if [[ -n "$source_leaks" ]]; then
  printf 'FAIL CJK text exists outside canonical localization/taxonomy files:\n%s\n' "$source_leaks"
  failures=$((failures + 1))
else
  echo 'PASS CJK text is confined to canonical localization/taxonomy files'
fi

ui_literal_pattern='(Text|Label|Button|TextField|SecureField|Toggle|navigationTitle|accessibility(Label|Hint|Value)|SoundscapeStatusLabel)\("(?!\\\(|[0-9])[^"\n]*[A-Za-z\p{Han}]|\b(eyebrow|title|detail): "(?!\\\(|[0-9])[^"\n]*[A-Za-z\p{Han}]'
ui_leaks=$(rg --pcre2 -n --glob '*.swift' "$ui_literal_pattern" \
  Sources/Soundscape/App Sources/Soundscape/Features Sources/Soundscape/Shared/DesignSystem || true)
if [[ -n "$ui_leaks" ]]; then
  printf 'FAIL user-facing SwiftUI strings bypass SoundscapeLocale:\n%s\n' "$ui_leaks"
  failures=$((failures + 1))
else
  echo 'PASS user-facing SwiftUI strings use SoundscapeLocale'
fi

if (( failures > 0 )); then
  printf 'SUMMARY localization_failures=%d\n' "$failures"
  exit 1
fi

echo 'SUMMARY localization_failures=0'
