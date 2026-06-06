import AVBrandFoundation
import SwiftUI

struct MomentsCreateSetupFormFields: View {
    @Binding var form: MomentSetupForm
    let templateSelection: Binding<MomentTemplateID>
    let templates: [MomentTemplate]
    let isSetupLocked: Bool

    private var selectedTemplateTitle: String {
        templates.first(where: { $0.id == templateSelection.wrappedValue })?.title ?? L10n.string("create.form.template.choose")
    }

    var body: some View {
        VStack(spacing: AVBrandSpacing.sm) {
            MomentsCreateMenuField(
                title: L10n.string("create.form.template"),
                value: selectedTemplateTitle,
                systemImage: "sparkles.rectangle.stack",
                isDisabled: isSetupLocked
            ) {
                ForEach(templates) { template in
                    Button(template.title) {
                        templateSelection.wrappedValue = template.id
                    }
                }
            }
            .accessibilityIdentifier("moments.create.template")

            MomentsCreateTextFieldRow(
                title: L10n.string("create.form.occasion"),
                placeholder: L10n.string("create.form.occasion.placeholder"),
                systemImage: "calendar",
                text: $form.occasion,
                isDisabled: isSetupLocked
            )
            .accessibilityIdentifier("moments.create.occasion")

            MomentsCreateTextFieldRow(
                title: L10n.string("create.form.recipient"),
                placeholder: L10n.string("create.form.recipient.placeholder"),
                systemImage: "person.crop.circle",
                text: $form.recipient,
                isDisabled: isSetupLocked
            )
            .accessibilityIdentifier("moments.create.recipient")

            HStack(spacing: AVBrandSpacing.sm) {
                MomentsCreateMenuField(
                    title: L10n.string("create.form.tone"),
                    value: form.tone.title,
                    systemImage: "quote.bubble.fill",
                    isDisabled: isSetupLocked
                ) {
                    ForEach(MomentSetupTone.allCases) { tone in
                        Button(tone.title) {
                            form.tone = tone
                        }
                    }
                }
                .accessibilityIdentifier("moments.create.tone")

                MomentsCreateMenuField(
                    title: L10n.string("create.form.tempo"),
                    value: form.tempo.title,
                    systemImage: "metronome.fill",
                    isDisabled: isSetupLocked
                ) {
                    ForEach(MomentSetupTempo.allCases) { tempo in
                        Button(tempo.title) {
                            form.tempo = tempo
                        }
                    }
                }
                .accessibilityIdentifier("moments.create.tempo")
            }

            MomentsCreateMultilineFieldRow(
                title: L10n.string("create.form.details"),
                placeholder: L10n.string("create.form.details.placeholder"),
                systemImage: "wand.and.stars",
                text: $form.details,
                isDisabled: isSetupLocked
            )
            .accessibilityIdentifier("moments.create.details")
        }
    }
}

private struct MomentsCreateMenuField<MenuContent: View>: View {
    @Environment(\.avBrandPalette) private var brandPalette

    let title: String
    let value: String
    let systemImage: String
    let isDisabled: Bool
    let menuContent: MenuContent

    init(
        title: String,
        value: String,
        systemImage: String,
        isDisabled: Bool,
        @ViewBuilder menuContent: () -> MenuContent
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.isDisabled = isDisabled
        self.menuContent = menuContent()
    }

    var body: some View {
        Menu {
            menuContent
        } label: {
            HStack(spacing: AVBrandSpacing.sm) {
                MomentsCreateFieldIcon(systemImage: systemImage)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .textCase(.uppercase)
                        .lineLimit(1)

                    Text(value)
                        .font(AVBrandTypography.bodyStrong)
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AVBrandColor.textSecondary.opacity(0.72))
            }
            .padding(AVBrandSpacing.md)
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
            .background(MomentsCreateFieldBackground())
        }
        .buttonStyle(.plain)
        .tint(brandPalette.accent)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.62 : 1)
    }
}

private struct MomentsCreateTextFieldRow: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: AVBrandSpacing.sm) {
            MomentsCreateFieldIcon(systemImage: systemImage)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                TextField(placeholder, text: $text)
                    .font(AVBrandTypography.bodyStrong)
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.next)
                    .disabled(isDisabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AVBrandSpacing.md)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(MomentsCreateFieldBackground())
        .opacity(isDisabled ? 0.62 : 1)
    }
}

struct MomentsCreateMultilineFieldRow: View {
    let title: String
    let placeholder: String
    let systemImage: String
    @Binding var text: String
    let isDisabled: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AVBrandSpacing.sm) {
            MomentsCreateFieldIcon(systemImage: systemImage)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: AVBrandSpacing.xxs) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .textCase(.uppercase)
                    .lineLimit(1)

                TextField(placeholder, text: $text, axis: .vertical)
                    .font(AVBrandTypography.body)
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(3...5)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .disabled(isDisabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AVBrandSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MomentsCreateFieldBackground())
        .opacity(isDisabled ? 0.62 : 1)
    }
}

private struct MomentsCreateFieldIcon: View {
    @Environment(\.avBrandPalette) private var brandPalette

    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(brandPalette.accent)
            .frame(width: 28, height: 28)
            .background(
                brandPalette.accent.opacity(0.12),
                in: RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous)
            )
    }
}

private struct MomentsCreateFieldBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous)
            .fill(AVBrandColor.cardSurface.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.5), lineWidth: 1)
            }
    }
}
