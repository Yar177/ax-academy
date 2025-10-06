import SwiftUI
import UIKit

/// A lightweight snapshot utility.  This helper renders a SwiftUI view into
/// an offscreen `UIImage` which can then be compared against a reference
/// image stored in the test bundle.  While not as feature rich as third
/// party snapshot frameworks it is sufficient for simple UI regression
/// testing.  Use `assertSnapshot(of:asImageNamed:file:line:)` to record or
/// compare snapshots.
public enum Snapshot {
    /// Renders the given view to an image with the specified size.  The
    /// default size uses the current device screen width and height.
    public static func image<V: View>(for view: V, size: CGSize = CGSize(width: 300, height: 600)) -> UIImage {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.frame = window.bounds
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
