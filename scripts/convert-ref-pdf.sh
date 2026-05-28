#!/usr/bin/env bash
#
# Convert a PDF rendered by the official LNCS LaTeX template into
# tytanic-compatible PNG reference snapshots named 1.png, 2.png, ...
#
# Usage:
#   ./scripts/convert-ref-pdf.sh path/to/ref.pdf path/to/ref-dir [ppi]

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 INPUT_PDF OUTPUT_DIR [PPI]" >&2
  exit 2
fi

input_pdf=$1
output_dir=$2
ppi=${3:-144}

if [[ ! -f $input_pdf ]]; then
  echo "error: input pdf not found: $input_pdf" >&2
  exit 1
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "error: ImageMagick 'magick' command not found" >&2
  exit 1
fi

repo=$(git rev-parse --show-toplevel)
cd "$repo"

mkdir -p "$output_dir"

# Avoid stale snapshots if a new PDF has fewer pages than the old refs.
find "$output_dir" -maxdepth 1 -type f -regex '.*/[0-9]+\.png' -delete

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/fine-lncs-ref.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

magick -density "$ppi" "$input_pdf" \
  -background white -alpha remove -alpha off \
  "$tmp_dir/page-%d.png"

shopt -s nullglob
pages=("$tmp_dir"/page-*.png)
shopt -u nullglob

if (( ${#pages[@]} == 0 )); then
  echo "error: conversion produced no png pages" >&2
  exit 1
fi

for page in "${pages[@]}"; do
  base=${page##*/}
  index=${base#page-}
  index=${index%.png}
  target=$((index + 1))
  mv "$page" "$output_dir/$target.png"
done

echo "converted ${#pages[@]} page(s) from $input_pdf into $output_dir at ${ppi} ppi"
