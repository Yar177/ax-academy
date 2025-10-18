#!/usr/bin/env python3
"""Validate that every lesson in the curriculum catalog meets authoring rules."""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path

DEFAULT_CATALOG = Path("AX Academy/ContentModel/Data/curriculum_v1.json")
REQUIRED_VARIANTS = {"practice", "challenge", "remediation"}
REQUIRED_DIFFICULTIES = {"emerging", "developing", "secure", "extending"}


def load_catalog(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Catalog not found at {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Catalog at {path} is not valid JSON: {exc}") from exc
    return data


def validate_lessons(catalog: dict) -> list[str]:
    errors: list[str] = []
    variants_by_strand: dict[tuple[str, str], set[str]] = defaultdict(set)

    for lesson in catalog.get("lessons", []):
        lid = lesson.get("id", "<missing>")
        grade = lesson.get("grade", "<missing>")
        strand = lesson.get("strandID", "<missing>")
        variant = lesson.get("variant")
        difficulty = lesson.get("difficulty")

        variants_by_strand[(grade, strand)].add(variant)

        if not lesson.get("objectives"):
            errors.append(f"{lid}: objectives must not be empty")
        if variant not in REQUIRED_VARIANTS:
            errors.append(f"{lid}: variant '{variant}' is not one of {sorted(REQUIRED_VARIANTS)}")
        if difficulty not in REQUIRED_DIFFICULTIES:
            errors.append(f"{lid}: difficulty '{difficulty}' is not recognised")
        if not lesson.get("hints"):
            errors.append(f"{lid}: must provide at least one lesson hint")
        if not lesson.get("scaffolds"):
            errors.append(f"{lid}: must provide at least one lesson scaffold")

        mastery = lesson.get("masteryRule") or {}
        if "scoreThreshold" not in mastery:
            errors.append(f"{lid}: masteryRule missing scoreThreshold")
        if "minimumItems" not in mastery:
            errors.append(f"{lid}: masteryRule missing minimumItems")

        for index, item in enumerate(lesson.get("items", [])):
            prefix = f"{lid} item {index + 1}"
            if not item.get("hints"):
                errors.append(f"{prefix}: must include at least one hint")
            if not item.get("scaffolds"):
                errors.append(f"{prefix}: must include at least one scaffold")

    for (grade, strand), variants in variants_by_strand.items():
        if variants != REQUIRED_VARIANTS:
            missing = REQUIRED_VARIANTS - variants
            errors.append(
                f"{grade}/{strand} missing lesson variants: {', '.join(sorted(missing))}"
            )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--catalog",
        type=Path,
        default=DEFAULT_CATALOG,
        help="Path to the curriculum JSON file",
    )
    args = parser.parse_args()

    catalog = load_catalog(args.catalog)
    errors = validate_lessons(catalog)
    if errors:
        print("Lesson validation failed:")
        for message in errors:
            print(f"  - {message}")
        return 1

    lessons = catalog.get("lessons", [])
    grades = sorted({lesson.get("grade") for lesson in lessons})
    print(f"Validated {len(lessons)} lessons across grades: {', '.join(grades)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
