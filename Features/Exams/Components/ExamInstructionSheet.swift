import SwiftUI

struct ExamInstructionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection: ExamInstructionSection = .math

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Раздел", selection: $selectedSection) {
                    ForEach(ExamInstructionSection.allCases) { section in
                        Text(section.title).tag(section)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 14) {
                    Text(selectedSection.heading)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))

                    ForEach(selectedSection.instructions, id: \.self) { instruction in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color(hex: "7257F4"))
                                .frame(width: 6, height: 6)
                                .padding(.top, 8)

                            Text(instruction)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color(hex: "4D5567"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(Color(hex: "F6F7FB"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(20)
            .navigationTitle("Инструкция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color(hex: "8C8F98"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private enum ExamInstructionSection: String, CaseIterable, Identifiable {
    case math
    case text
    case session

    var id: String { rawValue }

    var title: String {
        switch self {
        case .math:
            return "Математика"
        case .text:
            return "Текст"
        case .session:
            return "Сессия"
        }
    }

    var heading: String {
        switch self {
        case .math:
            return "Ввод формул"
        case .text:
            return "Ввод текста"
        case .session:
            return "Сохранение"
        }
    }

    var instructions: [String] {
        switch self {
        case .math:
            return [
                "Используй математическую клавиатуру для чисел, дробей, корней, степеней и специальных символов.",
                "Зеленая клавиша перехода двигает курсор внутри шаблонов: дробь, корень, логарифм, степень.",
                "CE очищает весь ответ, клавиша удаления убирает последний введенный символ.",
                "Кнопка абв переключает ввод на текстовую клавиатуру."
            ]
        case .text:
            return [
                "Текст вводится внутри LaTeX-блока, поэтому его можно совмещать с формулами в одном ответе.",
                "RU и EN переключают русский и английский алфавит.",
                "Space добавляет пробел между словами.",
                "Верхний ряд содержит основные знаки для письменного ответа: кавычки, тире, скобки и пунктуацию."
            ]
        case .session:
            return [
                "Продолжить сохраняет текущий ответ и переводит к следующему шагу экзамена.",
                "Выход предлагает сохранить экзамен и вернуться позже или завершить его.",
                "При сохранении и выходе сессия остается локально и восстановится при следующем открытии этого экзамена.",
                "Результаты пока не показываются: сейчас сохраняем только ход сессии и ответы."
            ]
        }
    }
}
