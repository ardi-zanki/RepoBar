import RepoBarCore
import SwiftUI

struct GitHubAPISettingsView: View {
    @Bindable var session: Session
    let appState: AppState
    @State private var isRefreshing = false

    var body: some View {
        let now = Date()
        let state = self.session.rateLimitDisplayState

        Form {
            Section {
                LabeledContent("Status") {
                    Text(state.compactSummary(now: now))
                        .multilineTextAlignment(.trailing)
                }

                if let updated = self.lastUpdatedText(state: state, now: now) {
                    LabeledContent("Updated") {
                        Text(updated)
                    }
                }

                Button {
                    Task { await self.refresh() }
                } label: {
                    if self.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Refresh")
                    }
                }
                .disabled(self.isRefreshing)
            } header: {
                Text("GitHub API Status")
            }

            ForEach(Array(self.detailSections(state: state, now: now).enumerated()), id: \.offset) { _, section in
                Section(section.title ?? "Details") {
                    ForEach(Array(section.resourceRows.enumerated()), id: \.offset) { _, row in
                        GitHubAPIRateLimitRow(row: row)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .task {
            await self.refresh()
        }
    }

    private func detailSections(state: RateLimitDisplayState, now: Date) -> [RateLimitDisplaySection] {
        state.sections(now: now).filter { section in
            section.title != "Current Status"
        }
    }

    private func lastUpdatedText(state: RateLimitDisplayState, now: Date) -> String? {
        state.lastUpdatedAt.map {
            RelativeFormatter.string(from: $0, relativeTo: now)
        }
    }

    private func refresh() async {
        guard !self.isRefreshing else { return }

        self.isRefreshing = true
        defer { self.isRefreshing = false }
        await self.appState.refreshRateLimitDisplayState()
    }
}

private struct GitHubAPIRateLimitRow: View {
    let row: RateLimitDisplayRow

    var body: some View {
        if self.row.resource != nil || self.row.quotaText != nil {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(self.row.resource ?? self.row.text)
                        .font(.body.weight(.medium))

                    Spacer(minLength: 12)

                    if let quota = self.row.quotaText {
                        Text(quota)
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }

                if let percent = self.row.percentRemaining {
                    ProgressView(value: percent, total: 100)
                        .tint(Self.tint(for: percent))
                        .accessibilityLabel(self.row.resource ?? "GitHub rate limit")
                        .accessibilityValue("\(Int(percent)) percent remaining")
                }

                if let reset = self.row.resetText {
                    Text(reset)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let detail = self.nonSampledDetail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 2)
        } else {
            Text(self.row.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var nonSampledDetail: String? {
        guard let detail = self.row.detailText,
              detail.isEmpty == false,
              detail.hasPrefix("sampled ") == false
        else { return nil }

        if let reset = self.row.resetText {
            let repeatedSuffix = " · \(reset)"
            if detail.hasSuffix(repeatedSuffix) {
                return String(detail.dropLast(repeatedSuffix.count))
            }
        }
        return detail
    }

    private static func tint(for percent: Double) -> Color {
        if percent <= 10 {
            return .red
        }
        if percent <= 30 {
            return .orange
        }
        return .green
    }
}
