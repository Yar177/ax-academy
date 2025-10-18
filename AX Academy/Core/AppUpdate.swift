import Foundation

/// Handles determining whether the user should be prompted to update the app
/// based on remote configuration.  The logic avoids nagging caregivers by only
/// prompting when the configured minimum version is higher than the installed
/// build.
public protocol AppUpdateManaging {
    func shouldShowUpdatePrompt(currentVersion: String, minimumVersion: String?) -> Bool
}

public final class AppUpdateManager: AppUpdateManaging {
    public init() {}

    public func shouldShowUpdatePrompt(currentVersion: String, minimumVersion: String?) -> Bool {
        guard let minimumVersion else { return false }
        return compareVersion(currentVersion, isLessThan: minimumVersion)
    }

    private func compareVersion(_ current: String, isLessThan minimum: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let minimumComponents = minimum.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(currentComponents.count, minimumComponents.count)
        for index in 0..<maxCount {
            let currentValue = index < currentComponents.count ? currentComponents[index] : 0
            let minimumValue = index < minimumComponents.count ? minimumComponents[index] : 0
            if currentValue < minimumValue { return true }
            if currentValue > minimumValue { return false }
        }
        return false
    }
}
