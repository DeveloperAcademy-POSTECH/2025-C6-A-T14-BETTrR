# Bettr 테스트 가이드

테스트를 변경하기 전에 `../AGENTS.md`를 읽습니다.

## 테스트 계층

앱 테스트는 외부 의존성에 따라 세 계층으로 구분합니다. AI 순수 테스트는
[BettrAI 패키지](../BettrAI/README.md)의 `Tests/BettrAITests/`에 둡니다.

| 계층 | 디렉터리 | 허용 의존성 | Firebase 설정 필요 | 실행 시점 |
| --- | --- | --- | --- | --- |
| Unit | `Unit/` | 없음 (메모리 내 순수 로직) | 없음 | 모든 PR, 로컬 `Cmd+U` |
| DatabaseIntegration | `DatabaseIntegration/` | in-memory GRDB만 | 없음 | 모든 PR, 로컬 `Cmd+U` |
| GeminiContract | `GeminiContract/` | 실제 네트워크, Firebase, 과금 | 필요 | 명시적 선택 시에만 |

- 메모리 안에서 입력과 출력만 검증하는 순수 로직 테스트는 `Unit/`에 둡니다.
- in-memory `GRDB DatabaseQueue()`를 사용하는 테스트는 `DatabaseIntegration/`에
  둡니다.
- 실제 Gemini 요청을 보내는 테스트는 `GeminiContract/`에 둡니다. 이런 테스트를
  Unit이나 DatabaseIntegration에 추가하지 않습니다.

## Test Plan

- `../TestPlans/Default.xctestplan`은 Unit, DatabaseIntegration과 BettrAITests를
  실행합니다. `GoogleService-Info.plist` 없이 동작해야 합니다.
- `../TestPlans/GeminiContract.xctestplan`은 실제 Firebase와 Gemini 호출을 위한
  명시적 Contract Test Plan입니다. 인증 정보와 비용 발생이 의도된 경우에만
  실행합니다.
- 일반 로컬 검증과 PR CI에는 Default Plan을 사용합니다.

## Default CI

- `.github/workflows/ios-default.yml`의 `iOS Default` workflow는 `dev`와 `main`
  대상 PR 및 `dev` push에서 Default Plan을 실행합니다.
- CI는 독립 BettrAI 테스트와 iPad Simulator의 Default/UI 테스트를 수행합니다.
  GeminiContract Test Plan, Firebase plist, App Check token, Gemini 호출은 포함하지
  않습니다.
- 앱 SPM cache는 앱과 BettrAI의 `Package.resolved`로 무효화됩니다. 앱 DerivedData와
  simulator data는 cache하지 않습니다. 독립 패키지 job은 SwiftPM scratch 경로를 cache합니다.

Xcode에서는 `Cmd+U`로 기본 Plan(Default)을 실행합니다. 다른 Plan은 Product >
Test Plan에서 선택합니다. 터미널과 CI에서는 다음 명령을 사용합니다.

```bash
xcodebuild test \
  -project Bettr/Bettr.xcodeproj \
  -scheme Bettr \
  -testPlan Default \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' \
  CODE_SIGNING_ALLOWED=NO
```

## Firebase 초기화

- 앱이 테스트 호스트로 실행될 때 `AppDelegate`는 Firebase 초기화를 건너뜁니다.
- 따라서 Default Plan은 `GoogleService-Info.plist` 없이 실행되어야 합니다.
- GeminiContract 테스트는 테스트 코드에서 Firebase를 직접 초기화하며, 로컬에서는
  커밋하지 않는 `GoogleService-Info.plist`를 사용합니다.

## GeminiContract 실행과 CI

- 실제 호출의 환경·초기화·호출 예산·실패 분류·증거 기준은
  [GeminiContract 실행 문서](../../docs/testing/gemini-contract.md)를 따릅니다.
- Default Plan은 `GeminiContractTests`를 제외합니다. 실제 호출 테스트 클래스나
  시나리오를 바꾸면 두 Test Plan과 전용 runner의 선택·성공 조건도 갱신합니다.
- Debug Provider는 테스트 코드에서만 구성합니다. 운영 Firebase Bootstrap을
  Debug Provider로 변경하지 않습니다.
