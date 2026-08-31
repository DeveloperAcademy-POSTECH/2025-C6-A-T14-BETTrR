# Bettr 테스트 가이드

테스트를 변경하기 전에 `../AGENTS.md`를 읽습니다.

## 테스트 계층

테스트는 외부 의존성에 따라 세 계층으로 구분합니다.

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

- `../TestPlans/Default.xctestplan`은 Unit과 DatabaseIntegration 테스트를
  실행합니다. `GoogleService-Info.plist` 없이 동작해야 합니다.
- `../TestPlans/GeminiContract.xctestplan`은 실제 Firebase와 Gemini 호출을 위한
  명시적 Contract Test Plan입니다. 인증 정보와 비용 발생이 의도된 경우에만
  실행합니다.
- 일반 로컬 검증과 PR CI에는 Default Plan을 사용합니다.

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

## GeminiContract CI

- `GoogleService-Info.plist`는 계속 Git에 커밋하지 않습니다.
- GeminiContract workflow에서는 `GOOGLE_SERVICE_INFO_PLIST_BASE64` secret을
  `Bettr/Bettr/GoogleService-Info.plist`로 복원합니다.
- Secret 값이나 복원한 plist 내용은 workflow 로그에 출력하지 않습니다.
