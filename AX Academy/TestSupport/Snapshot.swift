import SwiftUI
import UIKit
import XCTest

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

public extension XCTestCase {
    /// Asserts that a view's rendered image matches a stored reference image.
    /// When the reference does not exist this method records the snapshot to
    /// disk so it can be committed.  The reference images live alongside the
    /// test invoking this helper.
    func assertSnapshot<V: View>(of view: V,
                                 asImageNamed imageName: String,
                                 file: StaticString = #file,
                                 line: UInt = #line) {
        let size = CGSize(width: 300, height: 600)
        let snapshotImage = Snapshot.image(for: view, size: size)
        let data = snapshotImage.pngData()!
        let testFileURL = URL(fileURLWithPath: String(describing: file))
        let directory = testFileURL.deletingLastPathComponent()
        let referenceURL = directory.appendingPathComponent("__Snapshots__/")
            .appendingPathComponent(imageName)
            .appendingPathExtension("png")
        let fm = FileManager.default
        if !fm.fileExists(atPath: referenceURL.path) {
            // Record new snapshot
            try? fm.createDirectory(at: referenceURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try? data.write(to: referenceURL)
            XCTFail("Recorded snapshot. Please re-run the test.", file: file, line: line)
            return
        }
        guard let referenceData = try? Data(contentsOf: referenceURL) else {
            XCTFail("Failed to load reference snapshot", file: file, line: line)
            return
        }
        if referenceData != data {
            let attachments: [XCTAttachment] = [
                XCTAttachment(data: referenceData, uniformTypeIdentifier: "public.png"),
                XCTAttachment(data: data, uniformTypeIdentifier: "public.png")
            ]
            attachments.forEach { $0.lifetime = .keepAlways; add($0) }
            XCTFail("Snapshot mismatch: \(imageName)", file: file, line: line)
        }
    }
}