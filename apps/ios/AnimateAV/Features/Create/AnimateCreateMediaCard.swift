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

    @State private var cropRect = CGRect(x: 0.32, y: 0.18, width: 0.36, height: 0.64)
    @State private var activeDragCropRect = CGRect(x: 0.32, y: 0.18, width: 0.36, height: 0.64)

    private var image: UIImage? {
        UIImage(data: media.data)
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
            cropRect = constrainedCropRect(cropRect)
            activeDragCropRect = cropRect
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
            let imageRect = fittedImageRect(in: proxy.size)
            let absoluteCropRect = absoluteCropRect(in: imageRect)

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

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageRect.width, height: imageRect.height)
                        .position(x: imageRect.midX, y: imageRect.midY)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    cropOverlay(imageRect: imageRect, cropRect: absoluteCropRect)
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

    private var actionBar: some View {
        HStack {
            Spacer(minLength: 0)
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
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func cropOverlay(imageRect: CGRect, cropRect: CGRect) -> some View {
        ZStack {
            Path { path in
                path.addRect(imageRect)
                path.addRect(cropRect)
            }
            .fill(Color.black.opacity(0.48), style: FillStyle(eoFill: true))

            cropGrid(in: cropRect)
                .stroke(.white.opacity(0.55), lineWidth: 0.8)

            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .contentShape(Rectangle())
                .highPriorityGesture(moveCropGesture(in: imageRect))

            Rectangle()
                .stroke(.black.opacity(0.88), lineWidth: 3)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)

            Rectangle()
                .stroke(.white.opacity(0.38), lineWidth: 1)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)

            ForEach(CropHandle.allCases) { handle in
                cropHandle(handle, cropRect: cropRect, imageRect: imageRect)
            }
        }
    }

    private func cropGrid(in rect: CGRect) -> Path {
        Path { path in
            for fraction in [CGFloat(1.0 / 3.0), CGFloat(2.0 / 3.0)] {
                let x = rect.minX + rect.width * fraction
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x, y: rect.maxY))

                let y = rect.minY + rect.height * fraction
                path.move(to: CGPoint(x: rect.minX, y: y))
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
        }
    }

    private func cropHandle(_ handle: CropHandle, cropRect: CGRect, imageRect: CGRect) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.001))
                .frame(width: handle.hitSize(in: cropRect).width, height: handle.hitSize(in: cropRect).height)

            cropHandleShape(handle)
        }
        .position(handle.position(in: cropRect))
        .contentShape(Rectangle())
        .highPriorityGesture(resizeCropGesture(handle: handle, imageRect: imageRect))
    }

    @ViewBuilder
    private func cropHandleShape(_ handle: CropHandle) -> some View {
        if handle.isCorner {
            CropCornerHandle(corner: handle)
                .frame(width: 34, height: 34)
        } else {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(.black.opacity(0.92))
                .frame(width: handle.isHorizontalEdge ? 42 : 4, height: handle.isHorizontalEdge ? 4 : 42)
                .overlay {
                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .stroke(.white.opacity(0.35), lineWidth: 0.8)
                }
        }
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

    private func moveCropGesture(in imageRect: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let dx = value.translation.width / max(imageRect.width, 1)
                let dy = value.translation.height / max(imageRect.height, 1)
                cropRect = constrainedCropRect(
                    CGRect(
                        x: activeDragCropRect.minX + dx,
                        y: activeDragCropRect.minY + dy,
                        width: activeDragCropRect.width,
                        height: activeDragCropRect.height
                    )
                )
            }
            .onEnded { _ in
                activeDragCropRect = cropRect
            }
    }

    private func resizeCropGesture(handle: CropHandle, imageRect: CGRect) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let dx = value.translation.width / max(imageRect.width, 1)
                let dy = value.translation.height / max(imageRect.height, 1)
                cropRect = constrainedCropRect(
                    handle.resized(
                        activeDragCropRect,
                        dx: dx,
                        dy: dy,
                        aspect: normalizedCropAspect()
                    )
                )
            }
            .onEnded { _ in
                activeDragCropRect = cropRect
            }
    }

    private func resetCrop() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            cropRect = defaultCropRect()
            activeDragCropRect = cropRect
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

            let sourceRect = CGRect(
                x: cropRect.minX * image.size.width,
                y: cropRect.minY * image.size.height,
                width: cropRect.width * image.size.width,
                height: cropRect.height * image.size.height
            )
            let scale = max(
                outputSize.width / max(sourceRect.width, 1),
                outputSize.height / max(sourceRect.height, 1)
            )
            let scaledSourceSize = CGSize(width: sourceRect.width * scale, height: sourceRect.height * scale)
            let drawRect = CGRect(
                x: (outputSize.width - scaledSourceSize.width) / 2 - sourceRect.minX * scale,
                y: (outputSize.height - scaledSourceSize.height) / 2 - sourceRect.minY * scale,
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            image.draw(in: drawRect)
        }
        return rendered.jpegData(compressionQuality: 0.92)
    }

    private func fittedImageRect(in size: CGSize) -> CGRect {
        guard let image else {
            return CGRect(origin: .zero, size: size)
        }
        let available = CGSize(width: max(size.width - 4, 1), height: max(size.height - 4, 1))
        let imageAspect = image.size.width / max(image.size.height, 1)
        let availableAspect = available.width / max(available.height, 1)
        let fittedSize: CGSize
        if imageAspect > availableAspect {
            fittedSize = CGSize(width: available.width, height: available.width / imageAspect)
        } else {
            fittedSize = CGSize(width: available.height * imageAspect, height: available.height)
        }
        return CGRect(
            x: (size.width - fittedSize.width) / 2,
            y: (size.height - fittedSize.height) / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private func absoluteCropRect(in imageRect: CGRect) -> CGRect {
        CGRect(
            x: imageRect.minX + cropRect.minX * imageRect.width,
            y: imageRect.minY + cropRect.minY * imageRect.height,
            width: cropRect.width * imageRect.width,
            height: cropRect.height * imageRect.height
        )
    }

    private func defaultCropRect() -> CGRect {
        constrainedCropRect(CGRect(x: 0.32, y: 0.18, width: 0.36, height: 0.64))
    }

    private func constrainedCropRect(_ rect: CGRect) -> CGRect {
        let normalizedAspect = normalizedCropAspect()
        var width = min(max(rect.width, 0.24), 0.90)
        var height = width / normalizedAspect
        if height > 0.90 {
            height = 0.90
            width = height * normalizedAspect
        }
        let x = min(max(rect.midX - width / 2, 0), 1 - width)
        let y = min(max(rect.midY - height / 2, 0), 1 - height)
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func normalizedCropAspect() -> CGFloat {
        let outputAspect = CGFloat(9.0 / 16.0)
        let imageAspect = image.map { $0.size.width / max($0.size.height, 1) } ?? 1
        return outputAspect / max(imageAspect, 0.001)
    }
}

private enum CropHandle: CaseIterable, Identifiable {
    case top
    case bottom
    case leading
    case trailing
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    var id: String { String(describing: self) }

    var isCorner: Bool {
        switch self {
        case .topLeading, .topTrailing, .bottomLeading, .bottomTrailing:
            true
        case .top, .bottom, .leading, .trailing:
            false
        }
    }

    var isHorizontalEdge: Bool {
        self == .top || self == .bottom
    }

    func position(in rect: CGRect) -> CGPoint {
        switch self {
        case .top:
            CGPoint(x: rect.midX, y: rect.minY)
        case .bottom:
            CGPoint(x: rect.midX, y: rect.maxY)
        case .leading:
            CGPoint(x: rect.minX, y: rect.midY)
        case .trailing:
            CGPoint(x: rect.maxX, y: rect.midY)
        case .topLeading:
            CGPoint(x: rect.minX, y: rect.minY)
        case .topTrailing:
            CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeading:
            CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomTrailing:
            CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    func hitSize(in rect: CGRect) -> CGSize {
        switch self {
        case .top, .bottom:
            CGSize(width: max(rect.width - 72, 44), height: 64)
        case .leading, .trailing:
            CGSize(width: 64, height: max(rect.height - 72, 44))
        case .topLeading, .topTrailing, .bottomLeading, .bottomTrailing:
            CGSize(width: 72, height: 72)
        }
    }

    func resized(_ rect: CGRect, dx: CGFloat, dy: CGFloat, aspect: CGFloat) -> CGRect {
        let signedDelta: CGFloat
        switch self {
        case .top:
            signedDelta = -dy * aspect
        case .bottom:
            signedDelta = dy * aspect
        case .leading:
            signedDelta = -dx
        case .trailing:
            signedDelta = dx
        case .topLeading:
            signedDelta = min(-dx, -dy * aspect)
        case .topTrailing:
            signedDelta = min(dx, -dy * aspect)
        case .bottomLeading:
            signedDelta = min(-dx, dy * aspect)
        case .bottomTrailing:
            signedDelta = min(dx, dy * aspect)
        }

        let width = rect.width + signedDelta
        let height = width / aspect

        switch self {
        case .top:
            return CGRect(x: rect.midX - width / 2, y: rect.maxY - height, width: width, height: height)
        case .bottom:
            return CGRect(x: rect.midX - width / 2, y: rect.minY, width: width, height: height)
        case .leading:
            return CGRect(x: rect.maxX - width, y: rect.midY - height / 2, width: width, height: height)
        case .trailing:
            return CGRect(x: rect.minX, y: rect.midY - height / 2, width: width, height: height)
        case .topLeading:
            return CGRect(x: rect.maxX - width, y: rect.maxY - height, width: width, height: height)
        case .topTrailing:
            return CGRect(x: rect.minX, y: rect.maxY - height, width: width, height: height)
        case .bottomLeading:
            return CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: height)
        case .bottomTrailing:
            return CGRect(x: rect.minX, y: rect.minY, width: width, height: height)
        }
    }
}

private struct CropCornerHandle: View {
    let corner: CropHandle

    var body: some View {
        Path { path in
            let length: CGFloat = 18
            switch corner {
            case .topLeading:
                path.move(to: CGPoint(x: 0, y: length))
                path.addLine(to: .zero)
                path.addLine(to: CGPoint(x: length, y: 0))
            case .topTrailing:
                path.move(to: CGPoint(x: 34 - length, y: 0))
                path.addLine(to: CGPoint(x: 34, y: 0))
                path.addLine(to: CGPoint(x: 34, y: length))
            case .bottomLeading:
                path.move(to: CGPoint(x: 0, y: 34 - length))
                path.addLine(to: CGPoint(x: 0, y: 34))
                path.addLine(to: CGPoint(x: length, y: 34))
            case .bottomTrailing:
                path.move(to: CGPoint(x: 34 - length, y: 34))
                path.addLine(to: CGPoint(x: 34, y: 34))
                path.addLine(to: CGPoint(x: 34, y: 34 - length))
            case .top, .bottom, .leading, .trailing:
                break
            }
        }
        .stroke(.black.opacity(0.92), style: StrokeStyle(lineWidth: 4, lineCap: .square, lineJoin: .miter))
        .overlay {
            Path { path in
                let length: CGFloat = 18
                switch corner {
                case .topLeading:
                    path.move(to: CGPoint(x: 0, y: length))
                    path.addLine(to: .zero)
                    path.addLine(to: CGPoint(x: length, y: 0))
                case .topTrailing:
                    path.move(to: CGPoint(x: 34 - length, y: 0))
                    path.addLine(to: CGPoint(x: 34, y: 0))
                    path.addLine(to: CGPoint(x: 34, y: length))
                case .bottomLeading:
                    path.move(to: CGPoint(x: 0, y: 34 - length))
                    path.addLine(to: CGPoint(x: 0, y: 34))
                    path.addLine(to: CGPoint(x: length, y: 34))
                case .bottomTrailing:
                    path.move(to: CGPoint(x: 34 - length, y: 34))
                    path.addLine(to: CGPoint(x: 34, y: 34))
                    path.addLine(to: CGPoint(x: 34, y: 34 - length))
                case .top, .bottom, .leading, .trailing:
                    break
                }
            }
            .stroke(.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, lineCap: .square, lineJoin: .miter))
        }
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
