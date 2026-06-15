import Foundation

extension Array where Element: Identifiable {
    var ids: [Element.ID] {
        map(\.id)
    }
}
