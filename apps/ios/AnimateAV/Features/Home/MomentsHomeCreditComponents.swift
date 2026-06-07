import AVAppShellFoundation
import SwiftUI

struct MomentsHomeCreditBreakdown: View {
    let balance: AnimateCreditBalance

    var body: some View {
        AVAppShellMetricStrip(
            metrics: AnimateCreditCopy.detailRows(for: balance).map { row in
                AVAppShellMetric(
                    id: row.id,
                    title: row.title,
                    value: "\(row.value)"
                )
            },
            minTileHeight: 54
        )
    }
}
