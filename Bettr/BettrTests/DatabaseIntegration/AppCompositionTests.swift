import Foundation
import Observation
import XCTest
@testable import Bettr

@MainActor
final class AppCompositionTests: XCTestCase {
    func test_previewComposition_whenCreatedTwice_thenKeepsDatabasesIsolated() async throws {
        let first = try PreviewComposition.make()
        let second = try PreviewComposition.make()
        let firstView = first.makeMemorizationView(scriptId: 1, scriptTitle: "First")
        let created = try await firstView.viewModel.scriptService.createScript(scriptData: scriptData())
        let firstHome = first.makeHomeListModel()
        let secondHome = second.makeHomeListModel()

        await firstHome.refresh()
        await secondHome.refresh()

        XCTAssertEqual(firstHome.scripts?.map(\.id), [try XCTUnwrap(created.id)])
        XCTAssertTrue(try XCTUnwrap(secondHome.scripts).isEmpty)
        XCTAssertNil(firstHome.errorMessage)
        XCTAssertNil(secondHome.errorMessage)
    }

    func test_memorizationFactory_whenWordExtractorIsInjected_thenLoadsItsPersistedWords() async throws {
        let extractor = CompositionFakeWordExtractor()
        let composition = try PreviewComposition.make(wordExtractor: extractor)
        let writer = composition.makeMemorizationView(scriptId: 1, scriptTitle: "Fixture")
        let created = try await writer.viewModel.scriptService.createScript(scriptData: scriptData())
        let scriptId = try XCTUnwrap(created.id)
        let view = composition.makeMemorizationView(scriptId: scriptId, scriptTitle: created.title)

        await view.wordListViewModel.loadWords()

        XCTAssertEqual(extractor.inputs, ["A useful challenge."])
        XCTAssertEqual(view.wordListViewModel.words.map(\.lemma), ["useful", "challenge"])
        XCTAssertEqual(view.wordListViewModel.words.map(\.orderIndex), [0, 1])
        XCTAssertNil(view.wordListViewModel.errorMessage)
        XCTAssertFalse(view.wordListViewModel.isLoading)

        let anotherView = composition.makeMemorizationView(scriptId: scriptId, scriptTitle: created.title)
        await anotherView.wordListViewModel.loadWords()
        XCTAssertEqual(anotherView.wordListViewModel.words.map(\.lemma), ["useful", "challenge"])
        XCTAssertEqual(extractor.inputs.count, 1, "Saved words must be reused by a new screen")
    }

    func test_memorizationFactory_whenAudioIsInjected_thenSharesObservableInstance() async throws {
        let fakeAudio = CompositionFakeAudioPlayback()
        let composition = try PreviewComposition.make(audioService: fakeAudio)
        let first = composition.makeMemorizationView(scriptId: 1, scriptTitle: "First")
        let second = composition.makeMemorizationView(scriptId: 2, scriptTitle: "Second")

        XCTAssertTrue(first.viewModel.audioService === fakeAudio)
        XCTAssertTrue(second.viewModel.audioService === fakeAudio)
        XCTAssertTrue(first.viewModel.audioService === second.viewModel.audioService)

        let audio: any AudioPlaybackServiceProtocol = first.viewModel.audioService
        let playbackChanged = expectation(description: "Playback activity observed through protocol")
        let rangeChanged = expectation(description: "Spoken range observed through protocol")
        withObservationTracking {
            _ = audio.isPlaybackActive
        } onChange: {
            playbackChanged.fulfill()
        }
        withObservationTracking {
            _ = audio.currentSpokenRange
        } onChange: {
            rangeChanged.fulfill()
        }

        fakeAudio.isPlaybackActive = true
        fakeAudio.currentSpokenRange = NSRange(location: 2, length: 4)

        await fulfillment(of: [playbackChanged, rangeChanged], timeout: 1)
        XCTAssertTrue(second.viewModel.audioService.isPlaybackActive)
        XCTAssertEqual(second.viewModel.audioService.currentSpokenRange, NSRange(location: 2, length: 4))
    }

    func test_testHostLaunchContext_thenCreatesAnIsolatedEmptyComposition() async throws {
        XCTAssertTrue(AppLaunchContext.usesIsolatedDependencies)
        let composition = try AppLaunchContext.makeComposition()
        let home = composition.makeHomeListModel()

        await home.refresh()

        XCTAssertTrue(try XCTUnwrap(home.scripts).isEmpty)
        XCTAssertNil(home.errorMessage)
        XCTAssertFalse(home.isLoading)
    }

    func test_scriptConfirmFactory_thenPreservesASCIIFilterAndCharacterLimit() throws {
        let composition = try PreviewComposition.make()
        let asciiContent = "Hello 123!\n" + String(repeating: "x", count: 2000)
        let view = composition.makeScriptConfirmView(
            initialText: "한국어🙂" + asciiContent,
            initialTitle: "입력 제목"
        )

        XCTAssertEqual(view.scriptContent, String(asciiContent.prefix(2000)))
        XCTAssertEqual(view.scriptTitle, "입력 제목")

        let emptyView = composition.makeScriptConfirmView(initialText: nil, initialTitle: nil)
        XCTAssertEqual(emptyView.scriptContent, "")
        XCTAssertEqual(emptyView.scriptTitle, "")
    }

    private func scriptData() -> ScriptData {
        ScriptData(title: "Composition fixture", sentences: [
            SentenceData(
                orderIndex: 0,
                englishText: "A useful challenge.",
                koreanText: "유익한 도전.",
                chunks: [ChunkData(
                    orderIndex: 0,
                    englishText: "A useful challenge.",
                    koreanText: "유익한 도전."
                )]
            )
        ])
    }
}

@MainActor
private final class CompositionFakeWordExtractor: WordExtracting {
    private(set) var inputs: [String] = []

    func extractWords(from content: String) async throws -> [WordData] {
        inputs.append(content)
        return [
            WordData(lemma: "useful", pos: "형", meaning: "유익한"),
            WordData(lemma: "challenge", pos: "명", meaning: "도전")
        ]
    }
}

@MainActor
@Observable
private final class CompositionFakeAudioPlayback: AudioPlaybackServiceProtocol {
    var isPlaybackActive = false
    var isPaused = false
    var currentPlaybackMode = PlaybackMode.stopped
    var currentSpokenTextID: String?
    var currentPlaybackID: PlaybackTargetID?
    var currentMultiSentenceIndex: Int?
    var currentSpokenRange: NSRange?

    func play(text: String, id: PlaybackTargetID, language: String) {}
    func playAll(sentences: [SentenceData], language: String) {}
    func stop() {}
    func pause() {}
    func resume() {}
}
