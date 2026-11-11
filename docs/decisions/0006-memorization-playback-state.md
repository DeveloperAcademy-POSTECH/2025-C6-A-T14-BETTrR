# 암기 화면 재생 상태의 단일 소유권

- 날짜: 2026-11-10
- 상태: 채택 — 설계 원칙이며 구현 완료는 관련 이슈에서 추적한다.
- 관련 이슈: [#320](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/320), [#292](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/292)
- 관련 결정: [0002](0002-feature-state-contract.md), [0005](0005-recording-session-workflow.md)

## 배경

재생 상태가 `AudioPlaybackService`와 `MemorizationUIState`(`isPlaybackActive`,
`isPause`)에 중복되었고, View의 `onChange`가 둘을 맞췄다. `isPaused`는 관찰되지 않는
합성기 값을 읽어 UI가 서비스의 일시정지를 알 수 없었다. 전체/부분 재생 상호
배제와 모달 정지 규칙은 View 클로저에 흩어져 테스트할 수 없었고, 스크립트 로딩은
View가 만든 비구조화 `Task`로 실행되어 화면 이탈 뒤 늦은 결과가 상태를 바꿨다.

## 결정

**재생 상태의 소유자는 `AudioPlaybackService` 하나다.** 기준 상태는
`AudioPlaybackServiceProtocol`의 `currentPlaybackMode`, `currentPlaybackID`,
`currentMultiSentenceIndex`, `currentSpokenRange`, `isPaused`, `isPlaybackActive`이며
각 의미는 프로토콜 주석이 정의한다. 나머지는 복사하지 않고 파생한다.

| 파생 상태 | 규칙 | 위치 |
| --- | --- | --- |
| 전체 재생 중 (툴바 일시정지/정지 컨트롤) | `mode == .multi` | `MemorizationViewModel.isFullPlaybackActive` |
| 부분 재생 중 (모드 전환·전체 재생 잠금) | `mode == .single` | `isSinglePlaybackActive` |
| 일시정지 아이콘 | `service.isPaused` | `isPlaybackPaused` |
| 문장·청크 강조 | `currentPlaybackID`, `currentMultiSentenceIndex`, `currentSpokenRange` | `EnglishScriptTextView` |

- 재생 대상은 텍스트가 아니라 `PlaybackTargetID`로 구분한다. 텍스트가 같아도 ID가
  다르면 다른 대상이며, 같은 ID를 다시 탭할 때만 정지한다. 텍스트 기반
  `currentSpokenTextID`는 제거했다.
- 서비스는 현재 발화와 일치하는 합성기 이벤트만 반영한다. 이전 재생의 늦은
  시작·종료·취소 이벤트는 새 대상의 상태를 바꾸지 못한다. 문장 사이 대기 Task는
  정지·전환·일시정지 시 취소한다. 일시정지는 대기 중에도 유효하며 재개하면 다음
  문장부터 시작한다.
- 합성기는 `SpeechSynthesizing` 경계 뒤에 두어 Fake가 이벤트를 원하는 순서와
  시점에 공급한다. 실제 구현은 `SystemSpeechSynthesizer`다.
- 정지 규칙은 ViewModel 의도에 둔다: 부분 재생 중에는 전체 재생·모드 전환이,
  전체 재생 중에는 부분 재생 모드가 토스트와 함께 거부된다. 피드백 모달을 열면 정지하고,
  화면 이탈은 정지한다. 단어장 오버레이는 재생을 멈추지 않으며 위 잠금 규칙도 그대로 적용된다.
- 스크립트 로딩 Task의 소유자는 `MemorizationViewModel`이다. 진입·재시도는 이전
  로딩을 취소하고, 화면 이탈은 로딩과 재시도 대기를 취소한다. 마지막 요청의 결과만
  반영하고 취소·대체된 요청의 성공·실패는 무시한다. 단어 로딩은
  `WordListViewModel`이 같은 방식으로 소유한다.

## 대안과 보류 이유

- ViewModel을 재생 상태의 소유자로 두고 서비스를 단순 실행기로 만들기: 합성기
  이벤트가 서비스에서 먼저 도착하므로 동기화 경로가 다시 생긴다.
- 상태를 하나의 enum(`idle/single/all`)으로 재모델링: 강조 View 전반의 변경이 커지고
  이번 이슈의 문제(중복·경쟁)는 소유자 정리로 해결된다. 필요해지면 서비스 내부에서 바꾼다.
- 전면 MVI·Feature 모듈 추출: 이슈 범위 밖이다.

## 결과와 비용

동기화 콜백이 없어지고 늦은 이벤트의 영향 범위가 서비스 한 곳으로 줄어든다.
`SpeechSynthesizing` Fake와 보류형 저장소 Fake를 유지해야 한다. 문장 사이 대기 중
일시정지가 처음으로 실제로 동작한다.

## 검증

`AudioPlaybackServiceTests`, `MemorizationPlaybackTests`, `MemorizationLoadingTests`가
기기 없이 위 규칙을 검증한다. 실제 iPad 재생 acceptance 결과는 #320 PR에 남긴다.
