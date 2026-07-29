"""Verify that a rendered review PDF and its page PNGs form a complete set."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import pypdfium2
from PIL import Image, ImageChops


PAGE_PATTERN = re.compile(r"page-(\d+)\.png$")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path)
    parser.add_argument("page_dir", type=Path)
    args = parser.parse_args()

    if not args.pdf.is_file() or args.pdf.stat().st_size == 0:
        raise SystemExit(f"Missing or empty PDF: {args.pdf}")

    pdf = pypdfium2.PdfDocument(args.pdf)
    pages: list[tuple[int, Path]] = []
    for path in args.page_dir.glob("page-*.png"):
        match = PAGE_PATTERN.fullmatch(path.name)
        if match:
            pages.append((int(match.group(1)), path))
    pages.sort()

    expected = list(range(1, len(pdf) + 1))
    actual = [number for number, _ in pages]
    if actual != expected:
        raise SystemExit(f"PNG sequence mismatch: expected {expected}, found {actual}")

    dimensions: set[tuple[int, int]] = set()
    for number, path in pages:
        with Image.open(path) as image:
            image.verify()
        with Image.open(path).convert("RGB") as image:
            dimensions.add(image.size)
            white = Image.new("RGB", image.size, "white")
            if ImageChops.difference(image, white).getbbox() is None:
                raise SystemExit(f"Rendered page {number} is blank")

    if len(dimensions) != 1:
        raise SystemExit(f"Inconsistent page dimensions: {sorted(dimensions)}")

    print(f"Verified {len(pdf)} PDF pages and {len(pages)} sequential, nonblank PNGs at {dimensions.pop()}.")


if __name__ == "__main__":
    main()
