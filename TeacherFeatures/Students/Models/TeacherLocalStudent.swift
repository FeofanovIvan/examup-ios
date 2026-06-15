import Foundation

struct TeacherLocalStudent: Identifiable, Codable, Sendable, Equatable, Hashable {
    let id: String
    let publicID: String
    var name: String
    var className: String
    var note: String
    let createdAt: Date
    var updatedAt: Date

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Ученик" : name
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case publicID
        case name
        case className
        case note
        case createdAt
        case updatedAt
    }

    init(
        id: String,
        publicID: String,
        name: String,
        className: String,
        note: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.publicID = publicID
        self.name = name
        self.className = className
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        publicID = try container.decodeIfPresent(String.self, forKey: .publicID) ?? id
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        className = try container.decodeIfPresent(String.self, forKey: .className) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}
