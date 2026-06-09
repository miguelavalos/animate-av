import AVAppShellFoundation
import AVBrandFoundation
import CryptoKit
import PhotosUI
import SwiftUI
import UIKit

enum AnimateCreateImageLook: String, CaseIterable, Identifiable {
    case anime
    case cartoon
    case comic
    case clay
    case watercolor
    case cinematic3d
    case manga
    case paperCut
    case plush
    case sticker
    case pixel
    case neon
    case storybook
    case yellowComedy
    case soft3d
    case darkFantasy
    case vintagePoster
    case pencilSketch
    case editorialCaricature
    case euroComic
    case americanComic
    case stopMotion
    case blackWhiteManga
    case toyFigure
    case chibi
    case flatVector
    case pastelDream
    case heroicComic
    case noirInk
    case rubberHose
    case fantasyQuest
    case miniAvatar

    var id: String { rawValue }

    static var selectorOrder: [AnimateCreateImageLook] {
        [
            .cartoon,
            .anime,
            .cinematic3d,
            .watercolor,
            .comic,
            .manga,
            .clay,
            .paperCut,
            .plush,
            .sticker,
            .pixel,
            .neon,
            .storybook,
            .yellowComedy,
            .soft3d,
            .darkFantasy,
            .vintagePoster,
            .pencilSketch,
            .editorialCaricature,
            .euroComic,
            .americanComic,
            .stopMotion,
            .blackWhiteManga,
            .toyFigure,
            .chibi,
            .flatVector,
            .pastelDream,
            .heroicComic,
            .noirInk,
            .rubberHose,
            .fantasyQuest,
            .miniAvatar
        ]
    }

    var title: String {
        switch self {
        case .anime: L10n.string("create.look.anime.title")
        case .cartoon: L10n.string("create.look.cartoon.title")
        case .comic: L10n.string("create.look.comic.title")
        case .clay: L10n.string("create.look.clay.title")
        case .watercolor: L10n.string("create.look.watercolor.title")
        case .cinematic3d: L10n.string("create.look.cinematic3d.title")
        case .manga: L10n.string("create.look.manga.title")
        case .paperCut: L10n.string("create.look.paperCut.title")
        case .plush: L10n.string("create.look.plush.title")
        case .sticker: L10n.string("create.look.sticker.title")
        case .pixel: L10n.string("create.look.pixel.title")
        case .neon: L10n.string("create.look.neon.title")
        case .storybook: L10n.string("create.look.storybook.title")
        case .yellowComedy: L10n.string("create.look.yellowComedy.title")
        case .soft3d: L10n.string("create.look.soft3d.title")
        case .darkFantasy: L10n.string("create.look.darkFantasy.title")
        case .vintagePoster: L10n.string("create.look.vintagePoster.title")
        case .pencilSketch: L10n.string("create.look.pencilSketch.title")
        case .editorialCaricature: L10n.string("create.look.editorialCaricature.title")
        case .euroComic: L10n.string("create.look.euroComic.title")
        case .americanComic: L10n.string("create.look.americanComic.title")
        case .stopMotion: L10n.string("create.look.stopMotion.title")
        case .blackWhiteManga: L10n.string("create.look.blackWhiteManga.title")
        case .toyFigure: L10n.string("create.look.toyFigure.title")
        case .chibi: L10n.string("create.look.chibi.title")
        case .flatVector: L10n.string("create.look.flatVector.title")
        case .pastelDream: L10n.string("create.look.pastelDream.title")
        case .heroicComic: L10n.string("create.look.heroicComic.title")
        case .noirInk: L10n.string("create.look.noirInk.title")
        case .rubberHose: L10n.string("create.look.rubberHose.title")
        case .fantasyQuest: L10n.string("create.look.fantasyQuest.title")
        case .miniAvatar: L10n.string("create.look.miniAvatar.title")
        }
    }

