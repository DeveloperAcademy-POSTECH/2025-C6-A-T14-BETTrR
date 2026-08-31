# 테스트 가이드

## 테스트 계층

테스트는 외부 의존성에 따라 세 계층으로 구분합니다.

| 계층 | 디렉터리 | 허용 의존성 | Firebase 설정 필요 | 실행 시점 |
|---|---|---|---|---|
| Unit | `Bettr/BettrTests/Unit/` | 없음 (메모리 내 순수 로직) | ❌ | 모든 PR, 로컬 `Cmd+U` |
| DatabaseIntegration | `Bettr/BettrTests/DatabaseIntegration/` | in-memory GRDB만 | ❌ | 모든 PR, 로컬 `Cmd+U` |
| GeminiContract | (#297에서 추가 예정) | 실제 네트워크 + Firebase + 과금 | ✅ | 명시적 선택 시에만 (nightly, 릴리스 전) |

새 테스트를 추가할 때 판단 기준:

- 네트워크·DB 없이 입력→출력만 검증하면 **Unit**
- GRDB `DatabaseQueue()`(in-memory)를 사용하면 **DatabaseIntegration**
- 실제 Gemini API를 호출하면 **GeminiContract** — 절대 Unit/DatabaseIntegration에 넣지 않습니다

## Test Plan

Test Plan 파일은 `Bettr/TestPlans/`에 있으며 Bettr scheme에 연결되어 있습니다.

| Plan | 포함 테스트 | 용도 |
|---|---|---|
| `Default.xctestplan` (기본) | BettrTests 전체 (Unit + DatabaseIntegration) | 로컬 `Cmd+U`, PR CI |
| `GeminiContract.xctestplan` | 현재 비어 있음 (#297에서 채움) | 실제 Gemini 호출 검증 |

## 실행 방법

### Xcode

`Cmd+U` — 기본 Plan(Default)이 실행됩니다. 다른 Plan은 Product > Test Plan에서 선택합니다.

### 터미널 / CI

```bash
xcodebuild test \
  -project Bettr/Bettr.xcodeproj \
  -scheme Bettr \
  -testPlan Default \
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4)' \
  CODE_SIGNING_ALLOWED=NO
```

## Firebase 초기화 정책

- 앱이 테스트 호스트로 실행될 때는 `AppDelegate`가 Firebase 초기화를 건너뜁니다
  (`NSClassFromString("XCTestCase")` 감지 — `BettrApp.swift` 참고).
- 따라서 `GoogleService-Info.plist` 없이도 Default Plan을 실행할 수 있습니다.
- GeminiContract 테스트(#297)는 테스트 코드에서 직접 Firebase를 초기화해야 하며,
  로컬에서는 커밋되지 않은 `GoogleService-Info.plist`를 사용합니다.

## GeminiContract CI 설정

- `GoogleService-Info.plist`는 로컬 전용 파일이며 계속 Git에 커밋하지 않습니다.
- #297에서 GeminiContract workflow를 추가할 때는 `GOOGLE_SERVICE_INFO_PLIST_BASE64` GitHub Secret을
  `Bettr/Bettr/GoogleService-Info.plist`로 복원합니다.
- Secret 값이나 복원된 파일 내용은 workflow 로그에 출력하지 않습니다.
