import SwiftUI
import UIKit

/// Thin SwiftUI wrapper around UIActivityViewController.
/// Present via `.sheet` — SwiftUI handles iPad popover adaptation automatically.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    var onDismiss: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            onDismiss?()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
