import SwiftUI

struct AppTheme {
    let spacing: Spacing
    let colors: AppColors

    static let `default` = AppTheme(
        spacing: Spacing(),
        colors: AppColors()
    )
}

struct Spacing {
    let xs: CGFloat = 4
    let sm: CGFloat = 8
    let md: CGFloat = 16
    let lg: CGFloat = 24
    let xl: CGFloat = 32
}

struct AppColors {
    let background = Color(.systemBackground)
    let secondaryBackground = Color(.secondarySystemBackground)
    let text = Color(.label)
    let mutedText = Color(.secondaryLabel)
    let accent = Color.accentColor
}
