import SwiftUI

struct ExamQuestionSideMenu: View {
    let tasks: [EducationalTask]
    let currentIndex: Int
    let answeredTaskIDs: Set<EducationalTask.ID>
    let onSelect: (Int) -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Задания")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(ink)

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "EF4444"))
                                .frame(width: 34, height: 34)
                                .background(Color(hex: "FFF0F1"))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text("\(answeredTaskIDs.count) из \(tasks.count) отвечено")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 11)
                        .frame(height: 28)
                        .background(Color(hex: "F4F0FF"))
                        .clipShape(Capsule())
                }
                .padding(.top, 18)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                            Button {
                                onSelect(index)
                            } label: {
                                HStack(spacing: 10) {
                                    Text("Вопрос \(task.questionNumber ?? "\(index + 1)")")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(index == currentIndex ? accent : ink)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                    Spacer()
                                    if answeredTaskIDs.contains(task.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(accent)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(index == currentIndex ? Color(hex: "F4F0FF") : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(index == currentIndex ? accent.opacity(0.24) : Color(hex: "E9ECF4"), lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 18)
                }

                Spacer()
            }
            .frame(width: 250)
            .background(Color(hex: "FBFCFF"))
            .shadow(color: accent.opacity(0.14), radius: 18, x: 5, y: 0)

            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)
        }
    }

    private var accent: Color { Color(hex: "7257F4") }
    private var ink: Color { Color(hex: "20242D") }
}
