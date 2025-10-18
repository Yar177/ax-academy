# AX Academy Technical Specification

## Module Overview and Dependencies

### Module Dependency Graph
```
Core → {DesignSystem, ContentModel, Kindergarten, Grade1}
DesignSystem → ∅
ContentModel → {DesignSystem}
Kindergarten → {DesignSystem, ContentModel}
Grade1 → {DesignSystem, ContentModel}
TestSupport → {Core, DesignSystem, ContentModel, Kindergarten, Grade1}
```

- `Core` is the application shell that orchestrates navigation, persistence, and analytics. It owns configuration and feature flag lifecycles and exposes shared services to feature modules.
- `DesignSystem` offers UI primitives, theming, and accessibility helpers consumed by every feature module.
- `ContentModel` encapsulates curriculum metadata, lesson sequencing, and assessment logic. It is the single source of truth for grade-level and lesson content.
- `Kindergarten` and `Grade1` implement feature flows for each grade, including lesson plans, progress tracking, and gamified UI experiences.
- `TestSupport` bundles mocks, fixtures, and preview data for use by unit tests and SwiftUI previews.

### Public Protocols and Interface Contracts

| Protocol | Owned By | Purpose | Conformers |
| --- | --- | --- | --- |
| `NavigationCoordinating` | Core | Push/pop lesson flows, display modals, coordinate grade transitions. | Core navigator, feature module coordinators |
| `PersistentStore` | Core | CRUD operations for user profiles, lesson progress, and streaks. Supports async operations with conflict resolution. | Local database adapter, cloud sync adapter |
| `AnalyticsLogging` | Core | Track screen views, CTA taps, quiz outcomes, and progression funnels. Supports batching & offline queueing. | Core analytics service, testing spies |
| `FeatureModule` | Core | Defines lifecycle hooks (`bootstrap()`, `makeRootView()`, `handle(deepLink:)`). | KindergartenModule, Grade1Module |
| `LessonContentProvider` | ContentModel | Supplies lesson metadata, practice problems, and mastery criteria. | Kindergarten content adapters, Grade1 content adapters |
| `DesignTokenProviding` | DesignSystem | Access to color, typography, spacing, elevation, and motion tokens. | Default design token store, testing token overrides |
| `AccessibilityVariantHandling` | DesignSystem | Provides variant overrides for Reduced Transparency and Reduced Motion. | Token stores, animations wrappers |

Interface contract notes:
- All protocol methods are `async` where side effects are expected. Synchronous variants must decorate network/disk calls with Task execution.
- Feature modules must not access persistence or analytics directly; they rely on Core-provided protocol conformers.
- ContentModel exposes data via value types (`Lesson`, `Assessment`, `Activity`) to ensure immutability.
- DesignSystem tokens are read-only and versioned; consumers should observe `DesignSystemVersion.current` to react to updates.

## Design Tokens

### Color Tokens

| Semantic Name | Light | Dark | Reduced Transparency |
| --- | --- | --- | --- |
| `color.background.primary` | `#F7FBFF` | `#05080D` | solid with 95% opacity |
| `color.background.surface` | `#FFFFFF` | `#111824` | solid with 98% opacity |
| `color.background.glass` | `rgba(255,255,255,0.64)` | `rgba(15,26,40,0.64)` | fallback to `color.background.surface` |
| `color.accent.primary` | `#0F7AE5` | `#73B5FF` | unchanged |
| `color.accent.success` | `#1FBF75` | `#5FDEA1` | unchanged |
| `color.accent.warning` | `#FFB020` | `#FFC860` | unchanged |
| `color.text.primary` | `#0C1C30` | `#E8F2FF` | unchanged |
| `color.text.secondary` | `#44546A` | `#A9BED6` | unchanged |
| `color.text.inverse` | `#FFFFFF` | `#05101C` | unchanged |
| `color.border.neutral` | `#D4E0EE` | `#2B3C52` | increase opacity to 1.0 |

### Typography Tokens

| Semantic Name | Font | Size | Line Height | Weight | Reduced Motion |
| --- | --- | --- | --- | --- | --- |
| `type.display` | Rounded Display | 48pt | 54pt | Bold | no animation tracking |
| `type.heading.large` | Rounded Sans | 32pt | 40pt | SemiBold | disable character animations |
| `type.heading.medium` | Rounded Sans | 24pt | 32pt | SemiBold | disable character animations |
| `type.body` | Humanist Sans | 17pt | 24pt | Regular | unchanged |
| `type.caption` | Humanist Sans | 13pt | 18pt | Medium | unchanged |
| `type.mono` | Numeric Mono | 15pt | 20pt | Medium | unchanged |

### Spacing Tokens

| Semantic Name | Value |
| --- | --- |
| `space.xs` | 4pt |
| `space.sm` | 8pt |
| `space.md` | 16pt |
| `space.lg` | 24pt |
| `space.xl` | 32pt |
| `space.gutter` | 20pt on compact, 28pt on regular |
| `space.stack` | Responsive column spacing: `space.md` compact, `space.lg` regular |

### Elevation Tokens

| Semantic Name | Blur | Y-Offset | Opacity | Reduced Transparency |
| --- | --- | --- | --- | --- |
| `elevation.flat` | 0 | 0 | 0 | 0 |
| `elevation.raised` | 12 | 4 | 0.12 | use solid border `color.border.neutral` |
| `elevation.overlay` | 32 | 12 | 0.24 | use solid background `color.background.surface` |
| `elevation.hud` | 40 | 16 | 0.30 | use `color.background.surface` + 90% opacity |

### Motion Tokens

