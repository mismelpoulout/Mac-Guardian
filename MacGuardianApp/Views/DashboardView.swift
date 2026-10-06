import SwiftUI

struct DashboardView: View {
    @State private var model = DashboardViewModel()
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                if let errorMessageKey = model.errorMessageKey {
                    Label {
                        Text(LocalizedStringKey(errorMessageKey))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                        .foregroundStyle(.orange)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                if let overview = model.overview {
                    overviewGrid(overview)
                } else if model.isLoading {
                    ProgressView("Reading system information…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
                Text("Metrics shown here come from local macOS APIs. Scanner-based health and recovery estimates will appear in later phases.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 720, alignment: .leading)
            }
            .padding(32)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .task { await model.refresh() }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MAC GUARDIAN")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.orange)
                Text("System overview")
                    .font(.largeTitle.weight(.semibold))
                Text("A clear view of this Mac, with no estimated values.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await model.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(model.isLoading)
        }
    }

    private func overviewGrid(_ overview: SystemOverview) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let fraction = overview.storageUsageFraction,
               let capacity = overview.capacityBytes,
               let available = overview.availableBytes {
                MetricCard(
                    title: "Startup storage",
                    value: fraction.formatted(.percent.precision(.fractionLength(0)).locale(locale)),
                    detail: "\(formattedBytes(available, style: .file)) available of \(formattedBytes(capacity, style: .file))",
                    symbol: "internaldrive",
                    progress: fraction
                )
            } else {
                MetricCard(title: "Startup storage", value: "Unavailable", detail: "macOS did not provide capacity values.", symbol: "internaldrive")
            }
            MetricCard(
                title: "Physical memory",
                value: formattedBytes(Int64(clamping: overview.physicalMemoryBytes), style: .memory),
                detail: "Installed memory capacity",
                symbol: "memorychip"
            )
            MetricCard(
                title: "Startup volume",
                value: overview.volumeName,
                detail: "Mounted system volume",
                symbol: "externaldrive"
            )
            MetricCard(
                title: "System uptime",
                value: uptimeText(overview.uptime),
                detail: "Since the last restart",
                symbol: "clock"
            )
        }
    }

    private func formattedBytes(_ bytes: Int64, style: ByteCountFormatStyle.Style) -> String {
        bytes.formatted(.byteCount(style: style).locale(locale))
    }

    private func uptimeText(_ interval: TimeInterval) -> String {
        Duration.seconds(Int64(interval))
            .formatted(.units(allowed: [.days, .hours], width: .abbreviated).locale(locale))
    }
}

private struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let detail: LocalizedStringKey
    let symbol: String
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let progress {
                ProgressView(value: progress)
                    .tint(.orange)
            }
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.06)))
    }
}
