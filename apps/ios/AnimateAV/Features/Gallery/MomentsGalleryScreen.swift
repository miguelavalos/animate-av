import AVAppShellFoundation
import AVBrandFoundation
import AVFoundation
import AVKit
import SwiftUI

struct MomentsGalleryScreen: View {
    @EnvironmentObject private var viewModel: MomentsGalleryViewModel
    @State private var videoPendingDeletion: MomentsGalleryVideoPresentation?
    @State private var selectedVideo: MomentsGalleryVideoPlayerItem?
    @State private var videoPendingRename: MomentsGalleryVideoPresentation?
    @State private var selectedAssetKind: MomentsGalleryAssetKind = .videos

    var body: some View {
        AVAppShellScrollableScreenScaffold {
            MomentsTheme.shellBackground
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

            Picker(L10n.string("gallery.assetKind.accessibility"), selection: $selectedAssetKind) {
                ForEach(MomentsGalleryAssetKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            switch selectedAssetKind {
            case .videos:
                if viewModel.videos.isEmpty {
                    MomentsGalleryEmptyState(
                        systemImage: "play.square.stack.fill",
                        title: L10n.string("gallery.empty.title"),
                        detail: L10n.string("gallery.empty.detail")
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.videos) { video in
                            MomentsGalleryVideoRow(
                                video: video,
                                openVideo: {
                                    if video.isLocalFileAvailable {
                                        selectedVideo = MomentsGalleryVideoPlayerItem(video: video)
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
                MomentsGalleryEmptyState(
                    systemImage: "photo.stack.fill",
                    title: L10n.string("gallery.images.empty.title"),
                    detail: L10n.string("gallery.images.empty.detail")
                )
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
            MomentsGalleryVideoPlayerSheet(item: item)
        }
        .sheet(item: $videoPendingRename) { video in
            MomentsGalleryRenameSheet(video: video) { title in
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

    private func confirmDeletion() {
        if let videoPendingDeletion {
            viewModel.deleteVideo(videoPendingDeletion)
        }
        videoPendingDeletion = nil
    }
}

private enum MomentsGalleryAssetKind: String, CaseIterable, Identifiable {
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

private struct MomentsGalleryEmptyState: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
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

private struct MomentsGalleryVideoRow: View {
    let video: MomentsGalleryVideoPresentation
    let openVideo: () -> Void
    let downloadVideo: () -> Void
    let renameVideo: () -> Void
    let deleteVideo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: openVideo) {
                ZStack {
                    MomentsGalleryVideoThumbnail(url: video.localFileURL, isAvailable: video.isLocalFileAvailable)
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

                            MomentsGalleryVideoMenu(
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

                                Text(MomentsMomentFormatting.galleryDate(video.record.createdAt))
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

private struct MomentsGalleryVideoMenu: View {
    let video: MomentsGalleryVideoPresentation
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

private struct MomentsGalleryVideoThumbnail: View {
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
        await Task.detached(priority: .utility) {
            let asset = AVURLAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 720, height: 720)

            guard let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }.value
    }
}

private struct MomentsGalleryRenameSheet: View {
    let video: MomentsGalleryVideoPresentation
    let save: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    init(video: MomentsGalleryVideoPresentation, save: @escaping (String) -> Void) {
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

private struct MomentsGalleryVideoPlayerItem: Identifiable {
    let id: String
    let title: String
    let url: URL

    init(video: MomentsGalleryVideoPresentation) {
        id = video.id
        title = video.title
        url = video.localFileURL ?? URL(fileURLWithPath: "/dev/null")
    }
}

private struct MomentsGalleryVideoPlayerSheet: View {
    let item: MomentsGalleryVideoPlayerItem
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
