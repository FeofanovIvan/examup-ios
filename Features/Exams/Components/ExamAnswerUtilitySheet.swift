import SwiftUI

struct ExamAnswerUtilitySheet: View {
    let answerText: String
    let taskNumber: String

    var body: some View {
        NavigationStack {
            List {
                Section("Текущий вопрос") {
                    Text("№ \(taskNumber)")
                }

                Section("Черновой ответ") {
                    Text(answerText.isEmpty ? "Ответ пока не введён" : answerText)
                        .font(.system(size: 18, weight: .semibold))
                        .textSelection(.enabled)
                }

                Section("Заметка") {
                    Text("Проверку ответа пока не подключаем. Эта панель нужна как временная боковая зона для будущих инструментов экзамена.")
                }
            }
            .navigationTitle("Панель ответа")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
