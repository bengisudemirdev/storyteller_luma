import SwiftUI

enum PaywallSource {
    case manual
    case insufficientCredits(required: Int)
}

struct PaywallView: View {
    let source: PaywallSource

    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeViewModel = CreditStoreViewModel()
    @StateObject private var purchaseViewModel = PurchaseViewModel()
    @ObservedObject private var balanceViewModel = CreditBalanceViewModel.shared

    var body: some View {
        ZStack {
            LumaWarmScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    topBar
                    header
                    fixedCostInfo
                    balanceCard
                    packageList
                    footerActions
                }
                .padding(20)
                .padding(.bottom, 24)
            }
        }
        .task {
            await balanceViewModel.refreshBalance()
            await storeViewModel.loadPackages()
        }
        .alert("Islem bilgisi", isPresented: errorAlertBinding) {
            Button("Tamam") {
                purchaseViewModel.resetState()
            }
        } message: {
            Text(presentError ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(HomeDashboardPalette.muted)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.9)))
            }
            .buttonStyle(.plain)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kredi Magazasi")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(HomeDashboardPalette.ink)
            Text(headerDescription)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.muted)
        }
    }

    private var fixedCostInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("1 masal = 500 kredi")
            Text("1 seslendirme = 3000 kredi")
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(HomeDashboardPalette.accentOrange)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
    }

    private var balanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kredi Bakiyesi")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
                Text("\(balanceViewModel.balance) kredi")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.ink)
            }
            Spacer()
            if balanceViewModel.isRefreshing || purchaseViewModel.isBusy {
                ProgressView()
                    .tint(HomeDashboardPalette.accentOrange)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 10, x: 0, y: 4)
        )
    }

    private var packageList: some View {
        VStack(spacing: 12) {
            if storeViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if storeViewModel.packages.isEmpty {
                Text(storeViewModel.errorMessage ?? "Paketler su an yuklenemedi.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.muted)
            } else {
                ForEach(storeViewModel.packages) { package in
                    packageCard(package)
                }
            }
        }
    }

    private func packageCard(_ package: RevenueCatCreditPackage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.config.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text(package.config.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.muted)
                }
                Spacer()
                if let badge = package.config.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(HomeDashboardPalette.accentOrange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(HomeDashboardPalette.accentOrange.opacity(0.14)))
                }
            }

            Text("\(package.config.credits) kredi • \(package.config.displayPrice)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.ink)
            Text(package.config.valueHint)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(HomeDashboardPalette.sectionCaption)

            Button {
                Task {
                    await purchaseViewModel.purchase(package)
                    if case .success = purchaseViewModel.state {
                        dismiss()
                    }
                }
            } label: {
                Text(package.config.ctaTitle)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(HomeDashboardPalette.nightMid)
                    )
            }
            .buttonStyle(.plain)
            .disabled(purchaseViewModel.isBusy)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(HomeDashboardPalette.cardSurface)
                .shadow(color: HomeDashboardPalette.cardShadow, radius: 12, x: 0, y: 4)
        )
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            Button {
                Task { await purchaseViewModel.restore() }
            } label: {
                Text("Satin alimlari senkronize et")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(HomeDashboardPalette.accentOrange)
            }
            .buttonStyle(.plain)
            .disabled(purchaseViewModel.isBusy)
        }
        .frame(maxWidth: .infinity)
    }

    private var headerDescription: String {
        switch source {
        case .manual:
            return "Ihtiyacin kadar kredi al, diledigin zaman kullan."
        case .insufficientCredits(let required):
            return "Bu islem icin \(required) kredi gerekiyor. Paketinizi secip devam edin."
        }
    }

    private var presentError: String? {
        if case .failed(let message) = purchaseViewModel.state {
            return message
        }
        return nil
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { presentError != nil },
            set: { newValue in
                if !newValue {
                    purchaseViewModel.resetState()
                }
            }
        )
    }
}

#Preview {
    PaywallView(source: .manual)
}
