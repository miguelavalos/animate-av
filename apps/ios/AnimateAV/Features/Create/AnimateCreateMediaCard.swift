import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI
import UIKit

struct AnimateCreateMediaCard: View {
    let presentation: AnimateCreateMediaPresentation
    let choosePhotos: () -> Void

    var body: some View {
        AVAppShellCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 10) {
                        Text(L10n.string("create.media.title"))
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)

                        Spacer(minLength: 0)
                    }

                    HStack(alignment: .center, spacing: 16) {
                        mediaVisual

                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.string("create.media.emptySummary"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(AVBrandColor.textSecondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }

                    Text(L10n.string("create.media.startDetail"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 8) {
                        AnimateCreateMediaChoiceAction(
                            title: L10n.string("create.media.choose"),
                            systemImage: "photo.badge.plus",
                            isPrimary: true,
                            isEnabled: !presentation.summary.isImporting,
                            action: choosePhotos
                        )
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 232, alignment: .topLeading)
            }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var mediaVisual: some View {
        ZStack {
            AVBrandColor.accent.opacity(0.08)
            Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(AVBrandColor.accent)
        }
        .frame(width: 92, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AnimateCreateMediaChoiceAction: View {
    let title: String
    let systemImage: String
    let isPrimary: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            Label(title, systemImage: systemImage)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(backgroundColor, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(borderColor, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(title)
    }

    private var foregroundColor: Color {
        isEnabled ? AVBrandColor.textPrimary : AVBrandColor.textSecondary.opacity(0.55)
    }

    private var backgroundColor: Color {
        if !isEnabled {
            return AVBrandColor.mutedSurface.opacity(0.7)
        }

        return isPrimary ? AVBrandColor.accent.opacity(0.08) : AVBrandColor.mutedSurface.opacity(0.58)
    }

    private var borderColor: Color {
        if isPrimary {
            return isEnabled ? AVBrandColor.accent.opacity(0.22) : AVBrandColor.borderSubtle.opacity(0.45)
        }

        return AVBrandColor.borderSubtle.opacity(isEnabled ? 0.38 : 0.22)
    }
}

struct AnimateCreateMediaManagerSheet: View {
    let selectedMedia: [AnimateSelectedMedia]
    let syncedMediaAssets: [AnimateMediaAsset]
    let canAddMedia: Bool
    let isImporting: Bool
    let importProgress: AnimateMediaImportProgress?
    let removeMedia: (AnimateSelectedMedia) -> Void
    let updateMediaPhotoData: (AnimateSelectedMedia, Data) -> Void
    let restoreLocalMediaForEditing: () -> Void
    let discardVideoCreation: () -> Void
    let chooseManually: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workingMedia: [AnimateSelectedMedia] = []
    @State private var zoomedMedia: AnimateSelectedMedia?
    @State private var adjustingMedia: AnimateSelectedMedia?
    @State private var hasPresentedInitialAdjuster = false

    private let columns = [
        GridItem(.adaptive(minimum: 106, maximum: 106), spacing: 16)
    ]

    var body: some View {
        gridView
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            restoreLocalMediaForEditing()
            workingMedia = selectedMedia
            presentInitialAdjusterIfNeeded(selectedMedia)
        }
        .onChange(of: selectedMedia) { _, newMedia in
            workingMedia = newMedia
            presentInitialAdjusterIfNeeded(newMedia)
        }
    }

    private var gridView: some View {
        VStack(spacing: 0) {
            editHeader
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AnimateCreateEditorAviPanel(
                        selectedCount: displayCount,
                        canAddMedia: canAddMedia,
                        isImporting: isImporting,
                        addMedia: chooseManually
                    )

                    if isImporting {
                        AnimateCreateMediaImportProgressCard(
                            selectedCount: workingMedia.count,
                            progress: importProgress
                        )
                    }

                    if workingMedia.isEmpty, syncedMediaAssets.isEmpty {
                        AnimateCreateMediaEmptyState(
                            canAddMedia: canAddMedia,
                            isImporting: isImporting,
                            addMedia: chooseManually
                        )
                    } else {
                        if !workingMedia.isEmpty {
                            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                                ForEach(Array(workingMedia.enumerated()), id: \.element.id) { index, media in
                                    AnimateCreateManageableMediaTile(
                                        media: media,
                                        index: index,
                                        isImporting: isImporting,
                                        zoom: {
                                            zoomedMedia = media
                                        },
                                        adjust: {
                                            adjustingMedia = media
                                        },
                                        remove: {
                                            removeMedia(media)
                                        }
                                    )
                                }
                            }
                        }

                        if workingMedia.isEmpty, !syncedMediaAssets.isEmpty {
                            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                                ForEach(Array(syncedMediaAssets.enumerated()), id: \.element.id) { index, media in
                                    AnimateCreateSyncedMediaEditorTile(media: media, index: index)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .safeAreaPadding(.bottom, 96)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .fullScreenCover(item: $zoomedMedia) { media in
            AnimateCreateMediaZoomView(media: media) {
                zoomedMedia = nil
            }
        }
        .fullScreenCover(item: $adjustingMedia) { media in
            AnimateCreatePhotoAdjustView(
                media: media,
                save: { adjustedData in
                    updateMediaPhotoData(media, adjustedData)
                    adjustingMedia = nil
                    hasPresentedInitialAdjuster = true
                },
                continueWithOriginal: {
                    adjustingMedia = nil
                    hasPresentedInitialAdjuster = true
                },
                changePhoto: {
                    removeMedia(media)
                    adjustingMedia = nil
                    hasPresentedInitialAdjuster = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        chooseManually()
                    }
                },
                cancel: {
                    adjustingMedia = nil
                    hasPresentedInitialAdjuster = true
                }
            )
        }
    }

    private var editHeader: some View {
        AnimateCreateEditorPageHeader(
            title: L10n.string("create.media.editTitle"),
            dismiss: { dismiss() }
        )
    }

    private var displayCount: Int {
        workingMedia.isEmpty ? syncedMediaAssets.count : workingMedia.count
    }

    private func presentInitialAdjusterIfNeeded(_ media: [AnimateSelectedMedia]) {
        guard !hasPresentedInitialAdjuster,
              let firstPhoto = media.first(where: { $0.kind == "photo" || $0.kind == "image" }),
              media.count == 1 else { return }
        hasPresentedInitialAdjuster = true
        Task { @MainActor in
            await Task.yield()
            adjustingMedia = firstPhoto
        }
    }
}

private struct AnimateCreateMediaEmptyState: View {
    let canAddMedia: Bool
    let isImporting: Bool
    let addMedia: () -> Void

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AVBrandColor.accent.opacity(0.08))
                        .frame(width: 104, height: 82)
                        .rotationEffect(.degrees(-4))

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.white)
                        .frame(width: 104, height: 82)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AVBrandColor.borderSubtle.opacity(0.7), lineWidth: 1)
                        }
                        .shadow(color: AVBrandColor.ink.opacity(0.07), radius: 8, x: 0, y: 4)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AVBrandColor.accent)
                }
                .padding(.top, 4)
                .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text(L10n.string("video.progress.noMedia"))
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(L10n.string("create.media.emptyStart"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: addMedia) {
                    Label(L10n.string("create.media.add"), systemImage: "plus")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .fill(AVBrandColor.accent.opacity(0.08))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 21, style: .continuous)
                                .stroke(AVBrandColor.accent.opacity(0.24), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(!canAddMedia || isImporting)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}

private struct AnimateCreateSyncedMediaEditorTile: View {
    let media: AnimateMediaAsset
    let index: Int

    var body: some View {
        VStack(spacing: 6) {
            AnimateCreateSyncedMediaThumbnailImage(media: media)
                .frame(width: 96, height: mediaFrame.height)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

            HStack {
                Text("\(index + 1)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary.opacity(0.72))
                Spacer(minLength: 0)
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AVBrandColor.textSecondary.opacity(0.55))
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 106, height: 116, alignment: .top)
        .padding(.top, 5)
        .padding(.horizontal, 5)
        .padding(.bottom, 7)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.46), lineWidth: 1)
        }
        .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 5, x: 0, y: 2)
        .rotationEffect(.degrees(rotationDegrees))
        .accessibilityLabel(L10n.string("create.mediaCard.mediaAccessibility", localizedKind, index + 1))
    }

    private var mediaFrame: CGSize {
        media.kind == "video"
            ? CGSize(width: 96, height: 54)
            : CGSize(width: 96, height: 86)
    }

    private var localizedKind: String {
        media.kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo")
    }

    private var cardBackground: Color {
        media.kind == "video" ? AVBrandColor.ink.opacity(0.08) : .white
    }

    private var rotationDegrees: Double {
        [-1.0, 0.6, -0.4, 0.9][index % 4]
    }
}

