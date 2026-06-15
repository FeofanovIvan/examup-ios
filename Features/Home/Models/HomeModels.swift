import Foundation

struct HomeDashboard: Equatable {
    let userName: String
    let userPublicID: String
    let studyStreakDays: Int
    let startedExamCount: Int
    let completedExamCount: Int
    let savedAnswerCount: Int
    let subjects: [Subject]
    let programs: [HomeStudyProgram]
    let selectedProgram: HomeStudyProgram
    let blocks: [HomeExamBlock]

    static let placeholder = HomeDashboard(
        userName: "Пользователь",
        userPublicID: "000000",
        studyStreakDays: 0,
        startedExamCount: 0,
        completedExamCount: 0,
        savedAnswerCount: 0,
        subjects: Subject.placeholders,
        programs: HomeStudyProgram.all,
        selectedProgram: HomeStudyProgram.defaultProgram,
        blocks: HomeExamBlock.placeholders
    )
}

struct HomeStudyProgram: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subject: Subject
    let egeDatasetID: String?
    let ogeDatasetID: String?
    let egeVariants: [HomeExamVariant]
    let vprVariants: [HomeExamVariant]

    static let math = HomeStudyProgram(
        id: "math",
        title: "Математика",
        subject: Subject(id: "math", title: "Математика"),
        egeDatasetID: SeedDatasetID.mathEGEBase.rawValue,
        ogeDatasetID: SeedDatasetID.mathOGE.rawValue,
        egeVariants: [
            HomeExamVariant(
                id: "math_ege_base",
                title: "база",
                subtitle: "Базовый уровень\n21 задание",
                datasetID: SeedDatasetID.mathEGEBase.rawValue
            ),
            HomeExamVariant(
                id: "math_ege_profile",
                title: "профиль",
                subtitle: "Профильный уровень\n19 заданий",
                datasetID: SeedDatasetID.mathEGEProfile.rawValue
            )
        ],
        vprVariants: [
            HomeExamVariant(
                id: "math_vpr_6",
                title: "6 класс",
                subtitle: "ВПР 6 класса\n16 заданий",
                datasetID: SeedDatasetID.mathVPR6.rawValue
            ),
            HomeExamVariant(
                id: "math_vpr_7",
                title: "7 класс",
                subtitle: "ВПР 7 класса\n17 заданий",
                datasetID: SeedDatasetID.mathVPR7.rawValue
            ),
            HomeExamVariant(
                id: "math_vpr_7_advanced",
                title: "7 угл.",
                subtitle: "Углубленный уровень\n16 заданий",
                datasetID: SeedDatasetID.mathVPR7Advanced.rawValue
            ),
            HomeExamVariant(
                id: "math_vpr_8",
                title: "8 класс",
                subtitle: "ВПР 8 класса\n18 заданий",
                datasetID: SeedDatasetID.mathVPR8.rawValue
            ),
            HomeExamVariant(
                id: "math_vpr_8_advanced",
                title: "8 угл.",
                subtitle: "Углубленный уровень\n16 заданий",
                datasetID: SeedDatasetID.mathVPR8Advanced.rawValue
            )
        ]
    )

    static let russian = HomeStudyProgram(
        id: "russian",
        title: "Русский язык",
        subject: Subject(id: "russian", title: "Русский язык"),
        egeDatasetID: SeedDatasetID.russianEGE.rawValue,
        ogeDatasetID: SeedDatasetID.russianOGE.rawValue,
        egeVariants: [],
        vprVariants: [
            HomeExamVariant(
                id: "russian_vpr_6",
                title: "6 класс",
                subtitle: "ВПР 6 класса\n5 заданий",
                datasetID: SeedDatasetID.russianVPR6.rawValue
            ),
            HomeExamVariant(
                id: "russian_vpr_7",
                title: "7 класс",
                subtitle: "ВПР 7 класса\n7 заданий",
                datasetID: SeedDatasetID.russianVPR7.rawValue
            ),
            HomeExamVariant(
                id: "russian_vpr_8",
                title: "8 класс",
                subtitle: "ВПР 8 класса\n10 заданий",
                datasetID: SeedDatasetID.russianVPR.rawValue
            )
        ]
    )

    static let history = HomeStudyProgram(
        id: "history",
        title: "История",
        subject: Subject(id: "history", title: "История"),
        egeDatasetID: SeedDatasetID.historyEGE.rawValue,
        ogeDatasetID: SeedDatasetID.historyOGE.rawValue,
        egeVariants: [],
        vprVariants: [
            HomeExamVariant(
                id: "history_vpr_6",
                title: "6 класс",
                subtitle: "ВПР 6 класса\n11 заданий",
                datasetID: SeedDatasetID.historyVPR6.rawValue
            ),
            HomeExamVariant(
                id: "history_vpr_7",
                title: "7 класс",
                subtitle: "ВПР 7 класса\n10 заданий",
                datasetID: SeedDatasetID.historyVPR7.rawValue
            ),
            HomeExamVariant(
                id: "history_vpr_8",
                title: "8 класс",
                subtitle: "ВПР 8 класса\n11 заданий",
                datasetID: SeedDatasetID.historyVPR8.rawValue
            )
        ]
    )

    static let english = HomeStudyProgram(
        id: "english",
        title: "Английский язык",
        subject: Subject(id: "english", title: "Английский язык"),
        egeDatasetID: SeedDatasetID.englishEGE.rawValue,
        ogeDatasetID: SeedDatasetID.englishOGE.rawValue,
        egeVariants: [],
        vprVariants: [
            HomeExamVariant(
                id: "english_vpr_6",
                title: "6 класс",
                subtitle: "ВПР 6 класса\n4 задания",
                datasetID: SeedDatasetID.englishVPR6.rawValue
            ),
            HomeExamVariant(
                id: "english_vpr_7",
                title: "7 класс",
                subtitle: "ВПР 7 класса\n4 задания",
                datasetID: SeedDatasetID.englishVPR7.rawValue
            ),
            HomeExamVariant(
                id: "english_vpr_8",
                title: "8 класс",
                subtitle: "ВПР 8 класса\n4 задания",
                datasetID: SeedDatasetID.englishVPR8.rawValue
            )
        ]
    )

    static let all = [math, russian, history, english]
    static let defaultProgram = math
}

