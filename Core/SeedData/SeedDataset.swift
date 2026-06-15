import Foundation

enum SeedDatasetID: String, Codable, CaseIterable {
    case mathEGEBase = "math_ege_base"
    case mathEGEProfile = "math_ege_profile"
    case mathOGE = "math_oge"
    case mathVPR6 = "math_vpr_6"
    case mathVPR7 = "math_vpr_7"
    case mathVPR7Advanced = "math_vpr_7_advanced"
    case mathVPR8 = "math_vpr_8"
    case mathVPR8Advanced = "math_vpr_8_advanced"
    case russianEGE = "russian_ege"
    case russianOGE = "russian_oge"
    case russianVPR6 = "russian_vpr_6"
    case russianVPR7 = "russian_vpr_7"
    case russianVPR = "russian_vpr"
    case historyEGE = "history_ege"
    case historyOGE = "history_oge"
    case historyVPR6 = "history_vpr_6"
    case historyVPR7 = "history_vpr_7"
    case historyVPR8 = "history_vpr_8"
    case englishEGE = "english_ege"
    case englishOGE = "english_oge"
    case englishVPR6 = "english_vpr_6"
    case englishVPR7 = "english_vpr_7"
    case englishVPR8 = "english_vpr_8"
    case biologyEGE = "biology_ege"
    case biologyOGE = "biology_oge"
    case computerScienceEGE = "computer_science_ege"
    case computerScienceOGE = "computer_science_oge"
    case physicsEGE = "physics_ege"
    case physicsOGE = "physics_oge"
    case chemistryEGE = "chemistry_ege"
    case chemistryOGE = "chemistry_oge"
}

struct SeedDataset: Identifiable, Codable, Equatable {
    let id: SeedDatasetID
    let title: String
    let subject: Subject
    let examCategory: ExamCategory
    let level: String?
    let resourceName: String
    let resourceExtension: String
    let localFilename: String
    let versionKey: String
    let importedKey: String
    let initialVersion: Int
}

