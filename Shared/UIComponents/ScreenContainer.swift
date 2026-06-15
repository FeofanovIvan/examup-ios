import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding()
        }
        .navigationTitle(title)
    }
}
