import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @ObservedObject var notificationsViewModel: NotificationsViewModel
    let subjectLibraryManager: SubjectLibraryManaging
    var onExamBlockSelected: (HomeExamBlock) -> Void = { _ in }
    var onNotificationsTap: () -> Void = {}
    var onSubjectDownloadRequested: () -> Void = {}
    @State private var subjectLibraryStatuses: [SubjectLibraryStatus] = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Group {
            switch layoutKind {
            case .phonePortrait:
                StudentPortraitHomeView(
                    viewModel: viewModel,
                    unreadNotifications: notificationsViewModel.unreadCount,
                    subjectLibraryStatuses: subjectLibraryStatuses,
                    onExamBlockSelected: onExamBlockSelected,
                    onNotificationsTap: onNotificationsTap,
                    onSubjectDownloadRequested: onSubjectDownloadRequested,
                    onSubjectMenuOpen: refreshSubjectLibraries
                )
            case .phoneLandscape, .tablet:
                StudentPortraitHomeView(
                    viewModel: viewModel,
                    unreadNotifications: notificationsViewModel.unreadCount,
                    subjectLibraryStatuses: subjectLibraryStatuses,
                    onExamBlockSelected: onExamBlockSelected,
                    onNotificationsTap: onNotificationsTap,
                    onSubjectDownloadRequested: onSubjectDownloadRequested,
                    onSubjectMenuOpen: refreshSubjectLibraries
                )
            }
        }
        .task {
            await viewModel.load()
            subjectLibraryStatuses = await subjectLibraryManager.loadStatuses()
        }
        .onReceive(NotificationCenter.default.publisher(for: .subjectLibraryDidInstall)) { _ in
            refreshSubjectLibraries()
        }
    }

    private var layoutKind: AdaptiveLayoutKind {
        AdaptiveLayoutKind.resolve(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass
        )
    }

    private func refreshSubjectLibraries() {
        Task {
            subjectLibraryStatuses = await subjectLibraryManager.loadStatuses()
        }
    }
}

