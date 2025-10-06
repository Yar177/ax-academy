import Combine
import Foundation

/// A base class for view models in the MVVM C architecture.  View models
/// conforming to `ObservableObject` publish changes so views can update
/// reactively.  Subclasses should be final and expose only the properties
/// needed by the view.
open class BaseViewModel: ObservableObject {
    /// A cancellable set for Combine publishers.  Use this set to store
    /// subscriptions in a view model and automatically cancel them on
    /// deinitialization.
    public var cancellables = Set<AnyCancellable>()

    public init() {}
}