struct HomeExamVariant: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let datasetID: String
}

struct HomeExamBlock: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let imageName: String
    let tintHex: String
    let backgroundHex: String
    let examCategory: ExamCategory?
    let datasetID: String?
    let variants: [HomeExamVariant]

    func selectingVariant(_ variant: HomeExamVariant) -> HomeExamBlock {
        HomeExamBlock(
            id: "\(id)_\(variant.id)",
            title: "\(title) \(variant.title)",
            subtitle: variant.subtitle,
            actionTitle: actionTitle,
            imageName: imageName,
            tintHex: tintHex,
            backgroundHex: backgroundHex,
            examCategory: examCategory,
            datasetID: variant.datasetID,
            variants: []
        )
    }

    static func blocks(for program: HomeStudyProgram) -> [HomeExamBlock] {
        var blocks: [HomeExamBlock] = []

        if let egeDatasetID = program.egeDatasetID {
            blocks.append(
                HomeExamBlock(
                    id: "ege",
                    title: "ЕГЭ",
                    subtitle: egeSubtitle(for: program),
                    actionTitle: "Перейти",
                    imageName: "EGE",
                    tintHex: "7257F4",
                    backgroundHex: "F1ECFF",
                    examCategory: .ege,
                    datasetID: egeDatasetID,
                    variants: program.egeVariants
                )
            )
        }

        if let ogeDatasetID = program.ogeDatasetID {
            blocks.append(
                HomeExamBlock(
                    id: "oge",
                    title: "ОГЭ",
                    subtitle: ogeSubtitle(for: program),
                    actionTitle: "Перейти",
                    imageName: "OGE",
                    tintHex: "3F86E8",
                    backgroundHex: "EAF6FF",
                    examCategory: .oge,
                    datasetID: ogeDatasetID,
                    variants: []
                )
            )
        }

        if !program.vprVariants.isEmpty {
            blocks.append(
                HomeExamBlock(
                    id: "vpr",
                    title: "ВПР",
                    subtitle: vprSubtitle(for: program),
                    actionTitle: "Перейти",
                    imageName: "VPR",
                    tintHex: "45C38A",
                    backgroundHex: "EAF9F1",
                    examCategory: .vpr,
                    datasetID: program.vprVariants.first?.datasetID,
                    variants: program.vprVariants
                )
            )
        }

        blocks.append(
            HomeExamBlock(
            id: "constructor",
            title: "Конструктор",
            subtitle: "Собери вариант\nи проверь себя",
            actionTitle: "Перейти",
            imageName: "Constructor",
            tintHex: "FF982D",
            backgroundHex: "FFF5DF",
            examCategory: .constructor,
            datasetID: program.egeDatasetID,
            variants: []
            )
        )

        return blocks
    }

    private static func egeSubtitle(for program: HomeStudyProgram) -> String {
        switch program.id {
        case "math": return "База: 21 задание\nПрофиль: 19 заданий"
        case "russian": return "Вариант из 27 заданий"
        case "history": return "Вариант из 22 заданий"
        case "english": return "Вариант из 42 заданий"
        default: return "Единый государственный экзамен"
        }
    }

    private static func ogeSubtitle(for program: HomeStudyProgram) -> String {
        switch program.id {
        case "math": return "Вариант из 25 заданий"
        case "russian": return "Вариант из 13 заданий"
        case "history": return "Вариант из 24 заданий"
        case "english": return "Вариант из 38 заданий"
        default: return "Основной государственный экзамен"
        }
    }

    private static func vprSubtitle(for program: HomeStudyProgram) -> String {
        let variantCount = program.vprVariants.count
        return "\(variantCount) \(variantCount == 5 ? "программ" : "класса")\nВыберите вариант"
    }

    static let placeholders = blocks(for: HomeStudyProgram.defaultProgram)
}