private struct AnimateCreateMediaImportProgressCard: View {
    let selectedCount: Int
    let progress: AnimateMediaImportProgress?

    var body: some View {
        AVAppShellCard {
            HStack(spacing: 12) {
                progressView
                    .frame(width: 44, height: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("create.mediaCard.import.title"))
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(progressMessage)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityLabel(L10n.string("create.mediaCard.import.accessibility", progressMessage))
    }

    @ViewBuilder
    private var progressView: some View {
        if let fractionCompleted = progress?.fractionCompleted {
            ZStack {
                Circle()
                    .stroke(AVBrandColor.accent.opacity(0.16), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: fractionCompleted)
                    .stroke(AVBrandColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(progress?.title.split(separator: " ").first.map(String.init) ?? "")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
            }
        } else {
            ProgressView()
                .controlSize(.regular)
                .tint(AVBrandColor.accent)
        }
    }

    private var progressMessage: String {
        if let progress, progress.totalCount > 0 {
            return L10n.string(
                "create.mediaCard.import.progress",
                progress.title,
                progress.totalCount == 1
                    ? L10n.string("create.mediaCard.item.singular")
                    : L10n.string("create.mediaCard.item.plural")
            )
        }
        if selectedCount == 0 {
            return L10n.string("create.mediaCard.import.readingSelected")
        }
        return L10n.string(
            "create.mediaCard.import.keepingCurrent",
            selectedCount,
            selectedCount == 1
                ? L10n.string("create.mediaCard.item.singular")
                : L10n.string("create.mediaCard.item.plural")
        )
    }
}

private struct AnimateCreateManageableMediaTile: View {
    let media: AnimateSelectedMedia
    let index: Int
    let isImporting: Bool
    let zoom: () -> Void
    let adjust: () -> Void
    let remove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: zoom) {
                VStack(spacing: 6) {
                    ZStack(alignment: .bottomLeading) {
                        thumbnail
                    }
                    .frame(width: 96, height: mediaFrame.height)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                    HStack {
                        Text("\(index + 1)")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary.opacity(0.72))
                        Spacer(minLength: 0)
                        Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AVBrandColor.textSecondary.opacity(0.55))
                    }
                    .padding(.horizontal, 4)
                }
                .frame(width: 106, height: 116, alignment: .top)
                .padding(.top, 5)
                .padding(.horizontal, 5)
                .padding(.bottom, 7)
                .background(cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AVBrandColor.borderSubtle.opacity(0.46), lineWidth: 1)
                }
                .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 5, x: 0, y: 2)
                .rotationEffect(.degrees(rotationDegrees))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isImporting)

            Button(role: .destructive, action: remove) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(.black.opacity(0.62), in: Circle())
            }
            .padding(1)
            .disabled(isImporting)
            .opacity(isImporting ? 0.45 : 1)
            .accessibilityLabel(L10n.string("create.mediaCard.removeMedia"))

            if media.kind == "photo" || media.kind == "image" {
                Button(action: adjust) {
                    Image(systemName: "crop")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .frame(width: 24, height: 24)
                        .background(.white.opacity(0.92), in: Circle())
                }
                .padding(.top, 28)
                .padding(.trailing, 1)
                .disabled(isImporting)
                .opacity(isImporting ? 0.45 : 1)
                .accessibilityLabel(L10n.string("create.mediaCard.adjustFrame"))
            }
        }
        .accessibilityLabel(L10n.string("create.mediaCard.mediaAccessibility", localizedKind, index + 1))
    }

    private var mediaAspectRatio: CGFloat {
        media.kind == "video" ? 16.0 / 9.0 : 1.0
    }

    private var localizedKind: String {
        media.kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo")
    }

    private var mediaFrame: CGSize {
        media.kind == "video"
            ? CGSize(width: 96, height: 54)
            : CGSize(width: 96, height: 86)
    }

    private var cardBackground: Color {
        media.kind == "video" ? AVBrandColor.ink.opacity(0.08) : .white
    }

    private var rotationDegrees: Double {
        [-1.0, 0.6, -0.4, 0.9][index % 4]
    }

    @ViewBuilder
    private var thumbnail: some View {
        if (media.kind == "photo" || media.kind == "image"), let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: mediaFrame.width, height: mediaFrame.height)
                .clipped()
        } else {
            ZStack {
                AVBrandColor.ink.opacity(0.12)
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
            .frame(width: mediaFrame.width, height: mediaFrame.height)
        }
    }
}

