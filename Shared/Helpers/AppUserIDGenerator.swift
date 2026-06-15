import Foundation

enum AppUserIDGenerator {
    static func sixDigitID(from value: String) -> String {
        let hash = value.unicodeScalars.reduce(0) { partialResult, scalar in
            abs((partialResult &* 31) &+ Int(scalar.value))
        }
        return String(format: "%06d", hash % 1_000_000)
    }
}