enum SeedDatasetCatalog {
    static let all: [SeedDataset] = [
        SeedDataset(
            id: .mathEGEBase,
            title: "Математика. ЕГЭ база",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .ege,
            level: "base",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_ege_base",
            importedKey: "seed.imported.math_ege_base",
            initialVersion: 5
        ),
        SeedDataset(
            id: .mathEGEProfile,
            title: "Математика. ЕГЭ профиль",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .ege,
            level: "profile",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_ege_profile",
            importedKey: "seed.imported.math_ege_profile",
            initialVersion: 5
        ),
        SeedDataset(
            id: .mathOGE,
            title: "Математика. ОГЭ",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_oge",
            importedKey: "seed.imported.math_oge",
            initialVersion: 4
        ),
        SeedDataset(
            id: .mathVPR6,
            title: "Математика. ВПР 6 класс",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .vpr,
            level: "6",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_vpr_6",
            importedKey: "seed.imported.math_vpr_6",
            initialVersion: 2
        ),
        SeedDataset(
            id: .mathVPR7,
            title: "Математика. ВПР 7 класс",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .vpr,
            level: "7",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_vpr_7",
            importedKey: "seed.imported.math_vpr_7",
            initialVersion: 2
        ),
        SeedDataset(
            id: .mathVPR7Advanced,
            title: "Математика. ВПР 7 углубленный",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .vpr,
            level: "7_advanced",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_vpr_7_advanced",
            importedKey: "seed.imported.math_vpr_7_advanced",
            initialVersion: 2
        ),
        SeedDataset(
            id: .mathVPR8,
            title: "Математика. ВПР 8 класс",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .vpr,
            level: "8",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_vpr_8",
            importedKey: "seed.imported.math_vpr_8",
            initialVersion: 2
        ),
        SeedDataset(
            id: .mathVPR8Advanced,
            title: "Математика. ВПР 8 углубленный",
            subject: Subject(id: "math", title: "Математика"),
            examCategory: .vpr,
            level: "8_advanced",
            resourceName: "ExamUP_Math_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Math_Free.json",
            versionKey: "seed.version.math_vpr_8_advanced",
            importedKey: "seed.imported.math_vpr_8_advanced",
            initialVersion: 2
        ),
        SeedDataset(
            id: .russianEGE,
            title: "Русский язык. ЕГЭ",
            subject: Subject(id: "russian", title: "Русский язык"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_Russion_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Russion_Free.json",
            versionKey: "seed.version.russian_ege",
            importedKey: "seed.imported.russian_ege",
            initialVersion: 3
        ),
        SeedDataset(
            id: .russianOGE,
            title: "Русский язык. ОГЭ",
            subject: Subject(id: "russian", title: "Русский язык"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_Russion_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Russion_Free.json",
            versionKey: "seed.version.russian_oge",
            importedKey: "seed.imported.russian_oge",
            initialVersion: 4
        ),
        SeedDataset(
            id: .russianVPR6,
            title: "Русский язык. ВПР 6 класс",
            subject: Subject(id: "russian", title: "Русский язык"),
            examCategory: .vpr,
            level: "6",
            resourceName: "ExamUP_Russion_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Russion_Free.json",
            versionKey: "seed.version.russian_vpr_6",
            importedKey: "seed.imported.russian_vpr_6",
            initialVersion: 2
        ),
        SeedDataset(
            id: .russianVPR7,
            title: "Русский язык. ВПР 7 класс",
            subject: Subject(id: "russian", title: "Русский язык"),
            examCategory: .vpr,
            level: "7",
            resourceName: "ExamUP_Russion_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Russion_Free.json",
            versionKey: "seed.version.russian_vpr_7",
            importedKey: "seed.imported.russian_vpr_7",
            initialVersion: 2
        ),
        SeedDataset(
            id: .russianVPR,
            title: "Русский язык. ВПР 8 класс",
            subject: Subject(id: "russian", title: "Русский язык"),
            examCategory: .vpr,
            level: "8",
            resourceName: "ExamUP_Russion_Free",
            resourceExtension: "json",
            localFilename: "ExamUP_Russion_Free.json",
            versionKey: "seed.version.russian_vpr",
            importedKey: "seed.imported.russian_vpr",
            initialVersion: 3
        ),
        SeedDataset(
            id: .historyEGE,
            title: "История. ЕГЭ",
            subject: Subject(id: "history", title: "История"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_History",
            resourceExtension: "json",
            localFilename: "ExamUP_History.json",
            versionKey: "seed.version.history_ege",
            importedKey: "seed.imported.history_ege",
            initialVersion: 4
        ),
        SeedDataset(
            id: .historyOGE,
            title: "История. ОГЭ",
            subject: Subject(id: "history", title: "История"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_History",
            resourceExtension: "json",
            localFilename: "ExamUP_History.json",
            versionKey: "seed.version.history_oge",
            importedKey: "seed.imported.history_oge",
            initialVersion: 4
        ),
        SeedDataset(
            id: .historyVPR6,
            title: "История. ВПР 6 класс",
            subject: Subject(id: "history", title: "История"),
            examCategory: .vpr,
            level: "6",
            resourceName: "ExamUP_History",
            resourceExtension: "json",
            localFilename: "ExamUP_History.json",
            versionKey: "seed.version.history_vpr_6",
            importedKey: "seed.imported.history_vpr_6",
            initialVersion: 2
        ),
        SeedDataset(
            id: .historyVPR7,
            title: "История. ВПР 7 класс",
            subject: Subject(id: "history", title: "История"),
            examCategory: .vpr,
            level: "7",
            resourceName: "ExamUP_History",
            resourceExtension: "json",
            localFilename: "ExamUP_History.json",
            versionKey: "seed.version.history_vpr_7",
            importedKey: "seed.imported.history_vpr_7",
            initialVersion: 2
        ),
        SeedDataset(
            id: .historyVPR8,
            title: "История. ВПР 8 класс",
            subject: Subject(id: "history", title: "История"),
            examCategory: .vpr,
            level: "8",
            resourceName: "ExamUP_History",
            resourceExtension: "json",
            localFilename: "ExamUP_History.json",
            versionKey: "seed.version.history_vpr_8",
            importedKey: "seed.imported.history_vpr_8",
            initialVersion: 2
        ),
        SeedDataset(
            id: .englishEGE,
            title: "Английский язык. ЕГЭ",
            subject: Subject(id: "english", title: "Английский язык"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_English",
            resourceExtension: "json",
            localFilename: "ExamUP_English.json",
            versionKey: "seed.version.english_ege",
            importedKey: "seed.imported.english_ege",
            initialVersion: 1
        ),
        SeedDataset(
            id: .englishOGE,
            title: "Английский язык. ОГЭ",
            subject: Subject(id: "english", title: "Английский язык"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_English",
            resourceExtension: "json",
            localFilename: "ExamUP_English.json",
            versionKey: "seed.version.english_oge",
            importedKey: "seed.imported.english_oge",
            initialVersion: 1
        ),
        SeedDataset(
            id: .englishVPR6,
            title: "Английский язык. ВПР 6 класс",
            subject: Subject(id: "english", title: "Английский язык"),
            examCategory: .vpr,
            level: "6",
            resourceName: "ExamUP_English",
            resourceExtension: "json",
            localFilename: "ExamUP_English.json",
            versionKey: "seed.version.english_vpr_6",
            importedKey: "seed.imported.english_vpr_6",
            initialVersion: 1
        ),
        SeedDataset(
            id: .englishVPR7,
            title: "Английский язык. ВПР 7 класс",
            subject: Subject(id: "english", title: "Английский язык"),
            examCategory: .vpr,
            level: "7",
            resourceName: "ExamUP_English",
            resourceExtension: "json",
            localFilename: "ExamUP_English.json",
            versionKey: "seed.version.english_vpr_7",
            importedKey: "seed.imported.english_vpr_7",
            initialVersion: 1
        ),
        SeedDataset(
            id: .englishVPR8,
            title: "Английский язык. ВПР 8 класс",
            subject: Subject(id: "english", title: "Английский язык"),
            examCategory: .vpr,
            level: "8",
            resourceName: "ExamUP_English",
            resourceExtension: "json",
            localFilename: "ExamUP_English.json",
            versionKey: "seed.version.english_vpr_8",
            importedKey: "seed.imported.english_vpr_8",
            initialVersion: 1
        ),
        SeedDataset(
            id: .biologyEGE,
            title: "Биология. ЕГЭ",
            subject: Subject(id: "biology", title: "Биология"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_Biology",
            resourceExtension: "json",
            localFilename: "ExamUP_Biology.json",
            versionKey: "seed.version.biology_ege",
            importedKey: "seed.imported.biology_ege",
            initialVersion: 1
        ),
        SeedDataset(
            id: .biologyOGE,
            title: "Биология. ОГЭ",
            subject: Subject(id: "biology", title: "Биология"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_Biology",
            resourceExtension: "json",
            localFilename: "ExamUP_Biology.json",
            versionKey: "seed.version.biology_oge",
            importedKey: "seed.imported.biology_oge",
            initialVersion: 1
        ),
        SeedDataset(
            id: .computerScienceEGE,
            title: "Информатика. ЕГЭ",
            subject: Subject(id: "computer-science", title: "Информатика"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_Computer_Science",
            resourceExtension: "json",
            localFilename: "ExamUP_Computer_Science.json",
            versionKey: "seed.version.computer_science_ege",
            importedKey: "seed.imported.computer_science_ege",
            initialVersion: 1
        ),
        SeedDataset(
            id: .computerScienceOGE,
            title: "Информатика. ОГЭ",
            subject: Subject(id: "computer-science", title: "Информатика"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_Computer_Science",
            resourceExtension: "json",
            localFilename: "ExamUP_Computer_Science.json",
            versionKey: "seed.version.computer_science_oge",
            importedKey: "seed.imported.computer_science_oge",
            initialVersion: 1
        ),
        SeedDataset(
            id: .physicsEGE,
            title: "Физика. ЕГЭ",
            subject: Subject(id: "physics", title: "Физика"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_Physics",
            resourceExtension: "json",
            localFilename: "ExamUP_Physics.json",
            versionKey: "seed.version.physics_ege",
            importedKey: "seed.imported.physics_ege",
            initialVersion: 1
        ),
        SeedDataset(
            id: .physicsOGE,
            title: "Физика. ОГЭ",
            subject: Subject(id: "physics", title: "Физика"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_Physics",
            resourceExtension: "json",
            localFilename: "ExamUP_Physics.json",
            versionKey: "seed.version.physics_oge",
            importedKey: "seed.imported.physics_oge",
            initialVersion: 1
        ),
        SeedDataset(
            id: .chemistryEGE,
            title: "Химия. ЕГЭ",
            subject: Subject(id: "chemistry", title: "Химия"),
            examCategory: .ege,
            level: nil,
            resourceName: "ExamUP_Chemistry",
            resourceExtension: "json",
            localFilename: "ExamUP_Chemistry.json",
            versionKey: "seed.version.chemistry_ege",
            importedKey: "seed.imported.chemistry_ege",
            initialVersion: 1
        ),
        SeedDataset(
            id: .chemistryOGE,
            title: "Химия. ОГЭ",
            subject: Subject(id: "chemistry", title: "Химия"),
            examCategory: .oge,
            level: nil,
            resourceName: "ExamUP_Chemistry",
            resourceExtension: "json",
            localFilename: "ExamUP_Chemistry.json",
            versionKey: "seed.version.chemistry_oge",
            importedKey: "seed.imported.chemistry_oge",
            initialVersion: 1
        )
    ]
}
