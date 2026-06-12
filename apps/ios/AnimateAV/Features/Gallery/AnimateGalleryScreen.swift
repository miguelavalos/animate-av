import AVAppShellFoundation
import AVBrandFoundation
import AVFoundation
import AVKit
import SwiftUI

struct AnimateGalleryScreen: View {
    let startVideoCreation: () -> Void
    let startImageCreation: () -> Void
    let canUseAnimateImageGeneration: Bool

    @EnvironmentObject private var viewModel: AnimateGalleryViewModel
    @State private var pendingDeletion: AnimateGalleryDeletionTarget?
    @State private var selectedVideo: AnimateGalleryVideoPlayerItem?
    @State private var selectedImage: AnimateGalleryImagePresentation?
    @State private var videoPendingInfo: AnimateGalleryVideoPresentation?
    @State private var videoPendingRename: AnimateGalleryVideoPresentation?
    @SceneStorage("animate.gallery.selectedAssetKind") private var selectedAssetKindRaw = AnimateGalleryAssetKind.videos.rawValue

    var body: some View {
        AVAppShellScrollableScreenScaffold {
            AnimateTheme.shellBackground
        } content: {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.string("gallery.title"))
                    .font(.system(size: 34, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(L10n.string("gallery.subtitle"))
                    .font(AVBrandTypography.body)
                    .foregroundStyle(AVBrandColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if canUseAnimateImageGeneration {
                AnimateGalleryAssetKindPicker(selectedAssetKind: selectedAssetKindBinding)
            }

            switch selectedAssetKind {
            case .videos:
                if viewModel.videos.isEmpty {
                    AnimateGalleryEmptyState(
                        systemImage: "play.square.stack.fill",
                        title: L10n.string("gallery.empty.title"),
                        detail: L10n.string("gallery.empty.detail"),
                        actionTitle: L10n.string("gallery.empty.createVideo"),
                        actionSystemImage: "play.rectangle.fill",
                        action: startVideoCreation
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.videos) { video in
                            AnimateGalleryVideoRow(
                                video: video,
                                openVideo: {
                                    if video.isLocalFileAvailable {
                                        selectedVideo = AnimateGalleryVideoPlayerItem(video: video)
                                    }
                                },
                                downloadVideo: {
                                    viewModel.redownloadVideo(video)
                                },
                                showInfo: {
                                    videoPendingInfo = video
                                },
                                renameVideo: {
                                    videoPendingRename = video
                                },
                                deleteVideo: {
                                    pendingDeletion = .video(video)
                                }
                            )
                        }
                    }
                }
            case .images:
                if viewModel.images.isEmpty {
                    AnimateGalleryEmptyState(
                        systemImage: "photo.stack.fill",
                        title: L10n.string("gallery.images.empty.title"),
                        detail: L10n.string("gallery.images.empty.detail"),
                        actionTitle: L10n.string("gallery.images.empty.createImages"),
                        actionSystemImage: "photo.fill",
                        action: startImageCreation
                    )
                } else {
                    AnimateGalleryImagesGrid(
                        images: viewModel.images,
                        openImage: { image in
                            if image.localFileURL != nil {
                                selectedImage = image
                            } else if image.canDownload {
                                viewModel.downloadImage(image)
                            }
                        },
                        downloadImage: { image in
                            viewModel.downloadImage(image)
                        },
                        deleteImage: { image in
                            pendingDeletion = .image(image)
                        }
                    )
                }
            }
        }
        .confirmationDialog(
            pendingDeletion?.title ?? L10n.string("gallery.delete.title"),
            isPresented: deletionConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(pendingDeletion?.buttonTitle ?? L10n.string("gallery.delete.button"), role: .destructive) {
                confirmDeletion()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text(pendingDeletion?.message ?? L10n.string("gallery.delete.message"))
        }
        .sheet(item: $selectedVideo) { item in
            AnimateGalleryVideoPlayerSheet(item: item)
        }
        .sheet(item: $selectedImage) { image in
            AnimateGalleryImageZoomSheet(image: image)
        }
        .sheet(item: $videoPendingInfo) { video in
            AnimateGalleryVideoInfoSheet(video: video)
        }
        .sheet(item: $videoPendingRename) { video in
            AnimateGalleryRenameSheet(video: video) { title in
                viewModel.renameVideo(video, title: title)
            }
            .presentationDetents([.height(230)])
        }
        .onAppear {
            viewModel.startRemoteGalleryObservation()
            resetImageSelectionIfUnavailable()
        }
        .onDisappear {
            viewModel.stopRemoteGalleryObservation()
        }
        .onChange(of: canUseAnimateImageGeneration) { _, _ in
            resetImageSelectionIfUnavailable()
        }
    }

    private var deletionConfirmationPresented: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    pendingDeletion = nil
                }
            }
        )
    }

    private var selectedAssetKind: AnimateGalleryAssetKind {
        guard canUseAnimateImageGeneration else { return .videos }
        return AnimateGalleryAssetKind(rawValue: selectedAssetKindRaw) ?? .videos
    }

    private var selectedAssetKindBinding: Binding<AnimateGalleryAssetKind> {
        Binding(
            get: { selectedAssetKind },
            set: { selectedAssetKindRaw = $0.rawValue }
        )
    }

    private func confirmDeletion() {
        switch pendingDeletion {
        case let .video(video):
            viewModel.deleteVideo(video)
        case let .image(image):
            viewModel.deleteImage(image)
        case nil:
            break
        }
        pendingDeletion = nil
    }

    private func resetImageSelectionIfUnavailable() {
        guard !canUseAnimateImageGeneration else { return }
        selectedAssetKindRaw = AnimateGalleryAssetKind.videos.rawValue
        selectedImage = nil
        if case .image = pendingDeletion {
            pendingDeletion = nil
        }
    }
}

