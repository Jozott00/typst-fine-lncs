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

if ! command -v gs >/dev/null 2>&1; then
  echo "error: Ghostscript 'gs' command not found" >&2
  exit 1
fi

repo=$(git rev-parse --show-toplevel)
cd "$repo"

mkdir -p "$output_dir"

# Avoid stale snapshots if a new PDF has fewer pages than the old refs.
shopt -s nullglob
stale_refs=("$output_dir"/[0-9]*.png)
shopt -u nullglob
if (( ${#stale_refs[@]} > 0 )); then
  rm -f "${stale_refs[@]}"
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/fine-lncs-ref.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

page_size=$(magick identify "$input_pdf[0]" 2>/dev/null | awk '{
  for (i = 1; i <= NF; ++i) {
    if ($i ~ /^[0-9]+x[0-9]+$/) {
      print $i
      exit
    }
  }
}')

paper_size=
case "$page_size" in
  612x792)
    paper_size=letter
    ;;
  595x842|596x842)
    paper_size=a4
    ;;
esac

gs_args=(
  -dSAFER
  -dBATCH
  -dNOPAUSE
  -dPDFFitPage
  -sDEVICE=pnggray
  -r"$ppi"
  -sOutputFile="$tmp_dir/page-%d.png"
)

if [[ -n $paper_size ]]; then
  gs_args+=(-sPAPERSIZE="$paper_size" -dFIXEDMEDIA)
fi

gs "${gs_args[@]}" "$input_pdf"

shopt -s nullglob
pages=("$tmp_dir"/page-*.png)
shopt -u nullglob

if (( ${#pages[@]} == 0 )); then
  echo "error: conversion produced no png pages" >&2
  exit 1
fi

target=1
for page in "${pages[@]}"; do
  mv "$page" "$output_dir/$target.png"
  target=$((target + 1))
done

echo "converted ${#pages[@]} page(s) from $input_pdf into $output_dir at ${ppi} ppi"
