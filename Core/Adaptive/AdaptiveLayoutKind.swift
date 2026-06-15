import SwiftUI

enum AdaptiveLayoutKind: String, Codable, Equatable {
    case phonePortrait
    case phoneLandscape
    case tablet

    static func resolve(
        horizontalSizeClass: UserInterfaceSizeClass?,
        verticalSizeClass: UserInterfaceSizeClass?
    ) -> AdaptiveLayoutKind {
        if horizontalSizeClass == .regular {
            return .tablet
        }

        if verticalSizeClass == .compact {
            return .phoneLandscape
        }

        return .phonePortrait
    }
}