    var assetName: String {
        switch self {
        case .anime: "LookAnime"
        case .cartoon: "LookCartoon"
        case .comic: "LookComic"
        case .clay: "LookClay"
        case .watercolor: "LookCartoon"
        case .cinematic3d: "LookClay"
        case .manga: "LookAnime"
        case .paperCut: "LookComic"
        case .plush: "LookClay"
        case .sticker: "LookCartoon"
        case .pixel: "LookComic"
        case .neon: "LookAnime"
        case .storybook: "LookCartoon"
        case .yellowComedy: "LookCartoon"
        case .soft3d: "LookClay"
        case .darkFantasy: "LookAnime"
        case .vintagePoster: "LookComic"
        case .pencilSketch: "LookComic"
        case .editorialCaricature: "LookComic"
        case .euroComic: "LookComic"
        case .americanComic: "LookComic"
        case .stopMotion: "LookClay"
        case .blackWhiteManga: "LookAnime"
        case .toyFigure: "LookClay"
        case .chibi: "LookAnime"
        case .flatVector: "LookCartoon"
        case .pastelDream: "LookCartoon"
        case .heroicComic: "LookComic"
        case .noirInk: "LookComic"
        case .rubberHose: "LookCartoon"
        case .fantasyQuest: "LookAnime"
        case .miniAvatar: "LookClay"
        }
    }
}

struct AnimateCreateImagesWorkspace: View {
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let imageGenerationAvailability: AnimateImageGenerationAvailabilityResponse?
    let isLoadingImageGenerationAvailability: Bool
    let isStartingImageGeneration: Bool
    let isPurchasingImageGenerationPack: Bool
    let imageGenerationAvailabilityMessage: String?
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageData: Data?
    @Binding var selectedSourceImageLocalIdentifier: String?
    @Binding var selectedLooks: Set<AnimateCreateImageLook>
    let refreshImageGenerationAvailability: () -> Void
    let startImageGeneration: (String?, Data?, Int?, Int?, [String]) -> Void
    let purchaseImageGenerationPack: () -> Void
    let openCredits: () -> Void
    let cancelCreation: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var isLoadingImage = false
    @State private var showsInitialPhotoPicker = false
    @State private var showsLookSheet = false

    private let lookSelectionLimit = 5

