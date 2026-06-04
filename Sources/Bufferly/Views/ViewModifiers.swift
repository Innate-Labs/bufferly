import SwiftUI

private struct KeyboardHintModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

extension View {
    func keyboardHint() -> some View {
        modifier(KeyboardHintModifier())
    }
}