struct AnimateCreatePhotoAdjustView: View {
    let media: AnimateSelectedMedia
    let save: (Data) -> Void
    let continueWithOriginal: () -> Void
    let changePhoto: () -> Void
    let cancel: () -> Void

    @State private var frameScale: CGFloat = 1
    @State private var activeFrameScale: CGFloat = 1
    @State private var imageOffset: CGSize = .zero
    @State private var activeImageOffset: CGSize = .zero
    @State private var editorFrameSize = CGSize(width: 9, height: 16)

    private var image: UIImage? {
        UIImage(data: media.sourceImageDataForEditing)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                header

                cropEditor

                actionBar
            }
            .padding(.horizontal, 14)
            .padding(.top, 44)
            .padding(.bottom, 16)
        }
        .onAppear {
            resetFrame()
        }
    }

    private var header: some View {
        HStack {
            Button(action: cancel) {
                Text(L10n.string("common.cancel"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 68, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(L10n.string("create.mediaAdjust.title"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            Button(action: saveCrop) {
                Text(L10n.string("common.done"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AVBrandColor.accent)
                    .frame(minWidth: 68, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
    }

    private var cropEditor: some View {
        GeometryReader { proxy in
            let frameSize = fixedFrameSize(in: proxy.size)
            let frameRect = CGRect(
                x: (proxy.size.width - frameSize.width) / 2,
                y: (proxy.size.height - frameSize.height) / 2,
                width: frameSize.width,
                height: frameSize.height
            )

            ZStack {
                Color.black

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: 18)
                        .opacity(0.18)
                        .clipped()

                    framedImageEditor(image: image, frameSize: frameSize)
                        .frame(width: frameRect.width, height: frameRect.height)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(frameOverlay)
                        .position(x: frameRect.midX, y: frameRect.midY)
                        .contentShape(Rectangle())
                        .gesture(dragFrameGesture(frameSize: frameSize, image: image))
                        .simultaneousGesture(pinchFrameGesture(frameSize: frameSize, image: image))
                        .onTapGesture(count: 2) {
                            toggleFrameZoom(frameSize: frameSize, image: image)
                        }
                        .onAppear {
                            editorFrameSize = frameSize
                            clampFrameState(frameSize: frameSize, image: image)
                        }
                        .onChange(of: proxy.size) { _, _ in
                            editorFrameSize = frameSize
                            clampFrameState(frameSize: frameSize, image: image)
                        }

                    frameInstruction
                        .position(x: frameRect.midX, y: min(frameRect.maxY + 34, proxy.size.height - 22))
                } else {
                    fallbackImage
                        .frame(width: proxy.size.width, height: proxy.size.height)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    private func framedImageEditor(image: UIImage, frameSize: CGSize) -> some View {
        let displaySize = imageDisplaySize(for: image, frameSize: frameSize)
        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: displaySize.width, height: displaySize.height)
            .offset(imageOffset)
    }

    private var frameOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.black.opacity(0.88), lineWidth: 4)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1.4)
            frameGrid
                .stroke(.white.opacity(0.42), lineWidth: 0.8)
        }
    }

    private var frameGrid: Path {
        Path { path in
            for fraction in [CGFloat(1.0 / 3.0), CGFloat(2.0 / 3.0)] {
                path.move(to: CGPoint(x: editorFrameSize.width * fraction, y: 0))
                path.addLine(to: CGPoint(x: editorFrameSize.width * fraction, y: editorFrameSize.height))
                path.move(to: CGPoint(x: 0, y: editorFrameSize.height * fraction))
                path.addLine(to: CGPoint(x: editorFrameSize.width, y: editorFrameSize.height * fraction))
            }
        }
    }

    private var frameInstruction: some View {
        Text(L10n.string("create.mediaAdjust.frameDetail"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.78))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.black.opacity(0.42), in: Capsule())
    }

    private var actionBar: some View {
        VStack(spacing: 12) {
            if let image {
                zoomControls(image: image)
            }

            Button(action: resetCrop) {
                VStack(spacing: 5) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .semibold))
                    Text(L10n.string("create.mediaAdjust.reset"))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(width: 88, height: 52)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private func zoomControls(image: UIImage) -> some View {
        let minimumScale = minimumFrameScale(for: image, frameSize: editorFrameSize)
        return HStack(spacing: 12) {
            Button {
                adjustZoom(by: -0.25, image: image)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel(L10n.string("create.mediaAdjust.zoomOut"))

            Slider(
                value: Binding(
                    get: { Double(frameScale) },
                    set: { setZoom(CGFloat($0), image: image) }
                ),
                in: minimumScale...4
            )
            .tint(AVBrandColor.accent)
            .accessibilityLabel(L10n.string("create.mediaAdjust.zoom"))
            .accessibilityValue("\(Int(frameScale * 100))%")

            Button {
                fitFrame(image: image)
            } label: {
                Text(L10n.string("create.mediaAdjust.fit"))
                    .font(.caption.weight(.black))
                    .frame(width: 42, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel(L10n.string("create.mediaAdjust.fit"))

            Button {
                adjustZoom(by: 0.25, image: image)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .accessibilityLabel(L10n.string("create.mediaAdjust.zoomIn"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.white.opacity(0.10), in: Capsule())
        .padding(.horizontal, 8)
    }

    private var fallbackImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.12))
            Image(systemName: "photo.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private func resetCrop() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            resetFrame()
        }
    }

    private func saveCrop() {
        guard let image,
              let data = renderCrop(from: image) else {
            continueWithOriginal()
            return
        }
        save(data)
    }

    private func renderCrop(from image: UIImage) -> Data? {
        let outputSize = CGSize(width: 1080, height: 1920)
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let rendered = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))

            let backgroundScale = max(
                outputSize.width / max(image.size.width, 1),
                outputSize.height / max(image.size.height, 1)
            )
            let backgroundSize = CGSize(width: image.size.width * backgroundScale, height: image.size.height * backgroundScale)
            let backgroundRect = CGRect(
                x: (outputSize.width - backgroundSize.width) / 2,
                y: (outputSize.height - backgroundSize.height) / 2,
                width: backgroundSize.width,
                height: backgroundSize.height
            )
            image.draw(in: backgroundRect, blendMode: .normal, alpha: 0.32)
            UIColor.black.withAlphaComponent(0.36).setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))

            let baseScale = max(
                outputSize.width / max(image.size.width, 1),
                outputSize.height / max(image.size.height, 1)
            )
            let drawScale = baseScale * frameScale
            let scaledSourceSize = CGSize(width: image.size.width * drawScale, height: image.size.height * drawScale)
            let outputOffset = CGSize(
                width: imageOffset.width * outputSize.width / max(editorFrameSize.width, 1),
                height: imageOffset.height * outputSize.height / max(editorFrameSize.height, 1)
            )
            let drawRect = CGRect(
                x: (outputSize.width - scaledSourceSize.width) / 2 + outputOffset.width,
                y: (outputSize.height - scaledSourceSize.height) / 2 + outputOffset.height,
                width: scaledSourceSize.width,
                height: scaledSourceSize.height
            )
            image.draw(in: drawRect)
        }
        return rendered.jpegData(compressionQuality: 0.92)
    }

    private func fixedFrameSize(in size: CGSize) -> CGSize {
        let available = CGSize(width: max(size.width - 12, 1), height: max(size.height - 72, 1))
        let aspect = CGFloat(9.0 / 16.0)
        var width = min(available.width, available.height * aspect)
        var height = width / aspect
        if height > available.height {
            height = available.height
            width = height * aspect
        }
        return CGSize(width: width, height: height)
    }

    private func imageDisplaySize(for image: UIImage, frameSize: CGSize) -> CGSize {
        let baseScale = max(
            frameSize.width / max(image.size.width, 1),
            frameSize.height / max(image.size.height, 1)
        )
        let scale = baseScale * frameScale
        return CGSize(width: image.size.width * scale, height: image.size.height * scale)
    }

    private func minimumFrameScale(for image: UIImage, frameSize: CGSize) -> CGFloat {
        let fillScale = max(
            frameSize.width / max(image.size.width, 1),
            frameSize.height / max(image.size.height, 1)
        )
        let fitScale = min(
            frameSize.width / max(image.size.width, 1),
            frameSize.height / max(image.size.height, 1)
        )
        return max(min(fitScale / max(fillScale, 0.0001), 1), 0.2)
    }

    private func constrainedOffset(_ offset: CGSize, frameSize: CGSize, image: UIImage, scale: CGFloat) -> CGSize {
        let baseScale = max(
            frameSize.width / max(image.size.width, 1),
            frameSize.height / max(image.size.height, 1)
        )
        let displaySize = CGSize(width: image.size.width * baseScale * scale, height: image.size.height * baseScale * scale)
        let maxX = max((displaySize.width - frameSize.width) / 2, 0)
        let maxY = max((displaySize.height - frameSize.height) / 2, 0)
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }

    private func dragFrameGesture(frameSize: CGSize, image: UIImage) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                imageOffset = constrainedOffset(
                    CGSize(
                        width: activeImageOffset.width + value.translation.width,
                        height: activeImageOffset.height + value.translation.height
                    ),
                    frameSize: frameSize,
                    image: image,
                    scale: frameScale
                )
            }
            .onEnded { _ in
                activeImageOffset = imageOffset
            }
    }

    private func pinchFrameGesture(frameSize: CGSize, image: UIImage) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let minimumScale = minimumFrameScale(for: image, frameSize: frameSize)
                frameScale = min(max(activeFrameScale * value, minimumScale), 4)
                imageOffset = constrainedOffset(imageOffset, frameSize: frameSize, image: image, scale: frameScale)
            }
            .onEnded { _ in
                let minimumScale = minimumFrameScale(for: image, frameSize: frameSize)
                frameScale = min(max(frameScale, minimumScale), 4)
                imageOffset = constrainedOffset(imageOffset, frameSize: frameSize, image: image, scale: frameScale)
                activeFrameScale = frameScale
                activeImageOffset = imageOffset
            }
    }

    private func toggleFrameZoom(frameSize: CGSize, image: UIImage) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            if frameScale > 1.01 {
                resetFrame()
            } else {
                frameScale = 2
                activeFrameScale = 2
                imageOffset = constrainedOffset(imageOffset, frameSize: frameSize, image: image, scale: frameScale)
                activeImageOffset = imageOffset
            }
        }
    }

    private func adjustZoom(by delta: CGFloat, image: UIImage) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.88)) {
            setZoom(frameScale + delta, image: image)
        }
    }

    private func fitFrame(image: UIImage) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
            setZoom(minimumFrameScale(for: image, frameSize: editorFrameSize), image: image)
        }
    }

    private func setZoom(_ scale: CGFloat, image: UIImage) {
        let minimumScale = minimumFrameScale(for: image, frameSize: editorFrameSize)
        frameScale = min(max(scale, minimumScale), 4)
        imageOffset = constrainedOffset(imageOffset, frameSize: editorFrameSize, image: image, scale: frameScale)
        activeFrameScale = frameScale
        activeImageOffset = imageOffset
    }

    private func clampFrameState(frameSize: CGSize, image: UIImage) {
        let minimumScale = minimumFrameScale(for: image, frameSize: frameSize)
        frameScale = min(max(frameScale, minimumScale), 4)
        activeFrameScale = frameScale
        imageOffset = constrainedOffset(imageOffset, frameSize: frameSize, image: image, scale: frameScale)
        activeImageOffset = imageOffset
    }

    private func resetFrame() {
        frameScale = 1
        activeFrameScale = 1
        imageOffset = .zero
        activeImageOffset = .zero
    }
}