private struct AnimateGalleryAssetKindPicker: View {
    @Binding var selectedAssetKind: AnimateGalleryAssetKind

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AnimateGalleryAssetKind.allCases) { kind in
                Button {
                    selectedAssetKind = kind
                } label: {
                    AnimateGalleryAssetKindPill(
                        title: kind.title,
                        isSelected: selectedAssetKind == kind
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedAssetKind == kind ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.string("gallery.assetKind.accessibility"))
    }
}

private struct AnimateGalleryAssetKindPill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .black))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .foregroundStyle(isSelected ? .white : AVBrandColor.textPrimary)
            .background(background)
            .overlay(border)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? AVBrandColor.accent : AVBrandColor.elevatedSurface)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(AVBrandColor.borderSubtle.opacity(isSelected ? 0 : 0.55), lineWidth: 1)
    }
}

private struct AnimateGalleryImagesGrid: View {
    let images: [AnimateGalleryImagePresentation]
    let openImage: (AnimateGalleryImagePresentation) -> Void
    let downloadImage: (AnimateGalleryImagePresentation) -> Void
    let deleteImage: (AnimateGalleryImagePresentation) -> Void

    private let horizontalSpacing: CGFloat = 12
    private let verticalSpacing: CGFloat = 14

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: verticalSpacing) {
            ForEach(images) { image in
                AnimateGalleryImageTile(
                    image: image,
                    tileWidth: itemWidth,
                    openImage: { openImage(image) },
                    downloadImage: { downloadImage(image) },
                    deleteImage: { deleteImage(image) }
                )
                .frame(width: itemWidth, alignment: .top)
                .clipped()
            }
        }
        .frame(width: gridWidth, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var gridWidth: CGFloat {
        max(280, UIScreen.main.bounds.width - 40)
    }

    private var itemWidth: CGFloat {
        floor((gridWidth - horizontalSpacing) / 2)
    }

    private var columns: [GridItem] {
        [
            GridItem(.fixed(itemWidth), spacing: horizontalSpacing, alignment: .top),
            GridItem(.fixed(itemWidth), spacing: 0, alignment: .top)
        ]
    }
}

private struct AnimateGalleryImageTile: View {
    let image: AnimateGalleryImagePresentation
    let tileWidth: CGFloat
    let openImage: () -> Void
    let downloadImage: () -> Void
    let deleteImage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button(action: openImage) {
                ZStack(alignment: .topTrailing) {
                    AnimateGalleryImageThumbnail(url: image.localFileURL)
                        .frame(width: tileWidth, height: tileWidth)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AVBrandColor.borderSubtle.opacity(0.42), lineWidth: 1)
                        }

                    AnimateGalleryImageMenu(
                        image: image,
                        downloadImage: downloadImage,
                        deleteImage: deleteImage
                    )
                    .padding(7)
                }
                .frame(width: tileWidth, height: tileWidth)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(image.lookTitle)

            VStack(alignment: .leading, spacing: 1) {
                Text(image.lookTitle)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.horizontal, 2)
        }
        .frame(width: tileWidth, alignment: .leading)
    }
}

