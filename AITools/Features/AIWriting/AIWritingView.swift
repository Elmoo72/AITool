import SwiftUI

struct AIWritingView: View {
    @StateObject private var viewModel = AIWritingViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var apphudService: ApphudService
    @State private var showPaywall = false

    private let chipColumns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image("ic_back")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: { viewModel.clearResult() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hero icon + title
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primaryGradient)
                                    .frame(width: 56, height: 56)
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundColor(.white)
                            }

                            Text("AI Writing")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)

                        // Text Input
                        VStack(alignment: .trailing, spacing: 6) {
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.inputBackground)

                                if viewModel.inputText.isEmpty {
                                    Text("Enter your text here...")
                                        .foregroundColor(AppColors.textSecondary)
                                        .padding(14)
                                }

                                TextEditor(text: $viewModel.inputText)
                                    .scrollContentBackground(.hidden)
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(10)
                                    .onChange(of: viewModel.inputText) { newValue in
                                        viewModel.updateText(newValue)
                                    }
                            }
                            .frame(minHeight: 130)

                            Text("\(viewModel.characterCount)/400")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.horizontal, 16)

                        // Action Chips — 2x2 grid
                        LazyVGrid(columns: chipColumns, spacing: 10) {
                            ForEach(WritingAction.allCases, id: \.self) { action in
                                Button(action: { viewModel.selectedAction = action }) {
                                    Text(action.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(
                                            viewModel.selectedAction == action
                                                ? AppColors.primaryGradientStart
                                                : AppColors.textPrimary
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(AppColors.inputBackground)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    viewModel.selectedAction == action
                                                        ? AppColors.primaryGradientStart
                                                        : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)

                        // Dropdowns
                        VStack(spacing: 1) {
                            dropdownRow(label: "Translate") {
                                Menu {
                                    ForEach(WritingLanguage.allCases, id: \.self) { lang in
                                        Button(lang.rawValue) { viewModel.selectedLanguage = lang }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.selectedLanguage.rawValue)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }

                            Divider()
                                .background(AppColors.separatorColor)
                                .padding(.horizontal, 16)

                            dropdownRow(label: "Style") {
                                Menu {
                                    ForEach(WritingStyle.allCases, id: \.self) { style in
                                        Button(style.rawValue) { viewModel.selectedStyle = style }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(viewModel.selectedStyle.rawValue)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textPrimary)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                        }
                        .background(AppColors.inputBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        // Result
                        if let result = viewModel.resultText {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Result")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.textSecondary)

                                Text(result)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.textPrimary)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer().frame(height: 16)
                    }
                    .padding(.vertical, 8)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.resultText)
                }

                // Generate Button
                VStack(spacing: 0) {
                    Divider().background(AppColors.separatorColor)
                    GradientButton(
                        title: "Generate",
                        action: { viewModel.generate() },
                        isLoading: viewModel.isLoading
                    )
                    .padding(16)
                }
                .background(AppColors.cardBackground)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !apphudService.hasActiveSubscription {
                showPaywall = true
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(apphudService: apphudService)
                .environmentObject(apphudService)
        }
    }

    @ViewBuilder
    private func dropdownRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

#Preview {
    AIWritingView()
        .environmentObject(ApphudService.shared)
}
