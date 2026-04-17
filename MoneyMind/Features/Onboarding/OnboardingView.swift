import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private let lastPage = 3

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardingPage(
                        icon: "brain.head.profile",
                        iconColors: [Color(hex: "#1A1A2E"), Color(hex: "#0F3460")],
                        title: "Welcome to MoneyMind",
                        message: "A calm place to see where your money goes, stay within budgets, and grow savings goals — all on your device."
                    )
                    .tag(0)

                    OnboardingPage(
                        icon: "list.bullet.rectangle.portrait.fill",
                        iconColors: [.blue, .cyan],
                        title: "Track every dollar",
                        message: "Log income and expenses with categories. Search and filter by week, month, or year so patterns stay visible."
                    )
                    .tag(1)

                    OnboardingPage(
                        icon: "chart.pie.fill",
                        iconColors: [.orange, .pink],
                        title: "Budgets & insights",
                        message: "Set monthly limits per category, get clear alerts when you’re close, and use reports to understand your spending."
                    )
                    .tag(2)

                    OnboardingPage(
                        icon: "target",
                        iconColors: [.green, .mint],
                        title: "Goals that stick",
                        message: "Save toward what matters with goals and contributions. Optionally set aside part of income when you log a paycheck. Your currency matches your region when possible — change it anytime in Settings."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: page)

                VStack(spacing: 12) {
                    Button {
                        if page >= lastPage {
                            onFinish()
                        } else {
                            withAnimation { page += 1 }
                        }
                    } label: {
                        Text(page >= lastPage ? "Get started" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        onFinish()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

private struct OnboardingPage: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: iconColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: iconColors.first?.opacity(0.35) ?? .clear, radius: 24, y: 12)

                Image(systemName: icon)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}