private struct AnimateGalleryImageMenu: View {
    let image: AnimateGalleryImagePresentation
    let downloadImage: () -> Void
    let deleteImage: () -> Void

    var body: some View {
        Menu {
            if image.canDownload {
                Button(action: downloadImage) {
                    Label(L10n.string("gallery.image.download"), systemImage: "arrow.down.circle.fill")
                }
            }

            if let localFileURL = image.localFileURL {
                ShareLink(item: localFileURL) {
                    Label(L10n.string("common.share"), systemImage: "square.and.arrow.up")
                }
            }

            Button(role: .destructive, action: deleteImage) {
                Label(L10n.string("common.delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: AVBrandColor.ink.opacity(0.13), radius: 8, y: 3)
        }
        .accessibilityLabel(L10n.string("common.more"))
    }
}

private struct AnimateGalleryImageZoomSheet: View {
    let image: AnimateGalleryImagePresentation
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AnimateTheme.shellBackground
                    .ignoresSafeArea()

                AnimateGalleryImageThumbnail(url: image.localFileURL)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(16)
            }
            .navigationTitle(image.lookTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.string("common.close")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if let localFileURL = image.localFileURL {
                        ShareLink(item: localFileURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(L10n.string("common.share"))
                    }
                }
            }
        }
    }
}

private struct AnimateGalleryImageThumbnail: View {
    let url: URL?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AVBrandColor.accent.opacity(0.18),
                    AVBrandColor.accent.opacity(0.06),
                    AVBrandColor.neutral100
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let url, let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo.fill")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(AVBrandColor.accent.opacity(0.70))
            }
        }
    }
}

private enum AnimateGalleryAssetKind: String, CaseIterable, Identifiable {
    case videos
    case images

    var id: String { rawValue }

    var title: String {
        switch self {
        case .videos:
            L10n.string("gallery.assetKind.videos")
        case .images:
            L10n.string("gallery.assetKind.images")
        }
    }
}

private struct AnimateGalleryEmptyState: View {
    let systemImage: String
    let title: String
    let detail: String
    let actionTitle: String
    let actionSystemImage: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 74, height: 74)
                .background(Circle().fill(AVBrandColor.accent.opacity(0.10)))

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(detail)
                    .font(AVBrandTypography.body)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                Label(actionTitle, systemImage: actionSystemImage)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(AVBrandColor.textInverse)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(AVBrandColor.textPrimary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct AnimateGalleryVideoRow: View {
    let video: AnimateGalleryVideoPresentation
    let openVideo: () -> Void
    let downloadVideo: () -> Void
    let showInfo: () -> Void
    let renameVideo: () -> Void
    let deleteVideo: () -> Void

    var body: some View {
        Button(action: primaryAction) {
            ZStack {
                AnimateGalleryVideoThumbnail(url: video.localFileURL, isAvailable: video.isLocalFileAvailable)
                    .frame(height: 184)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.50)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Image(systemName: video.isLocalFileAvailable ? "play.fill" : "arrow.down.circle.fill")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.black.opacity(0.28), in: Circle())

                VStack {
                    HStack {
                        Spacer(minLength: 0)

                        AnimateGalleryVideoMenu(
                            video: video,
                            downloadVideo: downloadVideo,
                            showInfo: showInfo,
                            renameVideo: renameVideo,
                            deleteVideo: deleteVideo
                        )
                    }

                    Spacer(minLength: 0)

                    HStack {
                        Text(video.title)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Spacer(minLength: 0)
                    }
                }
                .padding(12)
            }
        }
        .buttonStyle(.plain)
        .disabled(!video.isLocalFileAvailable && !video.canDownload)
    }

    private func primaryAction() {
        if video.isLocalFileAvailable {
            openVideo()
        } else if video.canDownload {
            downloadVideo()
        }
    }
}

private enum AnimateGalleryDeletionTarget: Identifiable {
    case video(AnimateGalleryVideoPresentation)
    case image(AnimateGalleryImagePresentation)

    var id: String {
        switch self {
        case let .video(video):
            "video:\(video.id)"
        case let .image(image):
            "image:\(image.id)"
        }
    }

    var title: String {
        switch self {
        case .video:
            L10n.string("gallery.delete.video.title")
        case .image:
            L10n.string("gallery.delete.image.title")
        }
    }

