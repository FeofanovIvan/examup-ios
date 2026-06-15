import SwiftUI

struct SubjectSelectorPlaceholder: View {
    let subjects: [Subject]

    var body: some View {
        PlaceholderBlock(title: "Subjects", subtitle: subjects.map(\.title).joined(separator: ", "))
    }
}
