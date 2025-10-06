import SwiftUI

/// A protocol that defines the basic responsibilities of a coordinator.  A
/// coordinator is an object that owns a subtree of navigation and is
/// responsible for creating and presenting views.  Coordinators do not
/// implement business logic directly; they delegate to view models and
/// repositories.  This pattern helps to separate navigation concerns from
/// presentation and business logic.
public protocol Coordinator: AnyObject {
    /// The root SwiftUI view managed by this coordinator.  It should be
    /// constructed in `start()` and returned to the caller.  Because
    /// coordinators own navigation, they often present navigation views or
    /// tab views as their root.
    associatedtype ViewType: View

    /// Starts the coordinator and returns its root view.  A coordinator
    /// should be started only once and should construct all child
    /// coordinators lazily to avoid unnecessary work.
    func start() -> ViewType
}