    var message: String {
        switch self {
        case .video:
            L10n.string("gallery.delete.video.message")
        case .image:
            L10n.string("gallery.delete.image.message")
        }
    }

    var buttonTitle: String {
        switch self {
        case .video:
            L10n.string("gallery.delete.video.button")
        case .image:
            L10n.string("gallery.delete.image.button")
        }
    }
}

private struct AnimateGalleryVideoMenu: View {
    let video: AnimateGalleryVideoPresentation
    let downloadVideo: () -> Void
    let showInfo: () -> Void
    let renameVideo: () -> Void
    let deleteVideo: () -> Void

    var body: some View {
        Menu {
            Button(action: showInfo) {
                Label(L10n.string("common.info"), systemImage: "info.circle")
            }

            if video.isLocalFileAvailable {
                Button(action: renameVideo) {
                    Label(L10n.string("common.rename"), systemImage: "pencil")
                }
            }

            if video.canDownload {
                Button(action: downloadVideo) {
                    Label(L10n.string("gallery.video.redownload"), systemImage: "arrow.down.circle")
                }
            }

            if video.isLocalFileAvailable, let localFileURL = video.localFileURL {
                ShareLink(item: localFileURL) {
                    Label(L10n.string("common.share"), systemImage: "square.and.arrow.up")
                }
            }

            Button(role: .destructive, action: deleteVideo) {
                Label(video.isLocalFileAvailable ? L10n.string("common.delete") : L10n.string("common.remove"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.92), in: Circle())
        }
    }
}

private struct AnimateGalleryVideoInfoSheet: View {
    let video: AnimateGalleryVideoPresentation
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AnimateGalleryViewModel

    var body: some View {
        let currentVideo = viewModel.videos.first { $0.id == video.id } ?? video
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    AnimateGalleryVideoInfoHero(
                        sourceImageURL: currentVideo.sourceImageURL,
                        generatedImageURL: currentVideo.generatedImageURL
                    )

                    AnimateGalleryMetadataPanel(rows: metadataRows(for: currentVideo))
                }
                .padding(16)
            }
            .background(AnimateTheme.shellBackground.ignoresSafeArea())
            .navigationTitle(L10n.string("gallery.info.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.string("common.close")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.prepareVideoInfo(video)
        }
    }

    private func metadataRows(for video: AnimateGalleryVideoPresentation) -> [AnimateGalleryMetadataRow] {
        let artifact = video.remoteArtifact
        var rows = [
            AnimateGalleryMetadataRow(title: L10n.string("gallery.info.look"), value: video.lookTitle)
        ]

        if let durationSeconds = artifact?.durationSeconds, durationSeconds > 0 {
            rows.append(
                AnimateGalleryMetadataRow(
                    title: L10n.string("gallery.info.duration"),
                    value: L10n.string("gallery.info.duration.seconds", Int(durationSeconds.rounded()))
                )
            )
        }
        if let creditCost = artifact?.creditCost {
            rows.append(
                AnimateGalleryMetadataRow(
                    title: L10n.string("gallery.info.credits"),
                    value: L10n.string("gallery.info.credits.value", creditCost, AnimateCreditCopy.noun(creditCost))
                )
            )
        }
        if let hasWatermark = artifact?.hasWatermark {
            rows.append(
                AnimateGalleryMetadataRow(
                    title: L10n.string("gallery.info.branding"),
                    value: hasWatermark
                        ? L10n.string("gallery.info.branding.included")
                        : L10n.string("gallery.info.branding.removed")
                )
            )
        }
        if video.record.createdAt > 0 {
            rows.append(
                AnimateGalleryMetadataRow(
                    title: L10n.string("gallery.info.saved"),
                    value: AnimateDateFormatting.formattedDate(milliseconds: video.record.createdAt)
                )
            )
        }

        return rows
    }
}

private struct AnimateGalleryVideoInfoHero: View {
    let sourceImageURL: URL?
    let generatedImageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if let sourceImageURL, let generatedImageURL {
                    AnimateGalleryBeforeAfterImageView(
                        sourceImageURL: sourceImageURL,
                        generatedImageURL: generatedImageURL
                    )
                } else {
                    AnimateGalleryImageThumbnail(url: generatedImageURL ?? sourceImageURL)
                }
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.35), lineWidth: 1)
            }
        }
    }
}

