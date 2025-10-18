import Foundation

/// Protocol describing an error logging facility.  Logging is required for
/// auditing and for quickly diagnosing production issues.  Implementations
/// should avoid collecting personally identifiable information in order to stay
/// COPPA/GDPR compliant.
public protocol ErrorLogging {
    func log(error: Error, context: String)
    func log(message: String, context: String)
}

/// A simple implementation that prints to the console during development.  In a
/// production environment this could send anonymised reports to a backend.
public final class ConsoleErrorLogger: ErrorLogging {
    public init() {}

    public func log(error: Error, context: String) {
        print("[Error][\(context)] \(error.localizedDescription)")
    }

    public func log(message: String, context: String) {
        print("[Log][\(context)] \(message)")
    }
}
