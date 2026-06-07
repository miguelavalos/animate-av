import AVAppShellFoundation
import AVBrandFoundation
import Photos
import SwiftUI
import UIKit

enum MomentsSharedMediaItem: Identifiable, Equatable {
    case local(MomentsSelectedMedia)
    case synced(MomentMediaAsset)

    var id: String {
        switch self {
        case .local(let media):
            return media.id.uuidString
        case .synced(let media):
            return media.id
        }
    }

    var kind: String {
        switch self {
        case .local(let media):
            return media.kind
        case .synced(let media):
            return media.kind
        }
    }

    var displayKind: String {
        MomentStatusRules.displayKind(kind)
    }

    static func preferred(localMedia: [MomentsSelectedMedia], syncedMedia: [MomentMediaAsset]) -> [MomentsSharedMediaItem] {
        if !localMedia.isEmpty {
            return localMedia.map(Self.local)
        }

        return syncedMedia
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(Self.synced)
    }
}

struct MomentsSharedMediaSummaryStack: View {
    let localMedia: [MomentsSelectedMedia]
    let syncedMedia: [MomentMediaAsset]

    private var items: [MomentsSharedMediaItem] {
        MomentsSharedMediaItem.preferred(localMedia: localMedia, syncedMedia: syncedMedia)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                ForEach(Array(items.prefix(4).enumerated()), id: \.element.id) { index, item in
                    MomentsSharedMediaThumbnailContent(item: item, size: 74)
                        .frame(width: 74, height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(.white.opacity(0.95), lineWidth: 2)
                        }
                        .shadow(color: AVBrandColor.ink.opacity(0.09), radius: 6, x: 0, y: 3)
                        .offset(x: CGFloat(index) * -6, y: CGFloat(index) * 3)
                        .rotationEffect(.degrees(Double(index - 1) * -2.0))
                }
            }
            .frame(width: 92, height: 92, alignment: .center)

            Text("\(items.count)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.52), in: Capsule())
                .padding(4)
        }
        .frame(width: 92, height: 92)
    }
}

struct MomentsSharedMediaStrip: View {
    let localMedia: [MomentsSelectedMedia]
    let syncedMedia: [MomentMediaAsset]
    var maxCount = 12
    var tileSize: CGFloat = 58

    private var items: [MomentsSharedMediaItem] {
        Array(MomentsSharedMediaItem.preferred(localMedia: localMedia, syncedMedia: syncedMedia).prefix(maxCount))
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 9) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    MomentsSharedMediaIndexedTile(item: item, index: index, size: tileSize)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }
}

struct MomentsSharedSyncedMediaGrid: View {
    let mediaAssets: [MomentMediaAsset]
    var minimumTileWidth: CGFloat = 72
    var spacing: CGFloat = 8

    private var sortedMediaAssets: [MomentMediaAsset] {
        mediaAssets.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minimumTileWidth), spacing: spacing)]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: spacing) {
            ForEach(Array(sortedMediaAssets.enumerated()), id: \.element.id) { index, media in
                MomentsSharedMediaIndexedTile(item: .synced(media), index: index, size: minimumTileWidth)
            }
        }
    }
}

struct MomentsSharedMediaIndexedTile: View {
    let item: MomentsSharedMediaItem
    let index: Int
    var size: CGFloat = 58

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            MomentsSharedMediaThumbnailContent(item: item, size: size)

            Text("\(index + 1)")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(.black.opacity(0.54), in: Capsule())
                .padding(5)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.48), lineWidth: 1)
        }
        .accessibilityLabel("\(item.displayKind) \(index + 1)")
    }
}

struct MomentsSharedMediaThumbnailContent: View {
    let item: MomentsSharedMediaItem
    var size: CGFloat?

    var body: some View {
        switch item {
        case .local(let media):
            localThumbnail(media)
        case .synced(let media):
            AnimateCreateSyncedMediaThumbnailImage(media: media, size: size)
        }
    }

    @ViewBuilder
    private func localThumbnail(_ media: MomentsSelectedMedia) -> some View {
        if media.kind == "photo", let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            MomentsSharedMediaFallbackThumbnail(kind: media.kind, size: size)
        }
    }
}

struct MomentsSharedMediaFallbackThumbnail: View {
    let kind: String
    var size: CGFloat?

