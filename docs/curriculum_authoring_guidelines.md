# Curriculum Data Authoring Guidelines

This document describes how Kindergarten and Grade 1 curriculum content is structured, stored, and validated for AX Academy. Follow these standards when creating or updating content so the learning app, analytics pipeline, and caregiver dashboards stay in sync.

## Schema Overview

The curriculum catalog is defined in [`AX Academy/ContentModel`](../AX%20Academy/ContentModel) and serialized as JSON.

- **Standards (`Standard`)** – Align skills to academic benchmarks such as NY-NGMLS. Fields: `id`, `code`, `grade`, localized `description`, `strandID`, `skillIDs`.
- **Skills (`Skill`)** – Granular objectives that power mastery tracking. Fields: `id`, `grade`, `strandID`, localized `title` & `overview`, `standardIDs`, `prerequisiteSkillIDs`, `assetIDs`.
- **Learning Strands (`LearningStrand`)** – Instructional pathways combining skills, multimedia, and reporting tags.
- **Lessons (`Lesson`)** – Authored in three `variant`s (`practice`, `challenge`, `remediation`) per strand. Required metadata includes `objectives`, `difficulty`, `estimatedDurationMinutes`, `hints`, `scaffolds`, `masteryRule`, and an array of `items`.
- **Items (`LessonItem`)** – Currently support multiple choice via `choices`, but the schema is extensible to other response types. Every item carries localized `prompt`, `hints`, `scaffolds`, `standardIDs`, and optional multimedia references.
- **Multimedia Assets (`MultimediaAsset`)** – Describes illustrations, audio, video, or interactive manipulatives. Includes storage locations, localization support, and accessibility metadata.
- **Versioning (`CurriculumVersion`)** – Semantic version attached to the entire catalog. Content providers expose `catalogVersion` for analytics and parental reports.

See [`CurriculumModels.swift`](../AX%20Academy/ContentModel/CurriculumModels.swift) and [`Lesson.swift`](../AX%20Academy/ContentModel/Lesson.swift) for the authoritative type definitions.

## Storage & Localization Strategy

- **Current state:** The catalog ships as a bundled JSON file (`curriculum_v1.json`) located in `AX Academy/ContentModel/Data`. `BundledJSONContentProvider` loads and caches this data on device.
- **Cloud readiness:** Metadata declares future cloud containers (S3 prefixes). The provider can later fetch remote JSON without schema changes.
- **Localization:** Each user-facing string is a `LocalizedText` object with `translations` keyed by language code. Authoring must include an English baseline and may add optional locales (e.g., Spanish). Clients resolve strings at runtime using the device locale with safe fallbacks.

## Authoring Checklist

For every new or updated lesson:

1. Provide **at least two instructional objectives** aligned to the referenced skills.
2. Set **difficulty** to one of `emerging`, `developing`, `secure`, or `extending`.
3. Supply **lesson-level hints** (motivational guidance) and **scaffolds** (just-in-time supports like number lines or manipulatives).
4. Define a **mastery rule** with `scoreThreshold`, `minimumItems`, and optional `consecutiveCorrect` plus descriptive notes for analytics.
5. Author **each item** with a localized prompt, at least one hint and scaffold, difficulty tag, and any supporting `standardIDs` or `assetIDs`.
6. Ensure every strand has **practice, challenge, and remediation variants** covering its skills.

Multimedia assets must include accessibility metadata (alt text, captions) and storage details for both bundled and cloud sources.

## Validation Workflow

A reusable script enforces the authoring rules:

```bash
# Validate the bundled dataset
python scripts/validate_lessons.py

# Validate another catalog file
python scripts/validate_lessons.py --catalog path/to/catalog.json
```

The script fails if lessons are missing required objectives, hints, scaffolds, mastery rules, or if a strand lacks one of the three variants. Integrate this check into CI before distributing curriculum updates.

## Seed Data

Seed content for every Kindergarten and Grade 1 strand lives in [`curriculum_v1.json`](../AX%20Academy/ContentModel/Data/curriculum_v1.json). Each strand includes:

- **Practice** experiences targeting grade-level proficiency.
- **Challenge** lessons that extend reasoning or fluency.
- **Remediation** paths with scaffolded supports for learners needing reteach moments.

Use this dataset as a template when expanding to additional grades or subjects.
