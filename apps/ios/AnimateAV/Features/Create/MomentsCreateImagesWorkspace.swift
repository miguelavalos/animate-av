import AVBrandFoundation
import PhotosUI
import SwiftUI
import UIKit

private enum MomentsCreateImageLook: String, CaseIterable, Identifiable {
    case cartoon
    case anime
    case watercolor
    case comic
    case clay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cartoon:
            L10n.string("create.images.look.cartoon")
        case .anime:
            L10n.string("create.images.look.anime")
        case .watercolor:
            L10n.string("create.images.look.watercolor")
        case .comic:
            L10n.string("create.images.look.comic")
        case .clay:
            L10n.string("create.images.look.clay")
        }
    }

    var systemImage: String {
        switch self {
        case .cartoon:
            "sparkles"
        case .anime:
            "eyes"
        case .watercolor:
            "paintpalette.fill"
        case .comic:
            "captions.bubble.fill"
        case .clay:
            "cube.fill"
        }
    }
}

struct MomentsCreateImagesWorkspace: View {
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let imageGenerationAvailability: AnimateImageGenerationAvailabilityResponse?
    let isLoadingImageGenerationAvailability: Bool
    let isStartingImageGeneration: Bool
    let isPurchasingImageGenerationPack: Bool
    let imageGenerationAvailabilityMessage: String?
    let refreshImageGenerationAvailability: () -> Void
    let startImageGeneration: (String?, Data?, Int?, Int?, [String]) -> Void
    let purchaseImageGenerationPack: () -> Void
    let openCredits: () -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var selectedImageData: Data?
    @State private var selectedSourceImageLocalIdentifier: String?
    @State private var selectedLooks: Set<MomentsCreateImageLook> = [.cartoon]
    @State private var isLoadingImage = false

    private let lookSelectionLimit = 5

    private var canSubmit: Bool {
        selectedImage != nil
            && selectedImageData != nil
            && selectedSourceImageLocalIdentifier != nil
            && !selectedLooks.isEmpty
            && imageGenerationAvailability?.availableImages ?? 0 >= selectedLooks.count
            && !isStartingImageGeneration
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                MomentsCreateImagesHeader()

                MomentsCreateImagesSourceCard(
                    image: selectedImage,
                    isLoading: isLoadingImage,
                    pickerItem: $pickerItem
                )

                MomentsCreateImagesLookGrid(
                    selectedLooks: $selectedLooks,
                    selectionLimit: lookSelectionLimit
                )

                MomentsCreateImagesBalanceCard(
                    spendableCredits: balance.spendable,
                    creditBalanceLoadState: creditBalanceLoadState,
                    imageGenerationAvailability: imageGenerationAvailability,
                    isLoadingImageGenerationAvailability: isLoadingImageGenerationAvailability,
                    isPurchasingImageGenerationPack: isPurchasingImageGenerationPack,
                    imageGenerationAvailabilityMessage: imageGenerationAvailabilityMessage,
                    purchaseImageGenerationPack: purchaseImageGenerationPack,
                    openCredits: openCredits
                )

                Button {
                    startImageGeneration(
                        selectedSourceImageLocalIdentifier,
                        selectedImageData,
                        selectedImage.map { Int($0.size.width * $0.scale) },
                        selectedImage.map { Int($0.size.height * $0.scale) },
                        selectedLooks.map(\.rawValue).sorted()
                    )
                } label: {
                    Label(
                        createButtonTitle,
                        systemImage: "photo.stack.fill"
                    )
                    .font(.system(size: 16, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)
            }
            .padding(.bottom, 24)
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
        if selectedLooks.count > lookSelectionLimit {
            return L10n.string("create.images.action.tooManyLooks")
        }
        if isStartingImageGeneration {
            return L10n.string("create.images.action.starting")
        }
        if let availableImages = imageGenerationAvailability?.availableImages,
           availableImages < selectedLooks.count {
            return L10n.string("create.images.action.needsGenerations")
        }
        return L10n.string("create.images.action.start")
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        isLoadingImage = true
        selectedSourceImageLocalIdentifier = item.itemIdentifier
        Task {
            let data = try? await item.loadTransferable(type: Data.self)
            let image = data.flatMap(UIImage.init(data:))
            let uploadData = image?.jpegData(compressionQuality: 0.95)
            await MainActor.run {
                selectedImage = image
                selectedImageData = uploadData
                isLoadingImage = false
            }
        }
    }
}

private struct MomentsCreateImagesHeader: View {
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

private struct MomentsCreateImagesSourceCard: View {
    let image: UIImage?
    let isLoading: Bool
    @Binding var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string("create.images.source.title"))
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(L10n.string("create.images.source.detail"))
                        .font(AVBrandTypography.caption)
                        .foregroundStyle(AVBrandColor.textSecondary)
                }

                Spacer(minLength: 12)

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(
                        image == nil ? L10n.string("create.images.source.choose") : L10n.string("create.images.source.replace"),
                        systemImage: "photo.badge.plus"
                    )
                    .font(.system(size: 13, weight: .black))
                }
                .buttonStyle(.borderedProminent)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AVBrandColor.elevatedSurface)
                    .frame(height: 220)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: isLoading ? "hourglass" : "photo")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(AVBrandColor.accent)

                        Text(isLoading ? L10n.string("create.images.source.loading") : L10n.string("create.images.source.empty"))
                            .font(AVBrandTypography.bodyStrong)
                            .foregroundStyle(AVBrandColor.textSecondary)
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
    }
}

private struct MomentsCreateImagesLookGrid: View {
    @Binding var selectedLooks: Set<MomentsCreateImageLook>
    let selectionLimit: Int

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("create.images.looks.title"))
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)

            Text(L10n.string("create.images.looks.detail", selectionLimit))
                .font(AVBrandTypography.caption)
                .foregroundStyle(AVBrandColor.textSecondary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(MomentsCreateImageLook.allCases) { look in
                    Button {
                        toggle(look)
                    } label: {
                        MomentsCreateImageLookTile(
                            look: look,
                            isSelected: selectedLooks.contains(look)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
    }

    private func toggle(_ look: MomentsCreateImageLook) {
        if selectedLooks.contains(look) {
            guard selectedLooks.count > 1 else { return }
            selectedLooks.remove(look)
        } else {
            guard selectedLooks.count < selectionLimit else { return }
            selectedLooks.insert(look)
        }
    }
}

private struct MomentsCreateImageLookTile: View {
    let look: MomentsCreateImageLook
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: look.systemImage)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconBackground)

            Text(look.title)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(tileBackground)
        .overlay(tileBorder)
    }

    private var iconColor: Color {
        isSelected ? AVBrandColor.textInverse : AVBrandColor.accent
    }

    private var iconBackground: some View {
        Circle()
            .fill(isSelected ? AVBrandColor.accent : AVBrandColor.accent.opacity(0.10))
    }

    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? AVBrandColor.accent.opacity(0.12) : AVBrandColor.elevatedSurface)
    }

    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(isSelected ? AVBrandColor.accent.opacity(0.6) : AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
    }
}

private struct MomentsCreateImagesBalanceCard: View {
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
        if let imageGenerationAvailability {
            return availabilityDetail(imageGenerationAvailability)
        }
        if let imageGenerationAvailabilityMessage {
            return imageGenerationAvailabilityMessage
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