    private var canSubmit: Bool {
        selectedImage != nil
            && selectedImageData != nil
            && selectedSourceImageLocalIdentifier?.isEmpty == false
            && !selectedLooks.isEmpty
            && !isLoadingImageGenerationAvailability
            && imageGenerationAvailability != nil
            && imageGenerationAvailability?.availableImages ?? 0 >= selectedLooks.count
            && !isStartingImageGeneration
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AnimateCreateImagesHeader()

                AnimateCreateImagesAviGuide(
                    hasImage: selectedImage != nil,
                    selectedLookCount: selectedLooks.count
                )

                if selectedImage == nil {
                    AnimateCreateImagesSourceCard(
                        image: selectedImage,
                        isLoading: isLoadingImage,
                        pickerItem: $pickerItem
                    )
                } else {
                    AnimateCreateImagesSummaryCard(
                        image: selectedImage,
                        isLoading: isLoadingImage,
                        showsPhotoPicker: $showsInitialPhotoPicker,
                        selectedLookCount: selectedLooks.count,
                        editLooks: { showsLookSheet = true },
                        closeDraft: cancelCreation
                    )

                    AnimateCreateImagesBalanceCard(
                        spendableCredits: balance.spendable,
                        creditBalanceLoadState: creditBalanceLoadState,
                        imageGenerationAvailability: imageGenerationAvailability,
                        isLoadingImageGenerationAvailability: isLoadingImageGenerationAvailability,
                        isPurchasingImageGenerationPack: isPurchasingImageGenerationPack,
                        imageGenerationAvailabilityMessage: imageGenerationAvailabilityMessage,
                        purchaseImageGenerationPack: purchaseImageGenerationPack,
                        openCredits: openCredits
                    )

                    AnimateCreateImagesActionDock(
                        title: actionDockTitle,
                        detail: actionDockDetail,
                        buttonTitle: createButtonTitle,
                        canSubmit: canSubmit,
                        isStarting: isStartingImageGeneration
                    ) {
                        startImageGeneration(
                            selectedSourceImageLocalIdentifier,
                            selectedImageData,
                            selectedImage.map { Int($0.size.width * $0.scale) },
                            selectedImage.map { Int($0.size.height * $0.scale) },
                            selectedLooks.map(\.rawValue).sorted()
                        )
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .photosPicker(
            isPresented: $showsInitialPhotoPicker,
            selection: $pickerItem,
            matching: .images
        )
        .sheet(isPresented: $showsLookSheet) {
            AnimateCreateImagesLookSheet(
                selectedLooks: $selectedLooks,
                selectionLimit: lookSelectionLimit
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: pickerItem) { _, item in
            loadImage(from: item)
        }
        .task {
            refreshImageGenerationAvailability()
        }
    }

    private var createButtonTitle: String {
        if selectedImage == nil {
            return L10n.string("create.images.action.needsImage")
        }
        if selectedLooks.isEmpty {
            return L10n.string("create.images.action.needsLooks")
        }
        if selectedLooks.count > lookSelectionLimit {
            return L10n.string("create.images.action.tooManyLooks")
        }
        if isStartingImageGeneration {
            return L10n.string("create.images.action.starting")
        }
        if isLoadingImageGenerationAvailability || imageGenerationAvailability == nil {
            return L10n.string("create.images.action.checkingGenerations")
        }
        if let availableImages = imageGenerationAvailability?.availableImages,
           availableImages < selectedLooks.count {
            return L10n.string("create.images.action.needsGenerations")
        }
        return L10n.string("create.images.action.startCount", selectedLooks.count)
    }

    private var actionDockTitle: String {
        if isStartingImageGeneration {
            return L10n.string("create.images.actionDock.starting.title")
        }
        return canSubmit
            ? L10n.string("create.images.actionDock.ready.title")
            : L10n.string("create.images.actionDock.blocked.title")
    }

    private var actionDockDetail: String {
        if isStartingImageGeneration {
            return L10n.string("create.images.actionDock.starting.detail")
        }
        if let imageGenerationAvailabilityMessage, !imageGenerationAvailabilityMessage.isEmpty {
            return imageGenerationAvailabilityMessage
        }
        if canSubmit {
            return L10n.string("create.images.actionDock.ready.detail")
        }
        return L10n.string("create.images.actionDock.blocked.detail")
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingImage = true
        selectedSourceImageLocalIdentifier = item.itemIdentifier
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            let image = data.flatMap(UIImage.init(data:))
            let uploadData = image?.jpegData(compressionQuality: 0.95)
            let sourceIdentifier = uploadData.map {
                Self.sourceLocalIdentifier(itemIdentifier: item.itemIdentifier, imageData: $0)
            }
            await MainActor.run {
                selectedImage = image
                selectedImageData = uploadData
                selectedSourceImageLocalIdentifier = sourceIdentifier
                isLoadingImage = false
                if image != nil {
                    showsLookSheet = true
                }
            }
        }
    }

    private static func sourceLocalIdentifier(itemIdentifier: String?, imageData: Data) -> String {
        if let itemIdentifier = itemIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
           !itemIdentifier.isEmpty {
            return itemIdentifier
        }

        let digest = SHA256.hash(data: imageData)
            .prefix(12)
            .map { String(format: "%02x", $0) }
            .joined()
        return "animate-image-\(digest)"
    }
}

private struct AnimateCreateImagesActionDock: View {
    let title: String
    let detail: String
    let buttonTitle: String
    let canSubmit: Bool
    let isStarting: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: isStarting ? "sparkles" : "photo.stack.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(canSubmit ? AVBrandColor.textPrimary : AVBrandColor.textSecondary, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .lineLimit(1)

                    Text(detail)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Label(buttonTitle, systemImage: isStarting ? "sparkles" : "photo.stack.fill")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(canSubmit ? AVBrandColor.textPrimary : AVBrandColor.textSecondary.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(
                        colors: [
                            AVBrandColor.accent.opacity(canSubmit ? 0.16 : 0.07),
                            AVBrandColor.mutedSurface.opacity(canSubmit ? 0.92 : 0.62)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    Capsule()
                        .stroke(AVBrandColor.glassStroke.opacity(canSubmit ? 0.78 : 0.45), lineWidth: 1)
                }
                .contentShape(Capsule())
                .onTapGesture {
                    guard canSubmit else { return }
                    action()
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityAction {
                    guard canSubmit else { return }
                    action()
                }
            .opacity(canSubmit ? 1 : 0.72)
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

private struct AnimateCreateImagesSoftActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AVBrandColor.textPrimary : AVBrandColor.textSecondary.opacity(0.55))
            .padding(.horizontal, 18)
            .background(
                LinearGradient(
                    colors: [
                        AVBrandColor.accent.opacity(isEnabled ? 0.16 : 0.07),
                        AVBrandColor.mutedSurface.opacity(isEnabled ? 0.92 : 0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(AVBrandColor.glassStroke.opacity(isEnabled ? 0.78 : 0.45), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1)
    }
}

private struct AnimateCreateImagesAviGuide: View {
    let hasImage: Bool
    let selectedLookCount: Int

    var body: some View {
        AVAppShellCard {
            HStack(alignment: .center, spacing: 14) {
                Image("AviFullBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(5)
                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var title: String {
        hasImage
            ? L10n.string("create.images.avi.ready.title")
            : L10n.string("create.images.avi.start.title")
    }

    private var message: String {
        hasImage
            ? L10n.string("create.images.avi.ready.detail", selectedLookCount)
            : L10n.string("create.images.avi.start.detail")
    }
}

private struct AnimateCreateImagesPickingState: View {
    let choosePhoto: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 160)

            Image(systemName: "photo.badge.plus")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 88, height: 88)
                .background(Circle().fill(AVBrandColor.accent.opacity(0.10)))

            VStack(spacing: 6) {
                Text(L10n.string("create.images.source.chooseFirst.title"))
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(L10n.string("create.images.source.chooseFirst.detail"))
                    .font(AVBrandTypography.body)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: choosePhoto) {
                Label(L10n.string("create.images.source.choose"), systemImage: "photo.badge.plus")
                    .font(.system(size: 15, weight: .black))
                    .frame(maxWidth: 240)
                    .frame(height: 46)
            }
            .buttonStyle(AnimateCreateImagesSoftActionButtonStyle())
            .padding(.top, 4)

            Spacer(minLength: 220)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AnimateCreateImagesHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.string("create.images.title"))
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)

            Text(L10n.string("create.images.subtitle"))
                .font(AVBrandTypography.body)
                .foregroundStyle(AVBrandColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnimateCreateImagesSourceCard: View {
    let image: UIImage?
    let isLoading: Bool
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 14) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 58, height: 58)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
                        )
                } else {
                    Image(systemName: isLoading ? "hourglass" : "photo")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(AVBrandColor.accent)
                        .frame(width: 58, height: 58)
                        .background(AVBrandColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(image == nil ? L10n.string("create.images.source.title") : L10n.string("create.images.source.selected"))
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(image == nil ? L10n.string("create.images.source.detail") : L10n.string("create.images.source.selectedDetail"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(
                    image == nil ? L10n.string("create.images.source.choose") : L10n.string("create.images.source.replace"),
                    systemImage: image == nil ? "photo.badge.plus" : "arrow.triangle.2.circlepath"
                )
                .font(.system(size: 15, weight: .black))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
            }
            .buttonStyle(AnimateCreateSoftActionButtonStyle())
        }
        .padding(12)
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

private struct AnimateCreateImagesSummaryCard: View {
    let image: UIImage?
    let isLoading: Bool
    @Binding var showsPhotoPicker: Bool
    let selectedLookCount: Int
    let editLooks: () -> Void
    let closeDraft: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Image(systemName: isLoading ? "hourglass" : "photo")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)
                        .frame(width: 64, height: 64)
                        .background(AVBrandColor.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AVBrandColor.textInverse)
                    .frame(width: 34, height: 34)
                    .background(AVBrandColor.textPrimary, in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string("create.images.selection.title"))
                        .font(.system(size: 21, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.string("create.images.selection.detail"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Menu {
                    Section(L10n.string("create.videoDirection.menu.userActions")) {
                        Button {
                            showsPhotoPicker = true
                        } label: {
                            Label(L10n.string("create.media.editTitle"), systemImage: "photo.stack")
                        }

                        Button(role: .destructive, action: closeDraft) {
                            Label(L10n.string("create.discard.closeDraft"), systemImage: "xmark.circle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AVBrandColor.mutedSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.string("create.videoDirection.menu.accessibility"))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AVBrandColor.mutedSurface)
                    Capsule()
                        .fill(AVBrandColor.accent)
                        .frame(width: proxy.size.width * 0.50)
                }
            }
            .frame(height: 5)

            Button(action: editLooks) {
                HStack(spacing: 10) {
                    Image(systemName: "paintbrush.pointed.fill")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)
                        .frame(width: 30, height: 30)
                        .background(AVBrandColor.accent.opacity(0.10), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string("create.images.summary.looks.title"))
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)
                        Text(L10n.string("create.images.summary.looks.detail", selectedLookCount))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary.opacity(0.7))
                }
                .padding(10)
                .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
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

private struct AnimateCreateImagesLookSheet: View {
    @Binding var selectedLooks: Set<AnimateCreateImageLook>
    let selectionLimit: Int

    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex = 0

    private let looksPerPage = 8

    private var pageCount: Int {
        max(1, (AnimateCreateImageLook.selectorOrder.count + looksPerPage - 1) / looksPerPage)
    }

    private var visibleLooks: [AnimateCreateImageLook] {
        let startIndex = pageIndex * looksPerPage
        let endIndex = min(startIndex + looksPerPage, AnimateCreateImageLook.selectorOrder.count)
        guard startIndex < endIndex else { return [] }
        return Array(AnimateCreateImageLook.selectorOrder[startIndex..<endIndex])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.string("create.images.looks.title"))
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)

                        Text(L10n.string("create.images.looks.detail", selectionLimit))
                            .font(AVBrandTypography.body)
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(L10n.string("create.images.looks.selectedCount", selectedLooks.count, selectedLooks.count))
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(AVBrandColor.accent)
                            .padding(.top, 2)
                    }

                    AnimateCreateImagesTwoColumnGrid(items: visibleLooks, verticalSpacing: 10, itemHeight: 92) { look in
                        Button {
                            toggle(look)
                        } label: {
                            AnimateCreateImageLookTile(
                                look: look,
                                isSelected: selectedLooks.contains(look)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 10) {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                pageIndex = max(0, pageIndex - 1)
                            }
                        } label: {
                            Label(L10n.string("create.images.looks.previousPage"), systemImage: "chevron.left.circle.fill")
                                .font(.system(size: 14, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(AnimateCreateSoftActionButtonStyle())
                        .disabled(pageIndex == 0)

                        Text(L10n.string("create.images.looks.page", pageIndex + 1, pageCount))
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .frame(minWidth: 48)

                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                pageIndex = min(pageCount - 1, pageIndex + 1)
                            }
                        } label: {
                            Label(L10n.string("create.images.looks.nextPage"), systemImage: "chevron.right.circle.fill")
                                .font(.system(size: 14, weight: .black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(AnimateCreateSoftActionButtonStyle())
                        .disabled(pageIndex >= pageCount - 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 104)
            }
            .background(AnimateTheme.shellBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                        .opacity(0.45)
                    Button {
                        dismiss()
                    } label: {
                        Label(L10n.string("create.images.looks.done"), systemImage: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .black))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .disabled(selectedLooks.isEmpty)
                    .buttonStyle(AnimateCreateImagesSoftActionButtonStyle())
                    .opacity(selectedLooks.isEmpty ? 0.62 : 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .background(.ultraThinMaterial)
                }
            }
            .onChange(of: pageCount) { _, newPageCount in
                pageIndex = min(pageIndex, max(0, newPageCount - 1))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AVBrandColor.textSecondary.opacity(0.75))
                    }
                    .accessibilityLabel(L10n.string("common.close"))
                }
            }
        }
    }

    private func toggle(_ look: AnimateCreateImageLook) {
        if selectedLooks.contains(look) {
            selectedLooks.remove(look)
        } else {
            guard selectedLooks.count < selectionLimit else { return }
            selectedLooks.insert(look)
        }
    }
}

private struct AnimateCreateImagesTwoColumnGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var horizontalSpacing: CGFloat = 12
    var verticalSpacing: CGFloat = 12
    var itemHeight: CGFloat = 106
    let content: (Item) -> Content

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: verticalSpacing) {
            ForEach(items) { item in
                content(item)
                    .frame(width: itemWidth, height: itemHeight)
                    .clipped()
            }
        }
        .frame(width: gridWidth, alignment: .center)
        .frame(maxWidth: .infinity)
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

private struct AnimateCreateImageLookTile: View {
    let look: AnimateCreateImageLook
    let isSelected: Bool

    var body: some View {
        GeometryReader { proxy in
            tileContent(width: proxy.size.width)
        }
        .frame(height: 92)
    }

    private func tileContent(width: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(look.assetName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: 92)
                .clipped()

            LinearGradient(
                colors: [
                    .black.opacity(0.02),
                    .black.opacity(0.58),
                    .black.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Text(look.title)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                .padding(9)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white, AVBrandColor.accent)
                    .padding(7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .frame(width: width, height: 92)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.58), lineWidth: isSelected ? 2 : 1)
        }
        .shadow(color: AVBrandColor.ink.opacity(isSelected ? 0.14 : 0.08), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
    }
}

private struct AnimateCreateImagesBalanceCard: View {
    let spendableCredits: Int
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let imageGenerationAvailability: AnimateImageGenerationAvailabilityResponse?
    let isLoadingImageGenerationAvailability: Bool
    let isPurchasingImageGenerationPack: Bool
    let imageGenerationAvailabilityMessage: String?
    let purchaseImageGenerationPack: () -> Void
    let openCredits: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles.square.filled.on.square")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 42, height: 42)
                .background(Circle().fill(AVBrandColor.accent.opacity(0.10)))

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string("create.images.balance.title"))
                    .font(AVBrandTypography.bodyStrong)
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(balanceDetail)
                    .font(AVBrandTypography.caption)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if shouldShowBalanceAction {
                Button(balanceActionTitle) {
                    if canPurchasePack {
                        purchaseImageGenerationPack()
                    } else {
                        openCredits()
                    }
                }
                .font(.system(size: 13, weight: .black))
                .buttonStyle(.bordered)
                .disabled(isPurchasingImageGenerationPack)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
        )
    }

    private var balanceDetail: String {
        if isLoadingImageGenerationAvailability {
            return L10n.string("create.images.balance.loading")
        }
        if let imageGenerationAvailabilityMessage, !imageGenerationAvailabilityMessage.isEmpty {
            return imageGenerationAvailabilityMessage
        }
        if let imageGenerationAvailability {
            return availabilityDetail(imageGenerationAvailability)
        }

        return switch creditBalanceLoadState {
        case .loading:
            L10n.string("create.images.balance.loading")
        case .offline:
            L10n.string("create.images.balance.offline")
        case .unavailable:
            L10n.string("create.images.balance.unavailable")
        case .signedOut:
            L10n.string("create.images.balance.signIn")
        case .loaded:
            spendableCredits > 0
                ? L10n.string("create.images.balance.packAvailable", spendableCredits)
                : L10n.string("create.images.balance.empty")
        }
    }

    private var shouldShowBalanceAction: Bool {
        guard let availability = imageGenerationAvailability else {
            return spendableCredits <= 0
        }

        return availability.availableImages <= 0
    }

    private var balanceActionTitle: String {
        if isPurchasingImageGenerationPack {
            return L10n.string("create.images.balance.buyingPack")
        }
        if canPurchasePack,
           let offer = imageGenerationAvailability?.packOffer {
            return L10n.string("create.images.balance.buyPack", offer.imageGenerations, offer.creditCost)
        }

        return L10n.string("create.images.balance.add")
    }

    private var canPurchasePack: Bool {
        guard let offer = imageGenerationAvailability?.packOffer,
              offer.userCanPurchase
        else {
            return false
        }

        return true
    }

    private func availabilityDetail(_ availability: AnimateImageGenerationAvailabilityResponse) -> String {
        if availability.availableImages > 0 {
            return L10n.string(
                "create.images.balance.available",
                availability.availableImages,
                availability.monthlyProAllowance.remaining,
                availability.purchasedImages.balance
            )
        }

        if availability.packOffer.userCanPurchase {
            return L10n.string(
                "create.images.balance.packOffer",
                availability.packOffer.imageGenerations,
                availability.packOffer.creditCost
            )
        }

        return L10n.string("create.images.balance.empty")
    }
}
