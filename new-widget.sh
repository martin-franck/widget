#!/usr/bin/env bash
#
# Scaffold a new widget test page and link it from index.html.
#
# Usage:
#   ./new-widget.sh --env ephem --ticket 11900 --brand 8bxqW --widget 0067dfbe-0bba-027a-5a60-d00bbfdc8374 --title "Some feature"
#   ./new-widget.sh --env tst   --slug marta    --brand 8ZpE5 --widget 00634318-77a6-7478-5533-29f81aa89887 --title "Marta's widget"
#   ./new-widget.sh --env ephem --ticket 11900 --brand 8bxqW --widget 0067... --title "Some feature" --dry-run
#
# Required:
#   --env      ephem | tst | stg | prod
#   --brand    data-brand-id
#   --widget   data-widget-id
#
# One of these is required to name the file / build the ephemeral URL:
#   --ticket   DEV ticket number (e.g. 11900)
#   --slug     explicit slug for the filename, if there's no ticket
#
# Optional:
#   --title    Page <title> and index label (defaults to the ticket/slug)
#   --type     filename segment between env and slug (default: channel-widget)
#   --url      override the recastpay.js script src (auto-derived per env otherwise)
#   --dry-run  print what would happen without writing any files

set -euo pipefail

cd "$(dirname "$0")"

env=""
ticket=""
slug=""
brand=""
widget=""
title=""
type="channel-widget"
url_override=""
dry_run=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) env="$2"; shift 2 ;;
    --ticket) ticket="$2"; shift 2 ;;
    --slug) slug="$2"; shift 2 ;;
    --brand) brand="$2"; shift 2 ;;
    --widget) widget="$2"; shift 2 ;;
    --title) title="$2"; shift 2 ;;
    --type) type="$2"; shift 2 ;;
    --url) url_override="$2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

case "$env" in
  ephem|tst|stg|prod) ;;
  *) echo "Error: --env must be one of ephem, tst, stg, prod" >&2; exit 1 ;;
esac

[[ -n "$brand" ]] || { echo "Error: --brand is required" >&2; exit 1; }
[[ -n "$widget" ]] || { echo "Error: --widget is required" >&2; exit 1; }
[[ -n "$ticket" || -n "$slug" ]] || { echo "Error: pass --ticket and/or --slug" >&2; exit 1; }

if [[ -z "$slug" ]]; then
  slug="$ticket"
fi

if [[ -z "$url_override" && "$env" == "ephem" ]]; then
  [[ -n "$ticket" ]] || { echo "Error: ephem needs --ticket to derive the URL, or pass --url explicitly" >&2; exit 1; }
fi

case "$env" in
  ephem) script_src="${url_override:-https://channel-dev-${ticket}.ephemeral.recast.tv/recastpay.js}" ;;
  tst)   script_src="${url_override:-https://embedded.tst.recast.tv/recastpay.js}" ;;
  stg)   script_src="${url_override:-https://embedded.stg.recast.tv/recastpay.js}" ;;
  prod)  script_src="${url_override:-https://embedded.recast.tv/recastpay.js}" ;;
esac

if [[ -z "$title" ]]; then
  if [[ -n "$ticket" ]]; then
    title="DEV-$ticket"
  else
    title="$slug"
  fi
fi

label="$title"
if [[ -n "$ticket" && "$title" != *"$ticket"* ]]; then
  label="$title - DEV-$ticket"
fi

filename="${env}-${type}-${slug}.html"

if [[ -e "$filename" ]]; then
  echo "Error: $filename already exists" >&2
  exit 1
fi

widget_html=$(cat <<EOF
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${title}</title>
  </head>
  <body>
    <!-- WIDGET -->
    <script
      src="${script_src}"
      data-brand-id="${brand}"
      data-widget-id="${widget}"
    ></script>
  </body>
</html>
EOF
)

if $dry_run; then
  echo "--- would create ${filename} ---"
  echo "$widget_html"
  echo "--- would link from index.html (${env}) as: ${label} ---"
  exit 0
fi

echo "$widget_html" > "$filename"

if [[ "$env" == "ephem" ]]; then
  marker="<!-- NEW:ephem -->"
  entry=$(printf '        %s\n        <li><a href="%s">%s</a></li>' "$marker" "$filename" "$label")
else
  marker="<!-- NEW:${env} -->"
  entry=$(printf '        <ul>\n          <a href="%s">%s</a>\n        </ul>\n        %s' "$filename" "$label" "$marker")
fi

tmpfile=$(mktemp)
found=false
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == *"$marker"* ]]; then
    printf '%s\n' "$entry"
    found=true
  else
    printf '%s\n' "$line"
  fi
done < index.html > "$tmpfile"

if ! $found; then
  rm -f "$tmpfile"
  echo "Error: could not find marker $marker in index.html" >&2
  exit 1
fi

mv "$tmpfile" index.html

echo "Created $filename"
echo "Linked from index.html under ${env}"
