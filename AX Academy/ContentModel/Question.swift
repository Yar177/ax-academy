import Foundation

/// Temporary typealias to maintain API compatibility with earlier builds that
/// referenced `Question`. The new schema uses `LessonItem` which carries richer
/// metadata.
public typealias Question = LessonItem
