import SwiftUI

struct SubjectLibrariesView: View {
    @StateObject var viewModel: SubjectLibrariesViewModel
    let onBack: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                header

                ForEach(viewModel.statuses) { status in
                    subjectRow(status)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "FF3B30"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(Color(hex: "FBFCFF"))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .alert(item: $viewModel.pendingDownload) { confirmation in
            let library = confirmation.library
            return Alert(
                title: Text("Скачать «\(library.title)»?"),
                message: Text(downloadWarning(for: confirmation)),
                primaryButton: .default(Text("Скачать")) {
                    Task { await viewModel.confirmDownload(library: library) }
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Предметы")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Text("Управляйте локальными библиотеками заданий")
                    .font(.system(size: 15))
                    .foregroundStyle(Color(hex: "687083"))
            }
        }
    }

    private func subjectRow(_ status: SubjectLibraryStatus) -> some View {
        let isDownloading = viewModel.downloadingSubjectID == status.id
        let isPreparing = viewModel.preparingSubjectID == status.id
        let isBusy = isDownloading || isPreparing

        return HStack(spacing: 13) {
            Image(systemName: status.library.systemImage)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(Color(hex: status.library.tintHex))
                .frame(width: 50, height: 50)
                .background(Color(hex: status.library.tintHex).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(status.library.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Text(statusSubtitle(status))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
            }

            Spacer()

            Button {
                Task { await viewModel.prepareDownload(status.library) }
            } label: {
                Group {
                    if isBusy {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: status.isDownloaded ? "checkmark" : "arrow.down")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(width: 42, height: 42)
                .foregroundStyle(.white)
                .background(status.isDownloaded ? Color(hex: "22A95A") : Color(hex: "7257F4"))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(status.isDownloaded || viewModel.downloadingSubjectID != nil || viewModel.preparingSubjectID != nil)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
        }
    }

    private func statusSubtitle(_ status: SubjectLibraryStatus) -> String {
        if status.isDownloaded {
            return "Полная база загружена"
        }
        if status.partialBytes > 0 {
            let size = ByteCountFormatter.string(fromByteCount: status.partialBytes, countStyle: .file)
            return "Сохранено \(size), можно продолжить"
        }
        if status.library.hasBundledFreeVersion {
            return "Бесплатная база встроена"
        }
        return "Доступна для загрузки"
    }

    private func downloadWarning(for confirmation: SubjectLibraryDownloadConfirmation) -> String {
        return "\(confirmation.sizeText)\n\nБудут загружены база заданий и обязательный архив со всеми изображениями, аудио и другими ресурсами.\n\nПри обрыве сети загрузка продолжится с сохранённого места."
    }
}
