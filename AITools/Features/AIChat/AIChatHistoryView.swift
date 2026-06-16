import SwiftUI

struct AIChatHistoryView: View {
    @ObservedObject var viewModel: AIChatViewModel
    @Environment(\.dismiss) var dismiss

    private var groupedSessions: [(String, [ChatSession])] {
        let calendar = Calendar.current
        let now = Date()

        var today: [ChatSession] = []
        var yesterday: [ChatSession] = []
        var older: [String: [ChatSession]] = [:]

        for session in viewModel.sessions {
            if calendar.isDateInToday(session.createdAt) {
                today.append(session)
            } else if calendar.isDateInYesterday(session.createdAt) {
                yesterday.append(session)
            } else {
                let key = session.createdAt.formatted(.dateTime.day().month(.wide))
                older[key, default: []].append(session)
            }
        }

        var result: [(String, [ChatSession])] = []
        if !today.isEmpty { result.append(("Today", today)) }
        if !yesterday.isEmpty { result.append(("Yesterday", yesterday)) }
        let sortedOlder = older.sorted { a, b in
            (a.value.first?.createdAt ?? now) > (b.value.first?.createdAt ?? now)
        }
        result += sortedOlder.map { ($0.key, $0.value) }
        return result
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                Divider().background(AppColors.separatorColor)

                if viewModel.sessions.isEmpty {
                    emptyState
                } else {
                    sessionsList
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image("ic_back")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text("AI Chat History")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppColors.cardBackground)
    }

    private var sessionsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(groupedSessions, id: \.0) { group in
                    VStack(spacing: 4) {
                        ForEach(group.1) { session in
                            sessionRow(session)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }

    private func sessionRow(_ session: ChatSession) -> some View {
        NavigationLink(destination: chatViewFor(session)) {
            HStack(spacing: 12) {
                Image("ic_sparkles")
                    .resizable()
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.preview.isEmpty ? "Empty chat" : session.preview)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    Text(session.createdAt.formatted(.dateTime.hour().minute()))
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.cardBackground)
            .cornerRadius(14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                viewModel.deleteSession(session)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func chatViewFor(_ session: ChatSession) -> some View {
        AIChatSessionView(viewModel: viewModel, session: session)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image("ic_magic_pencil")
                .resizable()
                .frame(width: 80, height: 80)

            Text("No chats yet")
                .font(.system(size: 28, weight: .bold))
                .tracking(0.4)
                .foregroundColor(AppColors.textPrimary)

            Text("Start a conversation to see\nyour history here")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AIChatSessionView: View {
    @ObservedObject var viewModel: AIChatViewModel
    let session: ChatSession
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image("ic_back")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(AppColors.primaryGradientStart)
                            .frame(width: 32, height: 32)
                    }

                    Image("ic_sparkles")
                        .resizable()
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("AI Chat")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                        Text(session.createdAt.formatted(.dateTime.day().month(.twoDigits).year()))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppColors.cardBackground)

                Divider().background(AppColors.separatorColor)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(session.messages) { message in
                            MessageBubble(message: message.text, isUser: message.isUser)
                        }
                        Color.clear.frame(height: 1)
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        AIChatHistoryView(viewModel: AIChatViewModel())
    }
}
