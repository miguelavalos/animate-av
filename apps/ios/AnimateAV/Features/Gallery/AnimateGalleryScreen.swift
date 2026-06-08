import AVAppShellFoundation
import AVBrandFoundation
import AVFoundation
import AVKit
import SwiftUI

struct AnimateGalleryScreen: View {
    let startVideoCreation: () -> Void
    let startImageCreation: () -> Void

    @EnvironmentObject private var viewModel: AnimateGalleryViewModel
    @State private var videoPendingDeletion: AnimateGalleryVideoPresentation?
    @State private var selectedVideo: AnimateGalleryVideoPlayerItem?
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

            AnimateGalleryAssetKindPicker(selectedAssetKind: selectedAssetKindBinding)

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
                                renameVideo: {
                                    videoPendingRename = video
                                },
                                deleteVideo: {
                                    videoPendingDeletion = video
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
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.images) { image in
                            AnimateGalleryImageRow(
                                image: image,
                                downloadImage: {
                                    viewModel.downloadImage(image)
                                }
                            )
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            L10n.string("gallery.delete.title"),
            isPresented: deletionConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(L10n.string("gallery.delete.button"), role: .destructive) {
                confirmDeletion()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {
                videoPendingDeletion = nil
            }
        } message: {
            Text(L10n.string("gallery.delete.message"))
        }
        .sheet(item: $selectedVideo) { item in
            AnimateGalleryVideoPlayerSheet(item: item)
        }
        .sheet(item: $videoPendingRename) { video in
            AnimateGalleryRenameSheet(video: video) { title in
                viewModel.renameVideo(video, title: title)
            }
            .presentationDetents([.height(230)])
        }
    }

    private var deletionConfirmationPresented: Binding<Bool> {
        Binding(
            get: { videoPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    videoPendingDeletion = nil
                }
            }
        )
    }

    private var selectedAssetKind: AnimateGalleryAssetKind {
        AnimateGalleryAssetKind(rawValue: selectedAssetKindRaw) ?? .videos
    }

    private var selectedAssetKindBinding: Binding<AnimateGalleryAssetKind> {
        Binding(
            get: { selectedAssetKind },
            set: { selectedAssetKindRaw = $0.rawValue }
        )
    }

    private func confirmDeletion() {
        if let videoPendingDeletion {
            viewModel.deleteVideo(videoPendingDeletion)
        }
        videoPendingDeletion = nil
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

private struct AnimateGalleryImageRow: View {
    let image: AnimateGalleryImagePresentation
    let downloadImage: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                AnimateGalleryImageThumbnail(url: image.localFileURL)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack {
                    HStack {
                        Text(image.availabilityTitle)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(.black.opacity(0.28), in: Capsule())

                        Spacer(minLength: 0)

                        if let localFileURL = image.localFileURL {
                            ShareLink(item: localFileURL) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundStyle(AVBrandColor.textPrimary)
                                    .frame(width: 42, height: 42)
                                    .background(.white.opacity(0.92), in: Circle())
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(image.title)
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.white)

                            Text(AnimateVideoFormatting.galleryDate(image.artifact.createdAt))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white.opacity(0.82))
                        }

                        Spacer(minLength: 0)
                    }
                }
                .padding(14)
            }

            if image.localFileURL == nil, image.canDownload {
                Button(action: downloadImage) {
                    Label(L10n.string("gallery.image.download"), systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: AVBrandColor.ink.opacity(0.05), radius: 18, x: 0, y: 10)
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
    let renameVideo: () -> Void
    let deleteVideo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: openVideo) {
                ZStack {
                    AnimateGalleryVideoThumbnail(url: video.localFileURL, isAvailable: video.isLocalFileAvailable)
                        .frame(height: 176)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    LinearGradient(
                        colors: [.black.opacity(0.02), .black.opacity(0.56)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Image(systemName: video.isLocalFileAvailable ? "play.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 23, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(.black.opacity(0.28), in: Circle())

                    VStack {
                        HStack {
                            Text(video.availabilityTitle)
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 7)
                                .background(.black.opacity(0.28), in: Capsule())

                            Spacer(minLength: 0)

                            AnimateGalleryVideoMenu(
                                video: video,
                                downloadVideo: downloadVideo,
                                renameVideo: renameVideo,
                                deleteVideo: deleteVideo
                            )
                        }

                        Spacer(minLength: 0)

                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.title)
                                    .font(.system(size: 22, weight: .black))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)

                                Text(AnimateVideoFormatting.galleryDate(video.record.createdAt))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.82))
                            }

                            Spacer(minLength: 0)

                            if video.isLocalFileAvailable, let localFileURL = video.localFileURL {
                                ShareLink(item: localFileURL) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15, weight: .black))
                                        .foregroundStyle(AVBrandColor.textPrimary)
                                        .frame(width: 42, height: 42)
                                        .background(.white.opacity(0.92), in: Circle())
                                }
                            }
                        }
                    }
                    .padding(14)
                }
            }
            .buttonStyle(.plain)
            .disabled(!video.isLocalFileAvailable)

            if video.canDownload {
                Button(action: downloadVideo) {
                    Label(L10n.string("gallery.video.redownload"), systemImage: "arrow.down.circle.fill")
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: AVBrandColor.ink.opacity(0.05), radius: 18, x: 0, y: 10)
    }
}

private struct AnimateGalleryVideoMenu: View {
    let video: AnimateGalleryVideoPresentation
    let downloadVideo: () -> Void
    let renameVideo: () -> Void
    let deleteVideo: () -> Void

    var body: some View {
        Menu {
            if video.canDownload {
                Button(action: downloadVideo) {
                    Label(L10n.string("gallery.video.redownload"), systemImage: "arrow.down.circle")
                }
            }

            Button(action: renameVideo) {
                Label(L10n.string("common.rename"), systemImage: "pencil")
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

    var body: some View {
        NavigationStack {
            VideoPlayer(player: AVPlayer(url: item.url))
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
    }
}
