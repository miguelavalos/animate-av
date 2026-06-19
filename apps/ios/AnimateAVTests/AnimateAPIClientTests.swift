import Foundation
import XCTest
@testable import AnimateAV

final class AnimateAPIClientTests: XCTestCase {
    override func tearDown() {
        AnimateURLProtocolMock.reset()
        unsetenv("ANIMATEAV_MOCK_NO_SPEND_FINAL_RENDER")
        super.tearDown()
    }

    func testPrepareUploadUsesSharedAccountAPIBaseURL() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "mediaAssetId": "media-1",
              "uploadId": "upload-1",
              "uploadUrl": "https://uploads.example.com/media-1",
              "method": "PUT",
              "headers": { "content-type": "image/jpeg" },
              "expiresAt": "2026-05-16T17:00:00Z",
              "generatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateUploadClient(baseURLString: accountAPIBaseURL, session: session)
        let media = AnimateSelectedMedia(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            sourceLocalIdentifier: "local-1",
            originalFilename: "photo.jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )

        _ = try await client.prepareUpload(videoId: "video-1", bearerToken: "token-1", media: media)

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/media/prepare-upload")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
    }

    func testPrepareUploadRetriesTransientNetworkLoss() async throws {
        AnimateURLProtocolMock.failuresBeforeSuccess = 1
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "mediaAssetId": "media-1",
              "uploadId": "upload-1",
              "uploadUrl": "https://uploads.example.com/media-1",
              "method": "PUT",
              "headers": { "content-type": "image/jpeg" },
              "expiresAt": "2026-05-16T17:00:00Z",
              "generatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateUploadClient(
            baseURLString: accountAPIBaseURL,
            session: session,
            networkRetryPolicy: AnimateNetworkRetryPolicy(maximumRetries: 1, baseDelayNanoseconds: 1)
        )
        let media = AnimateSelectedMedia(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
            sourceLocalIdentifier: "local-1",
            originalFilename: "photo.jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )

        _ = try await client.prepareUpload(videoId: "video-1", bearerToken: "token-1", media: media)

        XCTAssertEqual(AnimateURLProtocolMock.requestCount, 2)
    }