private struct AnimateCreateMediaZoomView: View {
    let media: AnimateSelectedMedia
    let dismiss: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            zoomContent
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(pinchGesture)
                .simultaneousGesture(dragGesture)
                .onTapGesture(count: 2, perform: toggleZoom)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.18), in: Circle())
                    .contentShape(Circle())
            }
            .padding(.top, 18)
            .padding(.trailing, 18)
            .accessibilityLabel(L10n.string("create.mediaCard.closePreview"))
        }
    }

    @ViewBuilder
    private var zoomContent: some View {
        if (media.kind == "photo" || media.kind == "image"), let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            VStack(spacing: 12) {
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 44, weight: .semibold))
                Text(media.kind == "video" ? L10n.string("create.mediaCard.videoPreview") : L10n.string("create.mediaCard.mediaPreview"))
                    .font(.system(size: 17, weight: .black))
            }
            .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), 4)
                if scale <= 1.01 {
                    offset = .zero
                    lastOffset = .zero
                }
            }
            .onEnded { _ in
                if scale <= 1.01 {
                    resetZoom()
                } else {
                    lastScale = scale
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1 else { return }
                lastOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            if scale > 1 {
                resetZoom()
            } else {
                scale = 2
                lastScale = 2
            }
        }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

private struct AnimateCreateEditorAviPanel: View {
    let selectedCount: Int
    let canAddMedia: Bool
    let isImporting: Bool
    let addMedia: () -> Void

    var body: some View {
        AVAppShellCard {
            HStack(spacing: 12) {
                Image("AviFullBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .padding(4)
                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(panelTitle)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(panelMessage)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Menu {
                    Section(L10n.string("create.mediaCard.menu.yourEdits")) {
                        if canAddMedia {
                            Button(action: addMedia) {
                            Label(L10n.string("create.media.add"), systemImage: "photo.badge.plus")
                            }
                            .disabled(isImporting)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .frame(width: 38, height: 38)
                        .background(AVBrandColor.neutral100, in: Circle())
                }
                .accessibilityLabel(L10n.string("create.media.actions"))
            }
        }
    }

    private var panelTitle: String {
        if selectedCount == 0 {
            return L10n.string("create.media.startTitle")
        }
        return L10n.string("create.media.selectedCount", selectedCount)
    }

    private var panelMessage: String {
        if selectedCount == 0 {
            return L10n.string("create.media.panelDetail")
        }
        return L10n.string("create.mediaCard.selectionMessage")
    }
}

private struct AnimateCreateMediaReorderRow: View {
    let media: AnimateSelectedMedia
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("create.media.momentIndex", index + 1))
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(1)
            }
        }
        .listRowBackground(Color.clear)
    }

    private var detailText: String {
        var parts: [String] = []

        if let capturedAt = media.capturedAt {
            parts.append(capturedAt.formatted(date: .abbreviated, time: .shortened))
        } else {
            parts.append(L10n.string("create.mediaCard.noDate"))
        }

        parts.append(media.kind == "video" ? L10n.string("create.mediaCard.kind.video") : L10n.string("create.mediaCard.kind.photo"))
        parts.append(media.displaySize)

        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var thumbnail: some View {
        if (media.kind == "photo" || media.kind == "image"), let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                AVBrandColor.neutral100
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
        }
    }
}

