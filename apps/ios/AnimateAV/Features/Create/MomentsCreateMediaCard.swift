import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI
import UIKit

struct MomentsCreateMediaCard: View {
    let presentation: MomentsCreateMediaPresentation
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
                        MomentsCreateMediaChoiceAction(
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

private struct MomentsCreateMediaChoiceAction: View {
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

struct MomentsCreateMediaManagerSheet: View {
    let selectedMedia: [MomentsSelectedMedia]
    let syncedMediaAssets: [MomentMediaAsset]
    let canAddMedia: Bool
    let isImporting: Bool
    let importProgress: MomentsMediaImportProgress?
    let removeMedia: (MomentsSelectedMedia) -> Void
    let restoreLocalMediaForEditing: () -> Void
    let chooseManually: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workingMedia: [MomentsSelectedMedia] = []
    @State private var zoomedMedia: MomentsSelectedMedia?

    private let columns = [
        GridItem(.adaptive(minimum: 106, maximum: 106), spacing: 16)
    ]

    var body: some View {
        gridView
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            restoreLocalMediaForEditing()
            workingMedia = selectedMedia
        }
        .onChange(of: selectedMedia) { _, newMedia in
            workingMedia = newMedia
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
                    MomentsCreateEditorAviPanel(
                        selectedCount: displayCount,
                        canAddMedia: canAddMedia,
                        isImporting: isImporting,
                        addMedia: chooseManually
                    )

                    if isImporting {
                        MomentsCreateMediaImportProgressCard(
                            selectedCount: workingMedia.count,
                            progress: importProgress
                        )
                    }

                    if workingMedia.isEmpty, syncedMediaAssets.isEmpty {
                        MomentsCreateMediaEmptyState(
                            canAddMedia: canAddMedia,
                            isImporting: isImporting,
                            addMedia: chooseManually
                        )
                    } else {
                        if !workingMedia.isEmpty {
                            LazyVGrid(columns: columns, alignment: .center, spacing: 16) {
                                ForEach(Array(workingMedia.enumerated()), id: \.element.id) { index, media in
                                    MomentsCreateManageableMediaTile(
                                        media: media,
                                        index: index,
                                        isImporting: isImporting,
                                        zoom: {
                                            zoomedMedia = media
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
                                    MomentsCreateSyncedMediaEditorTile(media: media, index: index)
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
            MomentsCreateMediaZoomView(media: media) {
                zoomedMedia = nil
            }
        }
    }

    private var editHeader: some View {
        MomentsCreateEditorPageHeader(
            title: L10n.string("create.media.editTitle"),
            dismiss: { dismiss() }
        )
    }

    private var displayCount: Int {
        workingMedia.isEmpty ? syncedMediaAssets.count : workingMedia.count
    }
}

private struct MomentsCreateMediaEmptyState: View {
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
                    Text(L10n.string("moment.progress.noMedia"))
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

private struct MomentsCreateSyncedMediaEditorTile: View {
    let media: MomentMediaAsset
    let index: Int

    var body: some View {
        VStack(spacing: 6) {
            MomentsCreateSyncedMediaThumbnailImage(media: media)
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

private struct MomentsCreateMediaImportProgressCard: View {
    let selectedCount: Int
    let progress: MomentsMediaImportProgress?

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

private struct MomentsCreateManageableMediaTile: View {
    let media: MomentsSelectedMedia
    let index: Int
    let isImporting: Bool
    let zoom: () -> Void
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
        if media.kind == "photo", let image = UIImage(data: media.data) {
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
                    .foregroundStyle(MomentsTheme.highlight)
            }
            .frame(width: mediaFrame.width, height: mediaFrame.height)
        }
    }
}

private struct MomentsCreateMediaZoomView: View {
    let media: MomentsSelectedMedia
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
        if media.kind == "photo", let image = UIImage(data: media.data) {
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

private struct MomentsCreateEditorAviPanel: View {
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

private struct MomentsCreateMediaReorderRow: View {
    let media: MomentsSelectedMedia
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
        if media.kind == "photo", let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                AVBrandColor.neutral100
                Image(systemName: media.kind == "video" ? "video.fill" : "photo.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(MomentsTheme.highlight)
            }
        }
    }
}

private struct MomentsCreateSyncedMediaSection: View {
    let mediaAssets: [MomentMediaAsset]

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
                        MomentsCreateSyncedMediaThumbnailTile(media: media, index: index)
                    }
                }
            }
        }
    }
}

struct MomentsCreateSoftActionButtonStyle: ButtonStyle {
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

struct MomentsCreateFixedFooterAction: View {
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
            .buttonStyle(MomentsCreateSoftActionButtonStyle())
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

struct MomentsCreateSubtleInlineButtonStyle: ButtonStyle {
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

struct MomentsCreateNeutralInlineButtonStyle: ButtonStyle {
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

struct MomentsCreateEditorPageHeader: View {
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

private struct MomentsCreateToolbarPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(AVBrandColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(configuration.isPressed ? 0.78 : 0.92), in: Capsule())
            .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
