# BettrAI

AI 계약과 Firebase Gemini 구현을 소유하는 로컬 Swift Package입니다.
앱은 이 패키지를 가져오며, BettrAI는 앱·SwiftUI·GRDB를 가져오지 않습니다.
경계 정책은 [ADR 0003](../../docs/decisions/0003-ai-module-boundary.md)을 따릅니다.

## 공개 API

| 타입 | 역할 |
| --- | --- |
| `ScriptAnalyzing` | `analyzeScript(_:) async throws -> ScriptData` |
| `WordExtracting` | `extractWords(from:) async throws -> [WordData]` |
| `FirebaseGeminiAdapter` | 두 프로토콜의 실제 구현. 공개 `init()`으로 조립 |
| `ScriptData`, `SentenceData`, `ChunkData`, `WordData` | 공개 생성자와 프로퍼티를 가진 결과 값 |
| `AIError` | 취소·인증·호출 제한·일시 장애·입력·응답 계약·알 수 없는 실패 |

입력은 `String`이며 프로토콜과 Adapter는 `@MainActor`입니다. 결과 DTO와
오류는 `nonisolated`, `Sendable`입니다. Swift 5 언어 모드와 명시적 actor
격리를 사용하므로 앱 타깃의 기본 MainActor 설정에 의존하지 않습니다.
프롬프트·파서·SDK 오류 분류·재시도 및 테스트 주입 생성자는 내부 API입니다.
공개 계약에는 Firebase SDK 타입을 노출하지 않습니다.

```swift
import BettrAI

@MainActor
func makeAnalyzer() -> any ScriptAnalyzing {
    FirebaseGeminiAdapter()
}
```

## 의존성과 초기화

- Swift tools 6.2 이상, iOS 26 이상. macOS 13 이상은 앱 호스트 없는 테스트를 지원합니다.
- 외부 의존성은 Firebase iOS SDK **12.6.0**의 `FirebaseAILogic` 제품입니다.
  `Package.swift`의 정확한 버전과 `Package.resolved`를 함께 관리합니다.
  앱의 FirebaseCore/AppCheck도 동일한 SDK 버전으로 해석되어야 합니다.
- Firebase/AppCheck 초기화와 설정 파일은 앱의 `FirebaseBootstrap` 책임입니다.
  생성자는 SDK 모델을 만들지 않으며 최초 유효한 요청에서 생성합니다.
- `gemini-2.5-flash-lite`, 기존 프롬프트, 오류 분류와 최대 두 번의 재시도 정책을
  유지합니다. DB 변환·저장·화면 상태·요청별 사용량 제한은 앱 책임입니다.
- 패키지는 직접 로그를 출력하지 않습니다. 앱에서 정해진 오류 범주만 기록합니다.

Firebase SDK를 링크하므로 초기 의존성 다운로드에는 네트워크가 필요합니다.
순수 테스트 실행에는 Firebase 설정·App Check 토큰·실제 AI 호출이 필요하지 않습니다.

## 독립 테스트

저장소 루트에서 CI와 동일한 검증 runner를 실행합니다. `--results`는 매번 새
경로를 사용하고 `--scratch-path`는 재사용할 수 있습니다.

```bash
scripts/bettr-ai-test.sh \
  --scratch-path /tmp/bettr-ai-build \
  --results /tmp/bettr-ai-results-1
```

`swift test`는 추적된 lockfile을 강제 사용합니다. 파서·검증·오류 분류·취소·재시도와
Fake 응답을 사용하는 Adapter 테스트, 공개 API의 actor 간 DTO 전달을 검증합니다.
runner는 실행 실패·로그 저장 실패·테스트 0개·skip·성공 요약 누락을 실패로 처리합니다.
runner 자체의 회귀 검사는 `bash scripts/tests/bettr-ai-test.sh`입니다.

앱 `Default` Test Plan에도 `BettrAITests`가 포함됩니다. 앱의 DB 통합·기능 테스트는
기존 BettrTests에 남습니다. 실제 네트워크 검증은 이 패키지 테스트에 섞지 않고
[GeminiContract runner](../../docs/testing/gemini-contract.md)로 별도 실행합니다.
실제 계약 테스트는 앱의 Firebase Bootstrap과 패키지의 운영 Adapter·프롬프트·파서를
함께 검증합니다.

## CI 영향 범위

모든 PR에서 독립 패키지 테스트와 앱 Default/UI 검증을 실행합니다.
실제 Gemini CI는 `BettrAI/**`와 앱 Bootstrap·사용량 제한·SDK lockfile·Test Plan·계약
테스트·전용 runner/workflow 변경을 감지합니다. 순수 UI·GRDB 변경만으로는 실행하지
않으며 nightly/manual/release 실행은 유지합니다. 영향 경로의 기준은
`scripts/gemini-contract/impact.py`와 workflow이며 회귀 검사가 두 목록의 일치를 확인합니다.