private struct AnimateCreateSyncedMediaSection: View {
    let mediaAssets: [AnimateMediaAsset]

    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 8)
    ]

    @ViewBuilder
    var body: some View {
        if !mediaAssets.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                AVAppShellSectionHeader(title: L10n.string("create.media.added"))

                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(Array(mediaAssets.enumerated()), id: \.element.id) { index, media in
                        AnimateCreateSyncedMediaThumbnailTile(media: media, index: index)
                    }
                }
            }
        }
    }
}

struct AnimateCreateSoftActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AVBrandColor.textPrimary : AVBrandColor.textSecondary.opacity(0.55))
            .padding(.horizontal, AVBrandSpacing.md)
            .background(background(configuration: configuration), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        isEnabled ? AVBrandColor.accent.opacity(0.22) : AVBrandColor.borderSubtle.opacity(0.45),
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private func background(configuration: Configuration) -> Color {
        if !isEnabled {
            return AVBrandColor.mutedSurface.opacity(0.7)
        }

        return configuration.isPressed ? AVBrandColor.accent.opacity(0.14) : AVBrandColor.accent.opacity(0.08)
    }
}

struct AnimateCreateFixedFooterAction: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .font(.system(size: 15, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(AnimateCreateSoftActionButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AVBrandColor.glassStroke.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: AVBrandColor.glassShadow.opacity(0.7), radius: 12, y: 3)
    }
}

struct AnimateCreateSubtleInlineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AVBrandColor.accent : AVBrandColor.textSecondary.opacity(0.55))
            .padding(.horizontal, AVBrandSpacing.sm)
            .padding(.vertical, 6)
            .background(
                isEnabled ? AVBrandColor.accent.opacity(configuration.isPressed ? 0.14 : 0.08) : AVBrandColor.mutedSurface.opacity(0.7),
                in: Capsule()
            )
    }
}

struct AnimateCreateNeutralInlineButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AVBrandColor.textSecondary : AVBrandColor.textSecondary.opacity(0.45))
            .padding(.horizontal, AVBrandSpacing.sm)
            .padding(.vertical, 6)
            .background(
                isEnabled ? AVBrandColor.mutedSurface.opacity(configuration.isPressed ? 0.82 : 0.58) : AVBrandColor.mutedSurface.opacity(0.42),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(AVBrandColor.borderSubtle.opacity(isEnabled ? 0.38 : 0.22), lineWidth: 1)
            }
    }
}

struct AnimateCreateEditorPageHeader: View {
    let title: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: dismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.92), in: Circle())
                    .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 10, x: 0, y: 4)
            }
            .accessibilityLabel(L10n.string("create.mediaCard.backToDashboard"))

            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .frame(maxWidth: .infinity)

            Color.clear
                .frame(width: 44, height: 44)
        }
    }
}

private struct AnimateCreateToolbarPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AVBrandColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(configuration.isPressed ? 0.78 : 0.92), in: Capsule())
            .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
