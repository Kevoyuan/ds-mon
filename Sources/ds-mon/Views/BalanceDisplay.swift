import SwiftUI

struct BalanceDisplay: View {
    let balance: BalanceInfo?
    let hasAPIKey: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let balance {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Label("Balance", systemImage: "wallet.pass.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(balance.currency?.uppercased() ?? "CREDIT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.whaleBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.whaleBlue.opacity(0.10), in: Capsule())
                    }

                    Text(formatBalance(balance.totalBalance, currency: balance.currency))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: balance.totalBalance))

                    Text("Remaining DeepSeek credit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color.whalePanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.whaleStroke)
                )
                .shadow(color: .whaleBlue.opacity(0.08), radius: 8, x: 0, y: 2)
                .overlay(alignment: .bottomTrailing) {
                    DeepSeekWhaleMark(compact: true)
                        .frame(width: 64, height: 64)
                        .opacity(0.12)
                        .offset(x: 10, y: 12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Granted")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(formatBalance(balance.grantedBalance, currency: balance.currency))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .monospacedDigit()
                            .contentTransition(.numericText(value: balance.grantedBalance))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.whalePanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.whaleStroke)
                    )

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Top-up")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(formatBalance(balance.toppedUpBalance, currency: balance.currency))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .monospacedDigit()
                            .contentTransition(.numericText(value: balance.toppedUpBalance))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(10)
                    .background(Color.whalePanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.whaleStroke)
                    )
                }
            } else {
                VStack(spacing: 10) {
                    DeepSeekWhaleMark()
                        .frame(width: 58, height: 58)
                    Text(hasAPIKey ? "Balance unavailable" : "Add API key to view balance")
                        .font(.system(size: 13, weight: .semibold))
                    Text(hasAPIKey ? "Try refreshing in a moment." : "The whale needs a key before it can swim.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(Color.whalePanel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.whaleStroke)
                )
            }
        }
    }

    private func formatBalance(_ value: Double, currency: String?) -> String {
        switch currency?.uppercased() {
        case "USD":
            return String(format: "$%.2f", value)
        case "CNY":
            return String(format: "¥%.2f", value)
        default:
            return String(format: "%.2f", value)
        }
    }
}
