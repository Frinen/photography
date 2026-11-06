#!/bin/bash
set -euo pipefail

FULL_DIR="images/fulls"
THUMB_DIR="images/thumbs"
mkdir -p "$FULL_DIR" "$THUMB_DIR"

shopt -s nullglob
source_files=()
for f in images/*; do
  case "$f" in
    "$FULL_DIR"|"$THUMB_DIR") continue ;;
    *.jpg|*.JPG|*.jpeg|*.JPEG|*.png|*.PNG)
      source_files+=("$f")
      ;;
  esac
done

if [ "${#source_files[@]}" -gt 0 ]; then
  for f in "${source_files[@]}"; do
    name=$(basename "$f")

    tmp_full=$(mktemp "$FULL_DIR/.${name}.XXXXXX")
    magick "$f" -strip -resize 1600x1600 -quality 82 "$tmp_full"
    mv -f "$tmp_full" "$FULL_DIR/$name"

    tmp_thumb=$(mktemp "$THUMB_DIR/.${name}.XXXXXX")
    magick "$f" -strip -resize 640x640 -quality 72 "$tmp_thumb"
    mv -f "$tmp_thumb" "$THUMB_DIR/$name"
  done
else
  for f in "$FULL_DIR"/*; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
      *.jpg|*.JPG|*.jpeg|*.JPEG|*.png|*.PNG) ;;
      *) continue ;;
    esac

    name=$(basename "$f")
    tmp_thumb=$(mktemp "$THUMB_DIR/.${name}.XXXXXX")
    magick "$f" -strip -resize 640x640 -quality 72 "$tmp_thumb"
    mv -f "$tmp_thumb" "$THUMB_DIR/$name"
  done
fi

echo "resized images generated"