    func testUploadUsesPreparedURLAndHeaders() async throws {
        let session = makeMockSession(json: uploadCompletionJSON)
        let client = AnimateUploadClient(baseURLString: accountAPIBaseURL, session: session)
        let uploadURL = URL(string: "\(accountAPIBaseURL)/v1/apps/animateav/uploads/upload-1")!
        let media = AnimateSelectedMedia(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            sourceLocalIdentifier: "local-1",
            originalFilename: "photo.jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )
        let prepared = AnimatePreparedUpload(
            appId: "animateav",
            videoId: "video-1",
            mediaAssetId: "media-1",
            uploadId: "upload-1",
            uploadUrl: uploadURL,
            completionUrl: nil,
            method: "PUT",
            headers: [
                "content-type": "image/jpeg",
                "x-appsav-videos-video-id": "video-1",
                "x-appsav-videos-media-asset-id": "media-1"
            ],
            expiresAt: "2026-05-16T17:00:00Z",
            generatedAt: "2026-05-16T16:00:00Z"
        )

        _ = try await client.upload(media: media, preparedUpload: prepared)

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, uploadURL.absoluteString)
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "PUT")
        XCTAssertNil(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "x-appsav-videos-video-id"), "video-1")
    }

    func testUploadWithoutSignedURLFailsBeforeSavingMedia() async throws {
        let session = makeMockSession(json: "{}")
        let client = AnimateUploadClient(baseURLString: accountAPIBaseURL, session: session)
        let media = AnimateSelectedMedia(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            sourceLocalIdentifier: "local-1",
            originalFilename: "photo.jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )
        let prepared = AnimatePreparedUpload(
            appId: "animateav",
            videoId: "video-1",
            mediaAssetId: "media-1",
            uploadId: "upload-1",
            uploadUrl: nil,
            completionUrl: nil,
            method: "PUT",
            headers: ["content-type": "image/jpeg"],
            expiresAt: "2026-05-16T17:00:00Z",
            generatedAt: "2026-05-16T16:00:00Z"
        )

        do {
            _ = try await client.upload(media: media, preparedUpload: prepared)
            XCTFail("Expected missing upload URL to fail.")
        } catch AnimateUploadError.signedUploadUnavailable {
            XCTAssertEqual(AnimateURLProtocolMock.requestCount, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDirectUploadCompletesPreparedUploadAfterR2Put() async throws {
        let session = makeMockSession(json: uploadCompletionJSON)
        let client = AnimateUploadClient(baseURLString: accountAPIBaseURL, session: session)
        let uploadURL = URL(string: "https://account-1.r2.cloudflarestorage.com/appsav-assets-preview/animateav/user/video/source/media-1?X-Amz-Signature=test")!
        let completionURL = URL(string: "\(accountAPIBaseURL)/v1/apps/animateav/uploads/upload-1/complete")!
        let media = AnimateSelectedMedia(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            sourceLocalIdentifier: "local-1",
            originalFilename: "photo.jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )
        let prepared = AnimatePreparedUpload(
            appId: "animateav",
            videoId: "video-1",
            mediaAssetId: "media-1",
            uploadId: "upload-1",
            uploadUrl: uploadURL,
            completionUrl: completionURL,
            method: "PUT",
            headers: [
                "content-type": "image/jpeg",
                "x-amz-meta-upload-id": "upload-1"
            ],
            expiresAt: "2026-05-16T17:00:00Z",
            generatedAt: "2026-05-16T16:00:00Z"
        )

        _ = try await client.upload(media: media, preparedUpload: prepared)

        XCTAssertEqual(AnimateURLProtocolMock.requestCount, 2)
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, completionURL.absoluteString)
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
    }

    func testUploadRetriesTransientNetworkLoss() async throws {
        AnimateURLProtocolMock.failuresBeforeSuccess = 1
        let session = makeMockSession(json: uploadCompletionJSON)
        let client = AnimateUploadClient(
            baseURLString: accountAPIBaseURL,
            session: session,
            uploadRetryPolicy: AnimateUploadRetryPolicy(maximumRetries: 1, baseDelayNanoseconds: 1)
        )
        let uploadURL = URL(string: "\(accountAPIBaseURL)/v1/apps/animateav/uploads/upload-1")!
        let media = AnimateSelectedMedia(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            sourceLocalIdentifier: "local-1",
            originalFilename: "photo.jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )
        let prepared = AnimatePreparedUpload(
            appId: "animateav",
            videoId: "video-1",
            mediaAssetId: "media-1",
            uploadId: "upload-1",
            uploadUrl: uploadURL,
            completionUrl: nil,
            method: "PUT",
            headers: ["content-type": "image/jpeg"],
            expiresAt: "2026-05-16T17:00:00Z",
            generatedAt: "2026-05-16T16:00:00Z"
        )

        _ = try await client.upload(media: media, preparedUpload: prepared)

        XCTAssertEqual(AnimateURLProtocolMock.requestCount, 2)
    }

    func testVideoDirectionUsesSharedAccountAPIBaseURL() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "workflowRunId": "workflow-1",
              "status": "ready",
              "provider": "mock",
              "model": "mock",
              "moderationStatus": "allowed",
              "errorCode": null,
              "errorMessage": null,
              "narrationVoice": "avi_clear",
              "helperCopy": "Ready.",
              "scenes": [],
              "generatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateVideoDirectionClient(baseURLString: accountAPIBaseURL, session: session)

        _ = try await client.generatePlan(
            videoId: "video-1",
            ownerUserId: "user-1",
            bearerToken: "token-1",
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            mediaAssets: []
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/story/plans")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
    }

    func testVideoDirectionDoesNotRetryTransientNetworkLoss() async throws {
        AnimateURLProtocolMock.failuresBeforeSuccess = 1
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "workflowRunId": "workflow-1",
              "status": "ready",
              "provider": "mock",
              "model": "mock",
              "moderationStatus": "allowed",
              "errorCode": null,
              "errorMessage": null,
              "narrationVoice": "avi_clear",
              "helperCopy": "Ready.",
              "scenes": [],
              "generatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateVideoDirectionClient(
            baseURLString: accountAPIBaseURL,
            session: session,
            retryPolicy: AnimateNetworkRetryPolicy(maximumRetries: 1, baseDelayNanoseconds: 1)
        )

        do {
            _ = try await client.generatePlan(
                videoId: "video-1",
                ownerUserId: "user-1",
                bearerToken: "token-1",
                form: AnimateVideoSetupForm(template: .birthdayMessage),
                mediaAssets: []
            )
            XCTFail("Expected command request to fail without retrying.")
        } catch {
            XCTAssertEqual(AnimateURLProtocolMock.requestCount, 1)
        }
    }

    func testVideoDirectionSendsCurrentGuideFields() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "workflowRunId": "workflow-1",
              "status": "generated",
              "provider": "mock",
              "model": "mock",
              "moderationStatus": "allowed",
              "errorCode": null,
              "errorMessage": null,
              "narrationVoice": "none",
              "helperCopy": "Ready.",
              "scenes": [],
              "generatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateVideoDirectionClient(baseURLString: accountAPIBaseURL, session: session)
        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.movementDirection = .cinematic
        form.visualDirectionMode = .custom
        form.animationDirection = "  lanza besitos al aire  "

        _ = try await client.generatePlan(
            videoId: "video-1",
            ownerUserId: "user-1",
            bearerToken: "token-1",
            form: form,
            selectedMedia: [
                AnimateVideoDirectionMedia(
                    mediaAssetId: "media-1",
                    mediaKind: "photo",
                    sortOrder: 0,
                    selected: true,
                    moderationStatus: "approved"
                )
            ]
        )

        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["movementDirection"] as? String, "cinematic")
        XCTAssertEqual(json["motionDirection"] as? String, "cinematic")
        XCTAssertEqual(json["visualDirectionMode"] as? String, "custom")
        XCTAssertEqual(json["visualDirectionText"] as? String, "lanza besitos al aire")
        XCTAssertEqual(json["animationDirection"] as? String, "lanza besitos al aire")
        XCTAssertEqual(json["narrationVoice"] as? String, "none")
        XCTAssertEqual(json["voiceTone"] as? String, "")
    }

    func testConfirmFinalRenderDoesNotRetryTransientNetworkLoss() async throws {
        AnimateURLProtocolMock.failuresBeforeSuccess = 1
        let session = makeMockSession(json: "{}")
        let client = AnimateFinalRenderClient(
            baseURLString: accountAPIBaseURL,
            session: session,
            retryPolicy: AnimateNetworkRetryPolicy(maximumRetries: 1, baseDelayNanoseconds: 1)
        )

        do {
            _ = try await client.confirmFinalRender(
                videoId: "video-1",
                bearerToken: "token-1",
                template: .birthdayMessage,
                creationStyle: nil,
                form: AnimateVideoSetupForm(template: .birthdayMessage),
                removesWatermark: false,
                selectedSourceLocalIdentifiers: ["local-1"],
                sourceImageUploadId: "source-upload-1",
                generatedImageArtifactId: nil,
                planId: "plan-1",
                renderOptionId: "standard_video"
            )
            XCTFail("Expected command request to fail without retrying.")
        } catch {
            XCTAssertEqual(AnimateURLProtocolMock.requestCount, 1)
        }
    }

    func testPrepareRenderPlanSendsContractSafePayload() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "planId": "plan-1",
              "canCreateVideo": true,
              "createVideoBlockers": [],
              "generatedAt": "2026-05-16T16:00:00Z",
              "plan": {
                "schemaVersion": 1,
                "secondsPerCredit": 15,
                "renderOptionId": "short_video",
                "renderOptionTitle": "Short Video",
                "creationMode": "quick",
                "look": "real",
                "theme": "travel",
                "mood": "cinematic",
                "duration": "auto",
                "mediaUse": "aviPick",
                "creditCost": 1,
                "totalCreditCost": 1,
                "targetDurationMs": 15000,
                "minimumDurationMs": 8000,
                "fps": 24,
                "rendererMode": "guided_generative",
                "plannedAssetCount": 6,
                "usedAssetCount": 6,
                "rejectedAssetCount": 0,
                "qualityWarnings": [],
                "userMessage": "Ready."
              }
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)
        var form = AnimateVideoSetupForm(template: .partyRecap)
        form.theme = .travel
        form.look = .cartoon
        form.tone = .cinematic
        form.duration = .auto
        form.mediaUse = .aviPick
        form.occasion = "   "
        form.details = ""

        _ = try await client.prepareRenderPlan(
            videoId: "video-1",
            bearerToken: "token-1",
            template: .partyRecap,
            creationStyle: nil,
            form: form,
            removesWatermark: false,
            selectedSourceLocalIdentifiers: [" local-1 ", "", "local-2"],
            sourceImageUploadId: " source-upload-1 ",
            generatedImageArtifactId: " "
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/renders/plan")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["appId"] as? String, "animateav")
        XCTAssertNil(json["occasion"])
        XCTAssertNil(json["details"])
        XCTAssertNil(json["message"])
        XCTAssertNil(json["script"])
        XCTAssertNil(json["narrationVoice"])
        XCTAssertEqual(json["selectedSourceLocalIdentifiers"] as? [String], ["local-1", "local-2"])
        XCTAssertEqual(json["sourceImageUploadId"] as? String, "source-upload-1")
        XCTAssertNil(json["generatedImageArtifactId"])
        XCTAssertNil(json["creditCost"])
        XCTAssertEqual(json["startsWithSourcePhoto"] as? Bool, true)
    }

    func testPrepareRenderPlanUsesMockNoSpendEnvironmentOverride() async throws {
        setenv("ANIMATEAV_MOCK_NO_SPEND_FINAL_RENDER", "1", 1)
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "planId": "plan-1",
              "canCreateVideo": true,
              "createVideoBlockers": [],
              "generatedAt": "2026-05-16T16:00:00Z",
              "plan": {
                "schemaVersion": 1,
                "secondsPerCredit": 15,
                "renderOptionId": "short_video",
                "renderOptionTitle": "Short Video",
                "creationMode": "quick",
                "look": "real",
                "theme": "travel",
                "mood": "cinematic",
                "duration": "auto",
                "mediaUse": "aviPick",
                "creditCost": 0,
                "totalCreditCost": 0,
                "targetDurationMs": 15000,
                "minimumDurationMs": 8000,
                "fps": 24,
                "rendererMode": "guided_generative",
                "plannedAssetCount": 1,
                "usedAssetCount": 1,
                "rejectedAssetCount": 0,
                "qualityWarnings": [],
                "userMessage": "Ready."
              }
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)

        _ = try await client.prepareRenderPlan(
            videoId: "video-1",
            bearerToken: "token-1",
            template: .partyRecap,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .partyRecap),
            removesWatermark: false,
            selectedSourceLocalIdentifiers: ["local-1"],
            sourceImageUploadId: "source-upload-1",
            generatedImageArtifactId: nil
        )

        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["mockNoSpend"] as? Bool, true)
    }

    func testPrepareRenderPlanSendsCustomScriptForDurationInference() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "planId": "plan-1",
              "canCreateVideo": true,
              "createVideoBlockers": [],
              "generatedAt": "2026-05-16T16:00:00Z",
              "plan": {
                "schemaVersion": 1,
                "secondsPerCredit": 15,
                "renderOptionId": "short_video",
                "renderOptionTitle": "Short Video",
                "creationMode": "quick",
                "look": "cartoon",
                "theme": "celebration",
                "mood": "warm",
                "duration": "auto",
                "mediaUse": "aviPick",
                "creditCost": 1,
                "totalCreditCost": 1,
                "targetDurationMs": 10000,
                "fps": 24,
                "rendererMode": "image_to_video",
                "plannedAssetCount": 1,
                "usedAssetCount": 1,
                "rejectedAssetCount": 0,
                "qualityWarnings": [],
                "userMessage": "Ready."
              }
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)
        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.theme = .celebration
        form.look = .cartoon
        form.occasion = "Birthday"
        form.details = "Happy birthday, Ana. Your photo turns into a watercolor celebration."
        form.hasMessage = true
        form.voiceEnabled = true

        _ = try await client.prepareRenderPlan(
            videoId: "video-1",
            bearerToken: "token-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: form,
            removesWatermark: false,
            selectedSourceLocalIdentifiers: ["photo-1"]
        )

        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["occasion"] as? String, "Birthday")
        XCTAssertNil(json["details"])
        XCTAssertNil(json["message"])
        XCTAssertNil(json["script"])
        XCTAssertEqual(json["hasMessage"] as? Bool, true)
        XCTAssertEqual(json["messageText"] as? String, "Happy birthday, Ana. Your photo turns into a watercolor celebration.")
        XCTAssertEqual(json["voiceEnabled"] as? Bool, false)
        XCTAssertNil(json["voiceType"])
        XCTAssertNil(json["narrationVoice"])
        XCTAssertNil(json["mockNoSpend"])
        XCTAssertEqual(json["startsWithSourcePhoto"] as? Bool, true)
    }

    func testPrepareRenderPlanSendsCustomAnimationDirectionAsActionHint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "planId": "plan-1",
              "canCreateVideo": true,
              "createVideoBlockers": [],
              "generatedAt": "2026-05-16T16:00:00Z",
              "plan": {
                "schemaVersion": 1,
                "secondsPerCredit": 15,
                "renderOptionId": "short_video",
                "renderOptionTitle": "Short Video",
                "creationMode": "quick",
                "look": "cartoon",
                "theme": "celebration",
                "mood": "warm",
                "duration": "auto",
                "mediaUse": "aviPick",
                "creditCost": 1,
                "totalCreditCost": 1,
                "targetDurationMs": 10000,
                "fps": 24,
                "rendererMode": "image_to_video",
                "plannedAssetCount": 1,
                "usedAssetCount": 1,
                "rejectedAssetCount": 0,
                "qualityWarnings": [],
                "userMessage": "Ready."
              }
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)
        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.visualDirectionMode = .custom
        form.animationDirection = "  lanza besitos al aire  "

        _ = try await client.prepareRenderPlan(
            videoId: "video-1",
            bearerToken: "token-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: form,
            removesWatermark: false,
            selectedSourceLocalIdentifiers: ["photo-1"]
        )

        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["actionHint"] as? String, "lanza besitos al aire")
        XCTAssertEqual(json["visualDirectionMode"] as? String, "custom")
        XCTAssertEqual(json["visualDirectionText"] as? String, "lanza besitos al aire")
        XCTAssertEqual(json["animationDirection"] as? String, "lanza besitos al aire")
        XCTAssertNil(json["visualDirectionTemplateId"])
    }

    func testConfirmFinalRenderUsesBackendOwnedEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "planId": "plan-1",
              "reservation": {
                "id": "reservation-1",
                "appId": "animateav",
                "userId": "user-1",
                "videoId": "video-1",
                "workflowRunId": null,
                "amount": 2,
                "status": "reserved",
                "idempotencyKey": "final-confirm:video-1:birthdayMessage:watermarked:operation-1",
                "expiresAt": "2026-06-16T16:00:00Z",
                "createdAt": "2026-05-16T16:00:00Z",
                "updatedAt": "2026-05-16T16:00:00Z"
              },
              "workflow": {
                "appId": "animateav",
                "videoId": "video-1",
                "renderJobId": "render-1",
                "workflowRunId": "workflow-1",
                "status": "running",
                "startedAt": "2026-05-16T16:00:00Z"
              },
              "renderPlan": {
                "appId": "animateav",
                "videoId": "video-1",
                "planId": "plan-1",
                "canCreateVideo": true,
                "createVideoBlockers": [],
                "generatedAt": "2026-05-16T16:00:00Z",
                "plan": {
                  "schemaVersion": 1,
                  "secondsPerCredit": 15,
                  "renderOptionId": "standard_video",
                  "renderOptionTitle": "Standard Video",
                  "creationMode": "quick",
                  "look": "real",
                  "theme": "birthday",
                  "mood": "warm",
                  "duration": "auto",
                  "mediaUse": "aviPick",
                  "creditCost": 2,
                  "totalCreditCost": 2,
                  "targetDurationMs": 30000,
                  "fps": 24,
                  "rendererMode": "image_to_video",
                  "plannedAssetCount": 4,
                  "usedAssetCount": 4,
                  "rejectedAssetCount": 0,
                  "qualityWarnings": [],
                  "userMessage": "Ready."
                }
              },
              "confirmedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)

        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.details = "Happy birthday, Ana."
        form.hasMessage = true
        form.voiceEnabled = true

        let confirmation = try await client.confirmFinalRender(
            videoId: "video-1",
            bearerToken: "token-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: form,
            removesWatermark: false,
            selectedSourceLocalIdentifiers: ["local-1", "local-2"],
            sourceImageUploadId: "source-upload-1",
            generatedImageArtifactId: nil,
            planId: "plan-1",
            renderOptionId: "standard_video"
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/renders/final/confirm")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertEqual(confirmation.reservation.id, "reservation-1")
        XCTAssertEqual(confirmation.workflow.renderJobId, "render-1")
        XCTAssertEqual(confirmation.renderPlan.plan.totalCreditCost, 2)
        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["sourceImageUploadId"] as? String, "source-upload-1")
        XCTAssertNil(json["generatedImageArtifactId"])
        XCTAssertEqual(json["voiceEnabled"] as? Bool, false)
        XCTAssertNil(json["voiceType"])
        XCTAssertNil(json["narrationVoice"])
        XCTAssertNil(json["mockNoSpend"])
    }

    func testConfirmFinalRenderSendsCustomAnimationDirectionAsActionHint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "planId": "plan-1",
              "reservation": {
                "id": "reservation-1",
                "appId": "animateav",
                "userId": "user-1",
                "videoId": "video-1",
                "workflowRunId": null,
                "amount": 2,
                "status": "reserved",
                "idempotencyKey": "final-confirm:video-1:birthdayMessage:watermarked:operation-1",
                "expiresAt": "2026-06-16T16:00:00Z",
                "createdAt": "2026-05-16T16:00:00Z",
                "updatedAt": "2026-05-16T16:00:00Z"
              },
              "workflow": {
                "appId": "animateav",
                "videoId": "video-1",
                "renderJobId": "render-1",
                "workflowRunId": "workflow-1",
                "status": "running",
                "startedAt": "2026-05-16T16:00:00Z"
              },
              "renderPlan": {
                "appId": "animateav",
                "videoId": "video-1",
                "planId": "plan-1",
                "canCreateVideo": true,
                "createVideoBlockers": [],
                "generatedAt": "2026-05-16T16:00:00Z",
                "plan": {
                  "schemaVersion": 1,
                  "secondsPerCredit": 15,
                  "renderOptionId": "standard_video",
                  "renderOptionTitle": "Standard Video",
                  "creationMode": "quick",
                  "look": "real",
                  "theme": "birthday",
                  "mood": "warm",
                  "duration": "auto",
                  "mediaUse": "aviPick",
                  "creditCost": 2,
                  "totalCreditCost": 2,
                  "targetDurationMs": 30000,
                  "fps": 24,
                  "rendererMode": "image_to_video",
                  "plannedAssetCount": 4,
                  "usedAssetCount": 4,
                  "rejectedAssetCount": 0,
                  "qualityWarnings": [],
                  "userMessage": "Ready."
                }
              },
              "confirmedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)
        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.visualDirectionMode = .custom
        form.animationDirection = "lanza besitos al aire"

        _ = try await client.confirmFinalRender(
            videoId: "video-1",
            bearerToken: "token-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: form,
            removesWatermark: false,
            selectedSourceLocalIdentifiers: ["local-1"],
            sourceImageUploadId: "source-upload-1",
            generatedImageArtifactId: nil,
            planId: "plan-1",
            renderOptionId: "standard_video"
        )

        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["actionHint"] as? String, "lanza besitos al aire")
        XCTAssertEqual(json["visualDirectionMode"] as? String, "custom")
        XCTAssertEqual(json["visualDirectionText"] as? String, "lanza besitos al aire")
        XCTAssertEqual(json["animationDirection"] as? String, "lanza besitos al aire")
    }

    func testVideoQuoteUsesBackendOwnedQuoteEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "outputKind": "video",
              "duration": "upTo10s",
              "baseCreditCost": 2,
              "brandingRemovalCreditCost": 1,
              "totalCreditCost": 3,
              "proIncludesBrandingFreeVideo": false,
              "branding": {
                "enabled": true,
                "included": false,
                "removalAvailable": true,
                "removalRequested": true,
                "removalIncluded": false,
                "assetId": null,
                "placement": null,
                "reason": "branding_removal_purchased"
              }
            }
            """
        )
        let client = AnimateVideoQuoteClient(baseURLString: accountAPIBaseURL, session: session)

        let quote = try await client.quoteVideo(
            hasMessage: true,
            messageText: "Happy birthday Ana",
            removeBranding: true,
            bearerToken: "token-1"
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/video/quotes")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["appId"] as? String, "animateav")
        XCTAssertNil(json["duration"])
        XCTAssertEqual(json["hasMessage"] as? Bool, true)
        XCTAssertEqual(json["messageText"] as? String, "Happy birthday Ana")
        XCTAssertNil(json["message"])
        XCTAssertNil(json["script"])
        XCTAssertEqual(json["removeBranding"] as? Bool, true)
        XCTAssertEqual(quote.baseCreditCost, 2)
        XCTAssertEqual(quote.brandingRemovalCreditCost, 1)
        XCTAssertEqual(quote.totalCreditCost, 3)
        XCTAssertEqual(quote.branding.reason, "branding_removal_purchased")
    }

    func testImageGenerationAvailabilityUsesBackendOwnedEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "outputKind": "image",
              "monthlyProAllowance": {
                "included": true,
                "period": "2026-06",
                "allowance": 100,
                "used": 25,
                "remaining": 75
              },
              "purchasedImages": {
                "balance": 50
              },
              "availableImages": 125,
              "packOffer": {
                "enabled": true,
                "creditCost": 1,
                "imageGenerations": 50,
                "userCanPurchase": true,
                "blocker": null
              }
            }
            """
        )
        let client = AnimateImageGenerationAccountingClient(baseURLString: accountAPIBaseURL, session: session)

        let availability = try await client.fetchAvailability(bearerToken: "token-1")

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/images/availability")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "GET")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertEqual(availability.availableImages, 125)
        XCTAssertEqual(availability.monthlyProAllowance.remaining, 75)
        XCTAssertEqual(availability.purchasedImages.balance, 50)
        XCTAssertEqual(availability.packOffer.creditCost, 1)
        XCTAssertEqual(availability.packOffer.imageGenerations, 50)
    }

    func testImageGenerationStartUsesBackendOwnedEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "sourceImageUploadId": "source-upload-1",
              "sourceImageLocalIdentifier": "local-photo-1",
              "jobs": [
                {
                  "imageJobId": "convex-image-job-1",
                  "look": "cartoon",
                  "status": "queued",
                  "reservation": {
                    "idempotencyKey": "start-key-1:cartoon",
                    "monthlyReserved": 0,
                    "purchasedReserved": 1
                  }
                }
              ],
              "availability": {
                "appId": "animateav",
                "outputKind": "image",
                "monthlyProAllowance": {
                  "included": false,
                  "period": "2026-06",
                  "allowance": 0,
                  "used": 0,
                  "remaining": 0
                },
                "purchasedImages": {
                  "balance": 49
                },
                "availableImages": 49,
                "packOffer": {
                  "enabled": true,
                  "creditCost": 1,
                  "imageGenerations": 50,
                  "userCanPurchase": false,
                  "blocker": "insufficient_credits"
                }
              },
              "generatedAt": "2026-06-07T12:00:00.000Z"
            }
            """
        )
        let client = AnimateImageGenerationAccountingClient(baseURLString: accountAPIBaseURL, session: session)

        let response = try await client.startGeneration(
            sourceImageUploadId: "source-upload-1",
            looks: ["cartoon"],
            idempotencyKey: "start-key-1",
            bearerToken: "token-1"
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/images/generations")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["sourceImageUploadId"] as? String, "source-upload-1")
        XCTAssertEqual(json["looks"] as? [String], ["cartoon"])
        XCTAssertEqual(json["idempotencyKey"] as? String, "start-key-1")
        XCTAssertEqual(response.sourceImageUploadId, "source-upload-1")
        XCTAssertEqual(response.jobs.first?.imageJobId, "convex-image-job-1")
        XCTAssertEqual(response.availability.availableImages, 49)
    }

    func testImageGenerationStartDoesNotRetryTransientNetworkLoss() async throws {
        AnimateURLProtocolMock.failuresBeforeSuccess = 1
        let session = makeMockSession(json: "{}")
        let client = AnimateImageGenerationAccountingClient(
            baseURLString: accountAPIBaseURL,
            session: session,
            retryPolicy: AnimateNetworkRetryPolicy(maximumRetries: 1, baseDelayNanoseconds: 1)
        )

        do {
            _ = try await client.startGeneration(
                sourceImageUploadId: "source-upload-1",
                looks: ["cartoon"],
                idempotencyKey: "start-key-1",
                bearerToken: "token-1"
            )
            XCTFail("Expected command request to fail without retrying.")
        } catch {
            XCTAssertEqual(AnimateURLProtocolMock.requestCount, 1)
        }
    }

    func testSourceImagePrepareUploadUsesBackendOwnedEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "sourceImageUploadId": "source-upload-1",
              "uploadId": "source-upload-1",
              "uploadUrl": "https://api.example.test/v1/apps/animateav/images/source-uploads/source-upload-1",
              "method": "PUT",
              "headers": { "Content-Type": "image/jpeg" },
              "expiresAt": "2026-06-08T12:00:00.000Z",
              "generatedAt": "2026-06-07T12:00:00.000Z"
            }
            """
        )
        let client = AnimateImageGenerationAccountingClient(baseURLString: accountAPIBaseURL, session: session)

        let prepared = try await client.prepareSourceImageUpload(
            sourceLocalIdentifier: "local-photo-1",
            originalFilename: "animate-source.jpg",
            contentType: "image/jpeg",
            byteSize: 4,
            sha256: "0000000000000000000000000000000000000000000000000000000000000000",
            width: 100,
            height: 200,
            bearerToken: "token-1"
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/images/source-uploads/prepare")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["sourceLocalIdentifier"] as? String, "local-photo-1")
        XCTAssertEqual(json["contentType"] as? String, "image/jpeg")
        XCTAssertEqual(json["byteSize"] as? Int, 4)
        XCTAssertEqual(prepared.sourceImageUploadId, "source-upload-1")
    }

    func testSourceImageUploadUsesPreparedUploadEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "sourceImageUploadId": "source-upload-1",
              "uploadId": "source-upload-1",
              "sourceLocalIdentifier": "local-photo-1",
              "contentType": "image/jpeg",
              "width": 100,
              "height": 200,
              "status": "uploaded",
              "uploadedAt": "2026-06-07T12:00:00.000Z",
              "bytesReceived": 4
            }
            """
        )
        let client = AnimateImageGenerationAccountingClient(baseURLString: accountAPIBaseURL, session: session)
        let prepared = AnimateSourceImagePreparedUpload(
            appId: "animateav",
            sourceImageUploadId: "source-upload-1",
            uploadId: "source-upload-1",
            uploadUrl: "\(accountAPIBaseURL)/v1/apps/animateav/images/source-uploads/source-upload-1",
            method: "PUT",
            headers: ["Content-Type": "image/jpeg"],
            expiresAt: "2026-06-08T12:00:00.000Z",
            generatedAt: "2026-06-07T12:00:00.000Z"
        )

        let uploaded = try await client.uploadSourceImage(data: Data([1, 2, 3, 4]), preparedUpload: prepared)

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/images/source-uploads/source-upload-1")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "PUT")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "image/jpeg")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequestBody, Data([1, 2, 3, 4]))
        XCTAssertEqual(uploaded.sourceImageUploadId, "source-upload-1")
        XCTAssertEqual(uploaded.bytesReceived, 4)
    }

    func testImageGenerationPackPurchaseUsesBackendOwnedEndpoint() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "outputKind": "image",
              "monthlyProAllowance": {
                "included": false,
                "period": "2026-06",
                "allowance": 0,
                "used": 0,
                "remaining": 0
              },
              "purchasedImages": {
                "balance": 50
              },
              "availableImages": 50,
              "packOffer": {
                "enabled": true,
                "creditCost": 1,
                "imageGenerations": 50,
                "userCanPurchase": false,
                "blocker": "already_available"
              },
              "purchase": {
                "creditReservationId": "credit-reservation-1",
                "creditCost": 1,
                "imageGenerationsAdded": 50,
                "idempotencyKey": "pack-key-1",
                "createdAt": "2026-06-07T12:00:00.000Z"
              }
            }
            """
        )
        let client = AnimateImageGenerationAccountingClient(baseURLString: accountAPIBaseURL, session: session)

        let response = try await client.purchasePack(
            idempotencyKey: "pack-key-1",
            bearerToken: "token-1"
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/images/packs/purchase")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        let body = try XCTUnwrap(AnimateURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["idempotencyKey"] as? String, "pack-key-1")
        XCTAssertEqual(response.purchase.imageGenerationsAdded, 50)
        XCTAssertEqual(response.purchase.creditCost, 1)
        XCTAssertEqual(response.availability.availableImages, 50)
    }

    func testPrepareFinalArtifactDownloadAcceptsPublicSafeResponseWithoutR2Key() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "artifactId": "artifact-1",
              "artifactKind": "final_export",
              "downloadUrl": "https://account-1.r2.cloudflarestorage.com/videos-bucket/animateav/user/video-1/final%20exports/artifact-1.mp4?X-Amz-Signature=test",
              "method": "GET",
              "headers": {},
              "expiresAt": "2026-05-16T17:00:00Z",
              "generatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateFinalRenderClient(baseURLString: accountAPIBaseURL, session: session)

        let response = try await client.prepareFinalArtifactDownload(
            videoId: "video-1",
            artifactId: "artifact-1",
            bearerToken: "token-1"
        )

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/artifacts/artifact-1/download")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertNil(response.r2Key)
        XCTAssertEqual(response.artifactKind, "final_export")
    }

    func testRenderStatusUsesSharedAccountAPIBaseURL() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "videoId": "video-1",
              "renderJobId": "render-1",
              "workflowRunId": "workflow-1",
              "renderKind": "final",
              "status": "running",
              "progressPercent": 25,
              "artifactId": null,
              "artifactKind": null,
              "artifactStatus": null,
              "errorCode": null,
              "errorMessage": null,
              "updatedAt": "2026-05-16T16:00:00Z"
            }
            """
        )
        let client = AnimateRenderStatusClient(baseURLString: accountAPIBaseURL, session: session)

        let status = try await client.fetchStatus(renderJobId: "render-1", bearerToken: "token-1")

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/renders/render-1/status")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "GET")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertEqual(status.status, "running")
        XCTAssertEqual(status.progressPercent, 25)
    }

    func testRenderStatusSurfacesAPIErrorMessage() async throws {
        let session = makeMockSession(
            statusCode: 404,
            json: """
            {
              "error": {
                "code": "videos_render_not_found",
                "message": "Render job was not found."
              }
            }
            """
        )
        let client = AnimateRenderStatusClient(baseURLString: accountAPIBaseURL, session: session)

        do {
            _ = try await client.fetchStatus(renderJobId: "missing-render", bearerToken: "token-1")
            XCTFail("Expected API error")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Render job was not found.")
        }
    }

    func testCreditBalanceUsesBackendBucketsAndBearerToken() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "userId": "user-1",
              "spendableCredits": 10,
              "reservedCredits": 0,
              "proMonthlyCredits": 0,
              "promotionalGrantedCredits": 10,
              "purchasedCredits": 0,
              "hasProFeatures": true,
              "proSource": "promo",
              "proExpiresAt": "2026-06-25T00:00:00.000Z",
              "canStartVideo": true,
              "minimumRenderCredits": 1,
              "generatedAt": "2026-05-26T10:00:00.000Z"
            }
            """
        )
        let client = AnimateCreditBalanceClient(baseURLString: accountAPIBaseURL, session: session)

        let balance = try await client.fetchBalance(bearerToken: "token-1")

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/credits/balance")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "GET")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertEqual(balance, AnimateCreditBalance(proMonthly: 0, promotional: 10, purchased: 0, availableCredits: 10))
    }

    func testPromoCodeRedeemUsesBackendAndReturnsUpdatedBalance() async throws {
        let session = makeMockSession(
            json: """
            {
              "appId": "animateav",
              "userId": "user-1",
              "code": "MOMENTS-DEMO-2026",
              "campaignId": "demo_credit_flow",
              "creditsGranted": 5,
              "redemptionId": "promo-redemption-1",
              "ledgerEntryId": "promo-ledger-1",
              "balance": {
                "appId": "animateav",
                "userId": "user-1",
                "spendableCredits": 5,
                "reservedCredits": 0,
                "proMonthlyCredits": 0,
                "promotionalGrantedCredits": 5,
                "purchasedCredits": 0,
                "hasProFeatures": false,
                "proSource": "none",
                "proExpiresAt": null,
                "canStartVideo": true,
                "minimumRenderCredits": 1,
                "generatedAt": "2026-05-27T10:00:00.000Z"
              },
              "generatedAt": "2026-05-27T10:00:00.000Z"
            }
            """
        )
        let client = AnimatePromoCodeClient(baseURLString: accountAPIBaseURL, session: session)

        let response = try await client.redeem(code: "MOMENTS-DEMO-2026", bearerToken: "token-1")

        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.url?.absoluteString, "\(accountAPIBaseURL)/v1/apps/animateav/credits/promotions/redeem")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(AnimateURLProtocolMock.lastRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer token-1")
        XCTAssertEqual(response.creditsGranted, 5)
        XCTAssertEqual(response.balance, AnimateCreditBalance(proMonthly: 0, promotional: 5, purchased: 0, availableCredits: 5))
    }

    private var accountAPIBaseURL: String {
        "https://api-account-av-preview.avalsys.com"
    }

    private var uploadCompletionJSON: String {
        """
        {
          "appId": "animateav",
          "videoId": "video-1",
          "mediaAssetId": "media-1",
          "uploadId": "upload-1",
          "storageKey": "uploads/video-1/media-1.jpg",
          "status": "uploaded",
          "uploadedAt": "2026-05-16T16:00:00Z",
          "bytesReceived": 4
        }
        """
    }

    private func makeMockSession(statusCode: Int = 200, json: String) -> URLSession {
        AnimateURLProtocolMock.statusCode = statusCode
        AnimateURLProtocolMock.responseData = Data(json.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateURLProtocolMock.self]
        return URLSession(configuration: configuration)
    }
}

private final class AnimateURLProtocolMock: URLProtocol {
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var responseData = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastRequestBody: Data?
    nonisolated(unsafe) static var requestCount = 0
    nonisolated(unsafe) static var failuresBeforeSuccess = 0

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastRequestBody = request.httpBody
        if Self.lastRequestBody == nil,
           let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let read = stream.read(buffer, maxLength: bufferSize)
                if read <= 0 { break }
                data.append(buffer, count: read)
            }
            Self.lastRequestBody = data
        }
        Self.requestCount += 1
        if Self.failuresBeforeSuccess > 0 {
            Self.failuresBeforeSuccess -= 1
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
            return
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["content-type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        statusCode = 200
        responseData = Data()
        lastRequest = nil
        lastRequestBody = nil
        requestCount = 0
        failuresBeforeSuccess = 0
    }
}
