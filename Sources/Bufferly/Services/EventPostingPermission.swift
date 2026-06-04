import AppKit
import CoreGraphics

@MainActor
final class EventPostingPermission: ObservableObject {
    static let shared = EventPostingPermission()

    @Published private(set) var isGranted: Bool

    init() {
        isGranted = Self.preflight()
    }

    func refresh() {
        isGranted = Self.preflight()
    }

    @discardableResult
    func requestAccess() -> Bool {
        let granted = CGRequestPostEventAccess()
        isGranted = granted
        return granted
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private static func preflight() -> Bool {
        CGPreflightPostEventAccess()
    }
}
