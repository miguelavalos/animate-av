import AVAppShellFoundation
import SwiftUI

struct MomentsHomeCreditBreakdown: View {
    let balance: MomentsCreditBalance

    var body: some View {
        AVAppShellMetricStrip(
            metrics: MomentsCreditCopy.detailRows(for: balance).map { row in
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
