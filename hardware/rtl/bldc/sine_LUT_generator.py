#!/usr/bin/env python3
"""Generate the quarter-wave sine lookup table used by the BLDC SPWM mode."""

from __future__ import annotations

import argparse
import math
from pathlib import Path


def generate(rows: int, width: int) -> list[str]:
    fmt_width = math.ceil(width / 4)
    lines: list[str] = []

    for index in range(rows):
        angle = (math.pi / (2 * rows)) * index
        normalized = (1 + math.sin(angle)) * 0.5
        scaled = round((2**width) * normalized)

        if scaled == 2**width:
            scaled -= 1

        lines.append(
            f"{scaled:0{fmt_width}X}  // {index:03}: sin({angle:.4f}) = {normalized:.4f}"
        )

    return lines


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=int, default=16, help="entries in one quadrant")
    parser.add_argument("--width", type=int, default=8, help="bits per LUT entry")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).with_name("sine_LUT_table.mem"),
        help="output .mem path",
    )
    args = parser.parse_args()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(generate(args.rows, args.width)) + "\n")


if __name__ == "__main__":
    main()
