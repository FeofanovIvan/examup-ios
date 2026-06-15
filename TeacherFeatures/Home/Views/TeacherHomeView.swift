import SwiftUI

struct TeacherHomeView: View {
    @StateObject var viewModel: TeacherHomeViewModel
    @ObservedObject var notificationsViewModel: NotificationsViewModel
    let contentStore: EducationalContentStore
    let seedDataBootstrapService: SeedDataBootstrapServicing
    let assignmentRepository: TeacherAssignmentRepository
    let studentsRepository: TeacherStudentsRepository
    let onSignOut: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                header

                VStack(spacing: 10) {
                    ForEach(viewModel.sections) { section in
                        TeacherHomeSectionPager(section: section)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
        .background(Color(hex: "FBFCFF"))
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
        }
        .navigationDestination(for: TeacherHomeRoute.self) { route in
            switch route {
            case .students:
                TeacherStudentsView(
                    repository: studentsRepository,
                    assignmentHistoryRepository: FirestoreTeacherAssignmentHistoryRepository(contentStore: contentStore)
                )
            case .addStudent:
                TeacherStudentEditorView(student: nil, repository: studentsRepository)
            case .inviteStudent:
                TeacherInviteStudentView(repository: studentsRepository)
            case .assignmentConstructor:
                TeacherAssignmentConstructorView(
                    viewModel: TeacherAssignmentConstructorViewModel(
                        summary: viewModel.summary,
                        contentStore: contentStore,
                        seedDataBootstrapService: seedDataBootstrapService,
                        repository: assignmentRepository,
                        studentsRepository: studentsRepository
                    )
                )
            case .assignmentHistory:
                TeacherAssignmentHistoryView(
                    viewModel: TeacherAssignmentHistoryViewModel(
                        repository: FirestoreTeacherAssignmentHistoryRepository(contentStore: contentStore)
                    )
                )
            case .settings:
                TeacherSettingsView(summary: viewModel.summary, onSignOut: onSignOut)
            }
        }
        .navigationDestination(for: TeacherSettingsRoute.self) { route in
            TeacherSettingsDestinationView(route: route)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("Привет, \(viewModel.summary.displayName)")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "17213A"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text("👋")
                    .font(.system(size: 21))
                    .padding(.top, 4)

                Spacer(minLength: 10)

                NavigationLink {
                    NotificationsView(viewModel: notificationsViewModel)
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(Color(hex: "17213A"))
                            .frame(width: 48, height: 48)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(Color(hex: "E7E9F1"), lineWidth: 1)
                            }
                            .shadow(color: .black.opacity(0.06), radius: 14, x: 0, y: 8)

                        if notificationsViewModel.unreadCount > 0 {
                            Text("\(notificationsViewModel.unreadCount)")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(minWidth: 21, minHeight: 21)
                                .background(Color(hex: "7257F4"))
                                .clipShape(Circle())
                                .offset(x: 7, y: -6)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Button {
                UIPasteboard.general.string = viewModel.summary.publicId
            } label: {
                HStack(spacing: 8) {
                    Text("ID \(viewModel.summary.publicId)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "17213A"))

                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(hex: "7F8799"))
                }
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(Color(hex: "F1EBFF"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(studentCountText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))

                Text(viewModel.summary.subjectTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "8C94A3"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }

    private var studentCountText: String {
        "\(viewModel.summary.studentsCount) \(studentWord(for: viewModel.summary.studentsCount))"
    }

    private func studentWord(for count: Int) -> String {
        let lastTwo = count % 100
        let last = count % 10

        if (11...14).contains(lastTwo) {
            return "учеников"
        }

        switch last {
        case 1:
            return "ученик"
        case 2...4:
            return "ученика"
        default:
            return "учеников"
        }
    }
}

private struct TeacherSettingsDestinationView: View {
    let route: TeacherSettingsRoute
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch route {
        case .profile:
            ProfileSettingsView(
                viewModel: ProfileSettingsViewModel(
                    repository: FirebaseProfileSettingsRepository()
                ),
                onBack: { dismiss() }
            )
        case .security:
            SecuritySettingsView(
                viewModel: SecuritySettingsViewModel(
                    repository: FirebaseSecuritySettingsRepository()
                ),
                onBack: { dismiss() }
            )
        case .notifications:
            NotificationsSettingsView(
                viewModel: NotificationsSettingsViewModel(),
                onBack: { dismiss() }
            )
        case .examSettings:
            ExamSettingsView(
                viewModel: ExamSettingsViewModel(),
                onBack: { dismiss() }
            )
        case .deadlines:
            DeadlinesSettingsView(
                viewModel: DeadlinesSettingsViewModel(),
                onBack: { dismiss() }
            )
        case .support:
            SupportView(onBack: { dismiss() })
        case .about:
            AboutView(onBack: { dismiss() })
        }
    }
}

private struct TeacherHomeSectionPager: View {
    let section: TeacherHomeSection
    @State private var selectedPageID: String

    init(section: TeacherHomeSection) {
        self.section = section
        _selectedPageID = State(initialValue: section.pages.first?.id ?? "")
    }

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $selectedPageID) {
                ForEach(section.pages) { card in
                    NavigationLink(value: card.route) {
                        TeacherHomeCard(card: card)
                    }
                    .buttonStyle(.plain)
                    .tag(card.id)
                }
            }
            .frame(height: 150)
            .tabViewStyle(.page(indexDisplayMode: .never))

            if section.pages.count > 1 {
                TeacherPageDots(
                    pages: section.pages,
                    selectedPageID: selectedPageID,
                    activeColor: Color(hex: section.pages.first?.accentHex ?? "7257F4")
                )
            }
        }
    }
}

private struct TeacherHomeCard: View {
    let card: TeacherHomeActionCard

    var body: some View {
        HStack(spacing: 12) {
            icon

            VStack(alignment: .leading, spacing: 6) {
                Text(card.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: "17213A"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(card.subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "687083"))
                    .lineSpacing(2)
                    .lineLimit(3)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .frame(height: 150)
        .background(Color(hex: card.backgroundHex))
        .overlay(alignment: .bottomTrailing) {
            decorativeImage
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: card.accentHex).opacity(0.08), lineWidth: 1)
        }
    }

    private var icon: some View {
        Image(systemName: card.systemImage)
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 58, height: 58)
            .background(
                LinearGradient(
                    colors: [Color(hex: card.iconHex).opacity(0.88), Color(hex: card.iconHex)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: card.iconHex).opacity(0.28), radius: 12, x: 0, y: 8)
    }

    @ViewBuilder
    private var decorativeImage: some View {
        if let assetName = card.assetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 96)
                .opacity(0.72)
                .offset(x: 14, y: 10)
                .allowsHitTesting(false)
        }
    }
}

private struct TeacherPageDots: View {
    let pages: [TeacherHomeActionCard]
    let selectedPageID: String
    let activeColor: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(pages) { page in
                Circle()
                    .fill(page.id == selectedPageID ? activeColor : Color(hex: "DDE1EA"))
                    .frame(width: page.id == selectedPageID ? 8 : 7, height: page.id == selectedPageID ? 8 : 7)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