    var body: some View {
        ZStack {
            AVBrandColor.neutral100
            Image(systemName: kind == "video" ? "video.fill" : "photo.fill")
                .font(.system(size: size == nil ? 24 : 18, weight: .semibold))
                .foregroundStyle(AnimateTheme.highlight)
        }
        .frame(width: size, height: size)
    }
}

struct AnimateCreateMediaRow: View {
    let media: MomentsSelectedMedia
    let remove: () -> Void

    var body: some View {
        AVAppShellInfoRow(
            title: media.originalFilename,
            detail: "\(localizedKind(media.kind)) · \(media.displaySize)",
            systemImage: media.kind == "video" ? "video.fill" : "photo.fill"
        ) {
            Button(role: .destructive, action: remove) {
                Image(systemName: "minus.circle")
                    .font(.system(size: 18, weight: .semibold))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("create.mediaRows.removeNamed", media.originalFilename))
        }
    }

    private func localizedKind(_ kind: String) -> String {
        kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo")
    }
}

struct AnimateCreateMediaThumbnailTile: View {
    let media: MomentsSelectedMedia
    let index: Int
    let openDetails: () -> Void

    var body: some View {
        Button(action: openDetails) {
            ZStack(alignment: .bottomLeading) {
                thumbnail

                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.48), in: Capsule())
                    .padding(7)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string("create.mediaCard.mediaAccessibility", localizedKind, index + 1))
    }

    private var localizedKind: String {
        media.kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if media.kind == "photo", let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            ZStack {
                AVBrandColor.neutral100
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
        }
    }
}

struct AnimateCreateMediaDetailSheet: View {
    let media: MomentsSelectedMedia
    let remove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            preview

            VStack(alignment: .leading, spacing: 6) {
                Text(localizedKind)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(media.displaySize)
                    .font(AVBrandTypography.captionStrong)
                    .foregroundStyle(AVBrandColor.textSecondary)
            }

            Button(role: .destructive, action: remove) {
                Label(L10n.string("create.mediaRows.removeFromMoment"), systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var preview: some View {
        if media.kind == "photo", let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1.25, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        } else {
            ZStack {
                AVBrandColor.neutral100
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1.25, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var localizedKind: String {
        media.kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo")
    }
}

struct AnimateCreateSyncedMediaThumbnailTile: View {
    let media: MomentMediaAsset
    let index: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AnimateCreateSyncedMediaThumbnailImage(media: media)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white, AnimateTheme.highlight)
                .padding(7)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel(L10n.string("create.mediaCard.mediaAccessibility", localizedKind, index + 1))
    }

    private var localizedKind: String {
        media.kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo")
    }
}

struct AnimateCreateSyncedMediaThumbnailImage: View {
    let media: MomentMediaAsset
    var size: CGFloat?
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                AVBrandColor.neutral100
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: size == nil ? 24 : 20, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .task(id: "\(media.id)-\(media.platformMediaAssetId ?? "")") {
            image = MomentsLocalMediaThumbnailCache.thumbnail(
                mediaAssetId: media.id,
                platformMediaAssetId: media.platformMediaAssetId
            )
            guard image == nil else { return }
            image = await AnimateCreateLocalPhotoThumbnailLoader.thumbnail(
                for: media.platformMediaAssetId,
                targetSize: CGSize(width: 220, height: 220)
            )
            if let image {
                MomentsLocalMediaThumbnailCache.store(
                    image,
                    mediaAssetId: media.id,
                    platformMediaAssetId: media.platformMediaAssetId
                )
            }
        }
    }
}

private enum AnimateCreateLocalPhotoThumbnailLoader {
    static func thumbnail(for localIdentifier: String?, targetSize: CGSize) async -> UIImage? {
        guard let localIdentifier, !localIdentifier.isEmpty else { return nil }
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = result.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

struct AnimateCreateSyncedMediaRow: View {
    let media: MomentMediaAsset

    var body: some View {
        AVAppShellInfoRow(
            title: "\(MomentStatusRules.displayKind(media.kind)) \(Int(media.sortOrder) + 1)",
            detail: AnimateVideoFormatting.mediaAssetDetail(media),
            systemImage: media.kind == "video" ? "video.fill" : "photo.fill"
        ) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AnimateTheme.highlight)
                .font(.system(size: 18, weight: .semibold))
        }
    }
}

struct AnimateCreateEmptySectionRow: View {
    let systemImage: String
    let message: String

    var body: some View {
        AVAppShellInlineMessage(message: message, systemImage: systemImage)
    }
}
