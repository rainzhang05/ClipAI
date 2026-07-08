import SwiftUI

final class OverlayDisplayState: ObservableObject {
    @Published var text: String
    @Published var isError: Bool
    @Published var showsCopiedToast = false

    init(text: String, isError: Bool) {
        self.text = text
        self.isError = isError
    }

    func update(text: String, isError: Bool) {
        self.text = text
        self.isError = isError
        showsCopiedToast = false
    }

    func showCopiedToast() {
        showsCopiedToast = true
    }
}
