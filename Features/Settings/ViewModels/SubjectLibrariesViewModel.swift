import Foundation

@MainActor
final class SubjectLibrariesViewModel: ObservableObject {
    @Published private(set) var statuses: [SubjectLibraryStatus] = []
    @Published private(set) var downloadingSubjectID: String?
    @Published private(set) var preparingSubjectID: String?
    @Published private(set) var errorMessage: String?
    @Published var pendingDownload: SubjectLibraryDownloadConfirmation?

    private let manager: SubjectLibraryManaging

    init(manager: SubjectLibraryManaging) {
        self.manager = manager
    }

    func load() async {
        statuses = await manager.loadStatuses()
    }

    func prepareDownload(_ library: SubjectLibrary) async {
        guard downloadingSubjectID == nil, preparingSubjectID == nil else { return }
        preparingSubjectID = library.id
        defer { preparingSubjectID = nil }
        let size = await manager.downloadSize(for: library)
        pendingDownload = SubjectLibraryDownloadConfirmation(library: library, databaseBytes: size)
    }

    func confirmDownload(library: SubjectLibrary) async {
        pendingDownload = nil
        await download(library)
    }

    private func download(_ library: SubjectLibrary) async {
        guard downloadingSubjectID == nil else { return }
        downloadingSubjectID = library.id
        errorMessage = nil
        defer { downloadingSubjectID = nil }

        do {
            try await manager.download(library)
            statuses = await manager.loadStatuses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SubjectLibraryDownloadConfirmation: Identifiable {
    let library: SubjectLibrary
    let databaseBytes: Int64?

    var id: String { library.id }

    var sizeText: String {
        guard let databaseBytes else {
            return "Точный размер Google Drive не сообщил."
        }
        return "Общий размер базы и ресурсов: \(ByteCountFormatter.string(fromByteCount: databaseBytes, countStyle: .file))."
    }
}
