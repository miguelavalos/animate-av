import AVMediaAnalysisFoundation
import Foundation

struct AnimateMediaAutoStyleSuggestion: Equatable {
    let styleID: AnimateVideoCreationStyleID
    let musicPreset: AnimateVideoMusicPreset
    let confidence: Double
    let reason: String
    let metrics: AnimateMediaAutoStyleMetrics

    var confidenceTitle: String {
        "\(Int((confidence * 100).rounded()))%"
    }
}

struct AnimateMediaAutoStyleMetrics: Equatable {
    let mediaCount: Int
    let photoCount: Int
    let videoCount: Int
    let datedCount: Int
    let totalBytes: Int
    let sampleCount: Int
    let analyzedCount: Int
    let peopleAssetCount: Int
    let groupAssetCount: Int
    let sceneryAssetCount: Int
    let screenshotCount: Int
    let averageQualityScore: Double
    let estimatedThumbnailKilobytes: Int
    let estimatedVisionUnits: Int
    let estimatedMetadataTokens: Int

    var summary: String {
        "\(sampleCount) samples · \(estimatedThumbnailKilobytes) KB thumbs · \(estimatedMetadataTokens) metadata tokens"
    }
}

enum AnimateMediaAutoStyleSuggester {
    static func suggest(
        media: [AnimateSelectedMedia],
        styles: [AnimateVideoCreationStyle]
    ) -> AnimateMediaAutoStyleSuggestion? {
        guard !media.isEmpty else { return nil }

        let photoCount = media.filter { $0.kind == "photo" }.count
        let videoCount = media.filter { $0.kind == "video" }.count
        let datedMedia = media.compactMap(\.capturedAt)
        let filenames = media.map { $0.originalFilename.lowercased() }.joined(separator: " ")
        let totalBytes = media.reduce(0) { $0 + $1.byteSize }
        let sampleCount = min(media.count, 12)
        let analyses = media.compactMap(\.analysis)
        let peopleAssetCount = analyses.filter(\.hasPeople).count
        let groupAssetCount = analyses.filter { $0.sceneRole == .group }.count
        let sceneryAssetCount = analyses.filter { $0.sceneRole == .scenery }.count
        let screenshotCount = analyses.filter(\.isLikelyScreenshot).count
        let averageQualityScore = average(analyses.map(\.qualityScore))
        let metrics = AnimateMediaAutoStyleMetrics(
            mediaCount: media.count,
            photoCount: photoCount,
            videoCount: videoCount,
            datedCount: datedMedia.count,
            totalBytes: totalBytes,
            sampleCount: sampleCount,
            analyzedCount: analyses.count,
            peopleAssetCount: peopleAssetCount,
            groupAssetCount: groupAssetCount,
            sceneryAssetCount: sceneryAssetCount,
            screenshotCount: screenshotCount,
            averageQualityScore: averageQualityScore,
            estimatedThumbnailKilobytes: sampleCount * 80,
            estimatedVisionUnits: sampleCount,
            estimatedMetadataTokens: media.count * 36
        )

        let dateSpan = dateSpanSeconds(datedMedia)
        let candidate: (AnimateVideoCreationStyleID, AnimateVideoMusicPreset, Double, String)

        if containsAny(filenames, keywords: ["birthday", "cumple", "anni", "bday"]) {
            candidate = (.birthday, .warm, 0.72, "Filename hints look like a birthday set.")
        } else if screenshotCount >= max(2, media.count / 2) {
            candidate = (.eventRecap, .warm, 0.55, "Screenshots are safest as a simple recap.")
        } else if containsAny(filenames, keywords: ["trip", "travel", "viaje", "calama", "desert", "road", "playa", "mountain"]) {
            candidate = (.travel, .cinematic, 0.70, "Filename hints and media set look travel oriented.")
        } else if sceneryAssetCount >= max(3, media.count / 2) {
            candidate = (.travel, .cinematic, 0.68, "Local image analysis sees a scenic set.")
        } else if groupAssetCount >= max(2, media.count / 3) {
            candidate = (.familyMoments, .warm, 0.66, "Local image analysis sees several group videos.")
        } else if peopleAssetCount >= max(2, media.count / 2) && sceneryAssetCount < peopleAssetCount {
            candidate = (.favoritePeople, .warm, 0.63, "Local image analysis sees people-focused videos.")
        } else if videoCount > 0 && videoCount >= max(1, photoCount / 3) {
            candidate = (.eventRecap, .fun, 0.64, "Several clips suggest a fast event recap.")
        } else if media.count >= 10 && dateSpan > 6 * 60 * 60 {
            candidate = (.travel, .cinematic, 0.62, "Many videos across several hours fit a trip or day recap.")
        } else if media.count >= 6 {
            candidate = (.familyMoments, .warm, 0.58, "A medium set works best as a warm memory recap.")
        } else {
            candidate = (.eventRecap, .warm, 0.48, "Small sets are safest as a simple event recap.")
        }

        guard let style = styles.first(where: { $0.id == candidate.0 && $0.isEnabled }) else {
            return nil
        }

        let music = style.allowedMusic.contains(candidate.1) ? candidate.1 : style.defaultMusic
        return AnimateMediaAutoStyleSuggestion(
            styleID: style.id,
            musicPreset: music,
            confidence: candidate.2,
            reason: candidate.3,
            metrics: metrics
        )
    }

    private static func dateSpanSeconds(_ dates: [Date]) -> TimeInterval {
        guard let first = dates.min(), let last = dates.max() else { return 0 }
        return last.timeIntervalSince(first)
    }

    private static func containsAny(_ value: String, keywords: [String]) -> Bool {
        keywords.contains { value.contains($0) }
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