private struct StudentPortraitHomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let unreadNotifications: Int
    let subjectLibraryStatuses: [SubjectLibraryStatus]
    let onExamBlockSelected: (HomeExamBlock) -> Void
    let onNotificationsTap: () -> Void
    let onSubjectDownloadRequested: () -> Void
    let onSubjectMenuOpen: () -> Void
    @State private var isSubjectMenuOpen = false

    var body: some View {
        ZStack(alignment: .leading) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    subjectSelector

                    VStack(spacing: 10) {
                        ForEach(viewModel.dashboard.blocks) { block in
                            if block.variants.isEmpty {
                                HomeExamBlockCard(block: block, onSelect: onExamBlockSelected)
                            } else {
                                HomeExamVariantPager(block: block, onSelect: onExamBlockSelected)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 14)
            }
            .background(Color(hex: "FBFCFF"))
            .disabled(isSubjectMenuOpen)

            if isSubjectMenuOpen {
                Color.black.opacity(0.18)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            isSubjectMenuOpen = false
                        }
                    }
                    .zIndex(1)

                HomeSubjectSideMenu(
                    statuses: subjectLibraryStatuses,
                    programs: viewModel.dashboard.programs,
                    selectedProgram: viewModel.dashboard.selectedProgram,
                    onSelect: { program in
                        viewModel.selectProgram(program)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            isSubjectMenuOpen = false
                        }
                    },
                    onDownloadRequested: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            isSubjectMenuOpen = false
                        }
                        onSubjectDownloadRequested()
                    },
                    onClose: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                            isSubjectMenuOpen = false
                        }
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(isSubjectMenuOpen ? .hidden : .visible, for: .tabBar)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Привет, \(viewModel.dashboard.userName)")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("ID \(viewModel.dashboard.userPublicID)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "8C94A3"))
                    .lineLimit(1)

                Text(homeUsageText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "4C515C"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer()

            Button(action: onNotificationsTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(Color(hex: "20242D"))
                        .frame(width: 48, height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .shadow(color: .black.opacity(0.07), radius: 14, x: 0, y: 7)

                    if unreadNotifications > 0 {
                        Text("\(unreadNotifications)")
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
            .accessibilityLabel("Уведомления")
        }
    }

    private var homeUsageText: String {
        "\(viewModel.dashboard.studyStreakDays) дн. подряд"
    }

    private var subjectSelector: some View {
        Button {
            onSubjectMenuOpen()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                isSubjectMenuOpen = true
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(subjectColor(for: viewModel.dashboard.selectedProgram.subject.id))
                    Text(subjectSymbol(for: viewModel.dashboard.selectedProgram.subject.id))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Программа")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "8C94A3"))

                    Text(viewModel.dashboard.selectedProgram.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color(hex: "20242D"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer()

                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .frame(height: 64)
        .background(.white)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "E3E7EE"), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func subjectSymbol(for subjectID: String) -> String {
        switch subjectID {
        case "russian":
            return "А"
        case "history":
            return "🏛"
        case "english":
            return "EN"
        default:
            return "√x"
        }
    }

    private func subjectColor(for subjectID: String) -> Color {
        switch subjectID {
        case "russian":
            return Color(hex: "45C38A")
        case "history":
            return Color(hex: "B87938")
        case "english":
            return Color(hex: "E8453F")
        default:
            return Color(hex: "7257F4")
        }
    }
}

private struct HomeSubjectSideMenu: View {
    let statuses: [SubjectLibraryStatus]
    let programs: [HomeStudyProgram]
    let selectedProgram: HomeStudyProgram
    let onSelect: (HomeStudyProgram) -> Void
    let onDownloadRequested: () -> Void
    let onClose: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea(edges: .vertical)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Мои предметы")
                                .font(.system(size: 23, weight: .bold))
                                .foregroundStyle(Color(hex: "20242D"))

                            Text("Выбери программу подготовки")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "687083"))
                        }

                        Spacer()

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "FF3B30"))
                                .frame(width: 36, height: 36)
                                .background(Color(hex: "FFF0F0"))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Сейчас")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color(hex: "8C94A3"))

                        selectedProgramRow(selectedProgram)
                    }

                    Divider()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Все программы")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color(hex: "8C94A3"))

                            ForEach(statuses) { status in
                                Button {
                                    if status.isAvailable,
                                       let program = programs.first(where: { $0.id == status.id }) {
                                        onSelect(program)
                                    } else {
                                        onDownloadRequested()
                                    }
                                } label: {
                                    libraryRow(
                                        status,
                                        program: programs.first(where: { $0.id == status.id }),
                                        isSelected: status.id == selectedProgram.id
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, max(18, geometry.safeAreaInsets.bottom))
                    }
                    .frame(maxHeight: .infinity)
                    .scrollBounceBehavior(.basedOnSize)
                }
                .padding(.top, 18)
                .padding(.horizontal, 18)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 28,
                    style: .continuous
                )
            )
            .shadow(color: .black.opacity(0.16), radius: 24, x: 8, y: 0)
        }
        .frame(width: min(UIScreen.main.bounds.width * 0.84, CGFloat(326)))
    }

    private func libraryRow(
        _ status: SubjectLibraryStatus,
        program: HomeStudyProgram?,
        isSelected: Bool
    ) -> some View {
        let isAvailable = status.isAvailable && program != nil

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(isAvailable ? Color(hex: status.library.tintHex) : Color(hex: "D9DDE6"))

                Image(systemName: status.library.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.library.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isAvailable ? Color(hex: "20242D") : Color(hex: "8C94A3"))

                Text(librarySubtitle(status, isAvailable: isAvailable))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "8C94A3"))
            }

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : (isAvailable ? "chevron.right" : "arrow.down.circle"))
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(isSelected ? Color(hex: "7257F4") : Color(hex: "A8AFBD"))
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(isSelected ? Color(hex: "F6F3FF") : Color(hex: "F7F8FB"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func selectedProgramRow(_ program: HomeStudyProgram) -> some View {
        HStack(spacing: 12) {
            subjectIcon(for: program, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(program.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Text(selectedProgramSubtitle(program))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "687083"))
            }

            Spacer()
        }
        .padding(12)
        .background(Color(hex: "F6F3FF"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func librarySubtitle(_ status: SubjectLibraryStatus, isAvailable: Bool) -> String {
        if status.isDownloaded {
            return "Полная версия"
        }
        if status.library.hasBundledFreeVersion {
            return "Бесплатная версия"
        }
        return isAvailable ? "Библиотека доступна" : "Нажмите, чтобы скачать"
    }

    private func selectedProgramSubtitle(_ program: HomeStudyProgram) -> String {
        guard let status = statuses.first(where: { $0.id == program.id }) else {
            return programSubtitle(for: program)
        }
        return librarySubtitle(status, isAvailable: status.isAvailable)
    }

    private func programRow(_ program: HomeStudyProgram, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            subjectIcon(for: program, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(program.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color(hex: "20242D"))

                Text(programSubtitle(for: program))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "687083"))
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "7257F4"))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .background(isSelected ? Color(hex: "F6F3FF") : Color(hex: "F7F8FB"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func subjectIcon(for program: HomeStudyProgram, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(subjectColor(for: program.subject.id))

            Text(subjectSymbol(for: program.subject.id))
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }

    private func programSubtitle(for program: HomeStudyProgram) -> String {
        switch program.id {
        case "math":
            return "ЕГЭ база и профиль, ОГЭ, 5 ВПР"
        case "russian":
            return "ЕГЭ, ОГЭ, ВПР 6, 7 и 8"
        case "history":
            return "ЕГЭ, ОГЭ, ВПР 6, 7 и 8"
        case "english":
            return "ЕГЭ, ОГЭ, ВПР 6, 7 и 8"
        default:
            return "Индивидуальная подготовка"
        }
    }

    private func subjectSymbol(for subjectID: String) -> String {
        switch subjectID {
        case "russian":
            return "А"
        case "history":
            return "🏛"
        case "english":
            return "EN"
        default:
            return "√x"
        }
    }

    private func subjectColor(for subjectID: String) -> Color {
        switch subjectID {
        case "russian":
            return Color(hex: "45C38A")
        case "history":
            return Color(hex: "B87938")
        case "english":
            return Color(hex: "E8453F")
        default:
            return Color(hex: "7257F4")
        }
    }
}

private struct HomeExamVariantPager: View {
    let block: HomeExamBlock
    let onSelect: (HomeExamBlock) -> Void
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 8) {
            TabView(selection: $currentIndex) {
                ForEach(Array(block.variants.enumerated()), id: \.element.id) { index, variant in
                    HomeExamBlockCard(
                        block: block.selectingVariant(variant),
                        onSelect: onSelect
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 150)

            HStack(spacing: 7) {
                ForEach(block.variants.indices, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color(hex: block.tintHex) : Color(hex: "D8DCE5"))
                        .frame(width: index == currentIndex ? 8 : 7, height: index == currentIndex ? 8 : 7)
                }
            }
        }
    }
}