private struct AnimateGalleryBeforeAfterImageView: View {
    let sourceImageURL: URL
    let generatedImageURL: URL
    @State private var sourceImage: UIImage?
    @State private var generatedImage: UIImage?
    @State private var reveal: CGFloat = 0.5

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                if let sourceImage, let generatedImage {
                    Image(uiImage: sourceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    Image(uiImage: generatedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .mask(alignment: .leading) {
                            Rectangle()
                                .frame(width: proxy.size.width * reveal)
                        }

                    comparisonLabels
                        .padding(12)

                    Rectangle()
                        .fill(.white.opacity(0.92))
                        .frame(width: 3)
                        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
                        .position(x: proxy.size.width * reveal, y: proxy.size.height / 2)

                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "arrow.left.and.right")
                                .font(.system(size: 15, weight: .black))
                                .foregroundStyle(AVBrandColor.accent)
                        }
                        .shadow(color: .black.opacity(0.20), radius: 10, y: 4)
                        .position(x: proxy.size.width * reveal, y: proxy.size.height / 2)
                } else {
                    AnimateGalleryImageThumbnail(url: generatedImageURL)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let width = max(proxy.size.width, 1)
                        reveal = min(max(value.location.x / width, 0.02), 0.98)
                    }
            )
        }
        .task(id: "\(sourceImageURL.absoluteString)|\(generatedImageURL.absoluteString)") {
            sourceImage = Self.loadImage(url: sourceImageURL)
            generatedImage = Self.loadImage(url: generatedImageURL)
        }
    }

    private var comparisonLabels: some View {
        VStack {
            HStack {
                Text(L10n.string("gallery.info.compare.original"))
                    .font(.system(size: 11, weight: .black))
                    .textCase(.uppercase)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Text(L10n.string("gallery.info.compare.generated"))
                    .font(.system(size: 11, weight: .black))
                    .textCase(.uppercase)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            Spacer()
        }
        .foregroundStyle(AVBrandColor.textPrimary)
    }

    private static func loadImage(url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

private struct AnimateGalleryMetadataPanel: View {
    let rows: [AnimateGalleryMetadataRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rows) { row in
                HStack(alignment: .top, spacing: 14) {
                    Text(row.title)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .textCase(.uppercase)
                        .frame(width: 86, alignment: .leading)

                    Text(row.value)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)

                if row.id != rows.last?.id {
                    Divider()
                        .overlay(AVBrandColor.borderSubtle.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 14)
        .background(AVBrandColor.elevatedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.42), lineWidth: 1)
        }
    }
}

private struct AnimateGalleryMetadataRow: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

private struct AnimateGalleryVideoThumbnail: View {
    let url: URL?
    let isAvailable: Bool
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AVBrandColor.accent.opacity(0.18),
                    AVBrandColor.accent.opacity(0.06),
                    AVBrandColor.neutral100
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: isAvailable ? "play.rectangle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(AVBrandColor.accent.opacity(isAvailable ? 0.80 : 0.45))
            }
        }
        .task(id: url) {
            guard isAvailable, let url else { return }
            image = await Self.loadThumbnail(url: url)
        }
    }

    private static func loadThumbnail(url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)

        guard let cgImage = try? await generator.image(at: .zero).image else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

private struct AnimateGalleryRenameSheet: View {
    let video: AnimateGalleryVideoPresentation
    let save: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    init(video: AnimateGalleryVideoPresentation, save: @escaping (String) -> Void) {
        self.video = video
        self.save = save
        _title = State(initialValue: video.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.string("gallery.rename.placeholder"), text: $title)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle(L10n.string("gallery.rename.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) {
                        save(title)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct AnimateGalleryVideoPlayerItem: Identifiable {
    let id: String
    let title: String
    let url: URL

    init(video: AnimateGalleryVideoPresentation) {
        id = video.id
        title = video.title
        url = video.localFileURL ?? URL(fileURLWithPath: "/dev/null")
    }
}

private struct AnimateGalleryVideoPlayerSheet: View {
    let item: AnimateGalleryVideoPlayerItem
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer

    init(item: AnimateGalleryVideoPlayerItem) {
        self.item = item
        _player = State(initialValue: AVPlayer(url: item.url))
    }

    var body: some View {
        NavigationStack {
            VideoPlayer(player: player)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(item.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(L10n.string("common.done")) {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            player.play()
        }
        .onDisappear {
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
    }
}
