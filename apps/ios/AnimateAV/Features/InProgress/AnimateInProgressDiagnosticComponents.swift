import SwiftUI

struct AnimateInProgressDiagnosticStatusBadge: View {
    let status: String

    var body: some View {
        Text(AnimateStatusRules.displayTitle(for: status))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.14), in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case "available", "completed":
            .green
        case "failed", "error", "blocked":
            .red
        case "processing", "queued", "rendering":
            .orange
        default:
            .secondary
        }
    }
}