| Semantic Name | Duration | Curve | Reduced Motion Variant |
| --- | --- | --- | --- |
| `motion.fast` | 120ms | cubic-bezier(0.2, 0.8, 0.2, 1) | switch to 0ms (no animation) |
| `motion.standard` | 240ms | cubic-bezier(0.2, 0.8, 0.2, 1) | replace with crossfade over 120ms |
| `motion.emphasized` | 360ms | cubic-bezier(0.4, 0.0, 0.2, 1) | replace with opacity fade 180ms |
| `motion.bounce` | 480ms | spring response 0.75 | replace with scale 1.0 and fade |
| `motion.looping` | infinite | linear | disable animation, display static frame |

## SwiftUI Component APIs

### GlassCard
- **Signature:** `GlassCard(title: String, subtitle: String? = nil, icon: Image? = nil, action: (() -> Void)? = nil)`
- **Behavior:** Uses `color.background.glass` with blur and `elevation.raised`. When ReducedTransparency is active, falls back to `color.background.surface` with border.
- **Content Layout:** Vertical stack with `space.md` padding, leading aligned, icon size 40x40.
- **Accessibility:** Dynamic type resizes using typography tokens.

### PrimaryButton
- **Signature:** `PrimaryButton(label: String, style: PrimaryButton.Style = .filled, leadingIcon: Image? = nil, trailingIcon: Image? = nil, action: () -> Void)`
- **Styles:** `.filled` (accent primary background), `.tonal` (accent primary at 20% opacity), `.outline` (transparent background with accent border).
- **Fallbacks:** Reduced Motion disables scale/bounce animations; Reduced Transparency shifts tonal to solid background.
- **Visual Specs:** Height 52pt, corner radius 16pt, horizontal padding `space.lg`.

### ProgressBar
- **Signature:** `ProgressBar(progress: Double, label: String? = nil, showsFraction: Bool = false)`
- **Behavior:** Animates width change using `motion.standard`; Reduced Motion jumps without animation. Accepts `progress` clamped 0...1.
- **Visual Specs:** Track uses `color.background.surface`, fill uses `color.accent.primary`. Height 12pt, corner radius 6pt. Optional label above using `type.caption`.

### LessonCard
- **Signature:** `LessonCard(lesson: Lesson, status: LessonStatus, tapAction: () -> Void)`
- **Behavior:** Displays lesson title, tags, and status chip. Locked lessons dimmed using 60% opacity overlay. Completed lessons show checkmark badge.
- **Visual Specs:** Card uses `GlassCard` internally. Image banner 120pt height with fallback gradient if asset missing.
- **Accessibility:** VoiceOver uses `status.accessibilityDescription`.

### AnswerTile
- **Signature:** `AnswerTile(answer: AnswerOption, isSelected: Bool, isCorrect: Bool?, tapAction: () -> Void)`
- **Behavior:** Selection toggled with haptic feedback (if available). When `isCorrect == true`, tile uses success accent; when `false`, uses warning accent. Null indicates neutral.
- **Fallbacks:** Reduced Motion removes flip animation, uses opacity change.
- **Visual Specs:** Min width 120pt, height 60pt, corner radius 12pt, border width 2pt.

### HUD Overlays
- **Types:** `HUDOverlay.progress`, `HUDOverlay.success`, `HUDOverlay.error`, `HUDOverlay.reward`.
- **Signature:** `HUDOverlay(kind: HUDOverlay.Kind, message: String, action: (() -> Void)? = nil)`
- **Behavior:** Presented via `Core` navigation coordinator as top overlay. Auto-dismiss after 2s using `motion.fast`. Reduced Motion removes slide-in, uses fade.
- **Visual Specs:** Uses `elevation.hud`, `color.background.glass`, icon size 44pt, message uses `type.body` with center alignment.

## Core Touchpoints for Upcoming Features

### Analytics
- Screen view events for new adaptive lesson flow (`core.analytics.trackScreen("adaptive_lesson_intro")`).
- CTA events for `PrimaryButton` interactions tagged with `cta_id` (e.g., `"start_adaptive_assessment"`).
- Lesson completion funnel events emitted by `LessonCard` interactions.
- HUD overlay impressions and dismissals instrumented for success/error states.
- Data model: extend `AnalyticsEvent` enum with new cases and attach grade, lesson, and user cohort metadata.

### Feature Flags
- `featureFlags.isAdaptiveLearningEnabled` toggles new adaptive flow visibility per grade.
- `featureFlags.isGlassUIEnabled` controls usage of `GlassCard` and HUD overlays for A/B tests.
- Flags retrieved at launch via Core configuration service and cached in `PersistentStore`.
- Modules observe `FeatureFlagCenter` Combine publisher for real-time updates.

### Configuration
- Remote config keys for analytics sampling rate (`config.analytics.sampleRate`), maximum daily lessons (`config.lesson.dailyMax`), and reward cadence (`config.rewards.cadenceDays`).
- Core exposes `ConfigurationProviding` protocol with async `value(for:)` method returning typed configuration values.
- DesignSystem tokens version pinned by `config.designSystem.version` to allow remote theming updates.
- Kindergarten and Grade1 modules request grade-specific thresholds (`config.gradeKindergarten.masteryThreshold`, `config.grade1.masteryThreshold`).

### Persistence
- `PersistentStore` must support new `AdaptiveProgress` entity storing last assessment timestamp, mastery level, and recommended next lesson.
- Offline-first strategy: queue analytics and flag updates in `PersistentStore` when network unavailable.
- Provide migration path for existing user profiles to include new adaptive metadata.

### Navigation
- Extend `NavigationCoordinating` with route `adaptiveAssessment(grade:)` and overlay presentation for HUDs.
- Ensure deep links can target new adaptive lessons using URI scheme `axa://grade/{grade}/lesson/{id}`.

