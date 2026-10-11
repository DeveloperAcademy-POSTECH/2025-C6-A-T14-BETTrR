# 실제 Gemini 계약 검증

`GeminiContract`는 실제 Firebase/Gemini에 접속하는 별도 XCTest Plan이다.
`Default`의 Unit/DatabaseIntegration 테스트와 일반 PR 필수 검사에는 포함하지
않는다. 공개 계약과 운영 Adapter 경계는 [ADR 0003](../decisions/0003-ai-module-boundary.md)이
정의한다. 이 문서는 실제 호출의 실행 조건과 검증 증거를 정의한다.

## 검증 범위

`GeminiContractTests`는 스크립트 분석과 단어 추출을 각각 한 번 요청한다.
운영 `FirebaseGeminiAdapter`를 생성하여 운영 모델·프롬프트·파서를 그대로 사용한다.
고정된 공개 입력만 사용하며 사용자 스크립트를 fixture로 수집하지 않는다.

- 스크립트: 실제 응답 존재와 JSON decode, 필수 텍스트, 0부터 연속된 문장·청크
  인덱스, 청크별·입력 전체 coverage를 운영 파서로 검증한다. OCR 제목과 미완성
  문장을 포함한다.
- 단어: 비어 있지 않은 배열, 필수 필드, 허용 품사를 운영 파서로 검증한다.
- 자연어 번역, 생성 제목, 단어 선택이나 개수는 고정 문자열과 비교하지 않는다.
  coverage는 공백만 정규화하고 단어·구두점·순서를 보존한다. 정규화·원문 보존
  fixture는 `Unit/GeminiScriptParserTests.swift`에서 검증한다.

`Default.xctestplan`은 `GeminiContractTests`를 제외하고,
`GeminiContract.xctestplan`은 해당 클래스만 선택한다. 실제 호출 시나리오를
추가하거나 이름을 바꾸면 두 Plan과 전용 runner의 선택·성공 조건도 함께 갱신한다.

## 호스트와 초기화

현재 `BettrTests`는 Bettr 앱을 테스트 호스트로 사용한다. 앱은 XCTest 호스트에서
운영 Firebase 초기화를 건너뛴다. 실제 호출 테스트가 다음 순서로 초기화한다.

1. 명시적 실행 환경과 등록된 Debug token, 설정 plist의 필수 필드를 검사한다.
   누락·손상된 설정은 실패하며 skip하지 않는다.
2. Firebase 로그 수준을 error로 제한하고 테스트 전용 App Check factory를 설치한다.
   factory는 SDK의 `AppCheckDebugProvider`를 반환한다. SDK 기본 Debug factory의
   로컬 token 출력 경로는 사용하지 않는다.
3. 검증한 plist에서 `FirebaseOptions`를 읽어 default Firebase app을 구성한다.
4. 운영 Adapter를 생성하고 두 시나리오를 순차 실행한다.

Debug Provider는 테스트 코드에만 있으며 운영 `FirebaseBootstrap`의
App Attest/DeviceCheck 설정을 변경하지 않는다. SDK 변경 시 설정 검증·오류
분류와 Debug Provider 동작을 함께 확인한다.

## 로컬 실행

Xcode 26 이상, iPad Simulator, Firebase AI Logic이 활성화된 프로젝트가 필요하다.
`Bettr/Bettr/GoogleService-Info.plist`는 해당 앱 bundle ID에 맞는 로컬 파일을
사용한다. 파일은 Git에 포함하지 않는다.

App Check enforcement가 활성화된 프로젝트에서 등록된 Debug token을 사용한다.
CI 전용 token과 로컬 token은 별도로 관리한다. 비밀 저장소에서
`FIREBASE_APP_CHECK_DEBUG_TOKEN` 환경 변수를 설정한다. token을 명령 인자,
채팅, 문서, Xcode의 공유 설정 또는 Git에 넣지 않는다. runner는 Xcode의 `TEST_RUNNER_AppCheckDebugToken`으로 이를 전달하고,
Xcode는 prefix를 제거한 `AppCheckDebugToken`을 테스트 호스트에 제공한다.
legacy `FIRAAppCheckDebugToken`을 함께 설정하지 않는다.

```bash
GEMINI_CONTRACT_ENABLED=1 \
DESTINATION='platform=iOS Simulator,name=iPad Pro 11-inch (M4)' \
SOURCE_PACKAGES=/private/tmp/Bettr297Packages \
DERIVED_DATA=/private/tmp/Bettr297DerivedData \
SUMMARY_JSON=/private/tmp/Bettr297-summary.json \
scripts/gemini-contract/run.sh
```

Simulator의 실제 이름이나 ID에 맞게 `DESTINATION`을 지정한다. 지정하지 않으면
runner는 CI 기준인 iOS 26.2 / iPad Pro 11-inch (M4)를 생성하고 실행 후 삭제한다.
`DERIVED_DATA` 아래에 매 실행의 전용 임시 디렉터리를 만들고 실행 후 제거한다.
기존 plist와 결과 요약은 덮어쓰지 않는다. 반복 실행 전에 이전 요약을 별도 위치로
보관하거나 새 `SUMMARY_JSON` 경로를 지정한다.
공유 Plan에는 비밀값이나 token 매크로를 저장하지 않는다.
`$(ENV)` 매크로는 shell 환경 변수를 자동으로 확장하지 않으므로, token 전달은
[Apple의 TEST_RUNNER 환경 변수 규칙](https://developer.apple.com/documentation/xcode/environment-variable-reference)을
따르는 runner를 사용한다.

## 시간과 호출 예산

| 범위 | 상한 |
| --- | --- |
| 시나리오별 분석 대기 | 단조 시계 기준 60초 |
| XCTest 안전장치 | 테스트별 90초 |
| 운영 Adapter 시도 | 시나리오별 최대 2회, 재시도 대기 1초 |
| 실행별 Gemini 생성 요청 | 두 시나리오 합계 최대 4회 |
| CI job | 빌드·실행 포함 15분 |

외부 호출의 재시도는 운영 Adapter 정책만 사용한다. runner에서 추가로 재시도하거나
XCTest 반복 실행·병렬 실행을 켜지 않는다. App Check token 교환 등 SDK 내부
인증 요청은 Gemini 생성 요청 수에 포함하지 않는다.

시간 제한은 구조적 task group을 사용하지 않는다. 외부 호출이 취소에 응답하지
않아도 unstructured task의 첫 결과만 continuation으로 전달하고 제한 시간에
반환한다. 작업을 취소한 뒤 도착한 결과는 폐기한다. 서버 처리가 실제로 중단되는
것은 보장하지 않는다. 이 동작은 Default의 `GeminiContractSupportTests`에서
취소를 무시하는 fake로 검증한다.

## 전용 CI

`.github/workflows/ios-gemini-contract.yml`을 사용한다. 일반 `iOS Default` 검사를
대체하거나 필수 검사에 포함하지 않는다.

- 수동: Actions의 `iOS Gemini Contract`에서 실행할 ref와 목적을 선택한다.
- nightly: 매일 03:17 KST에 저장소 기본 브랜치에서 실행한다.
- 릴리스 전: 의도한 승격 대상 ref에서 `purpose=release-before`로 수동 실행하고
  해당 커밋의 성공 결과를 확인한다. 릴리스 태그를 만든 뒤의 실행으로 대체하지 않는다.
- AI 영향 경로 변경: 전용 PR/push workflow를 실행한다. Adapter, 프롬프트·파서,
  공개 계약·DTO, 계약/관련 단위 테스트, Firebase bootstrap, SDK/Package.resolved,
  프로젝트·Test Plan·관련 workflow/runner를 포함한다. 순수 UI와 GRDB 변경은 제외한다.
  #301 이후 BettrAI 경로도 감지하되 bootstrap·설정 경로는 유지한다.

Repository Actions Secrets:

- `GOOGLE_SERVICE_INFO_PLIST_BASE64`: CI용 Firebase plist의 base64.
- `FIREBASE_APP_CHECK_DEBUG_TOKEN`: 해당 Firebase 앱에 등록한 CI 전용 token.

CI는 설정 파일을 복원하고 실행 후 제거한다. 복원한 plist, token, 입력,
원문 응답, SDK 오류 원문, 원본 xcodebuild 출력과 xcresult를 artifact로 올리지 않는다.
임시 빌드 자료와 token을 담을 수 있는 xctestrun manifest도 실행 후 제거한다.
runner는 고정된 실패 분류와 정제한 성공 요약만 공개한다. 로그 보호를 위해
`set -x`나 Firebase debug logging을 사용하지 않는다.

## 실패 분류와 성공 증거

| 분류 | 의미 |
| --- | --- |
| `configuration` | 실행 환경, token 또는 plist 설정 문제 |
| `authentication` | Firebase/App Check 인증·권한 문제 |
| `quota` | 호출 제한 또는 quota |
| `serviceUnavailable` | 외부 서비스·전송 장애 |
| `deadline` | 분석 대기 시간 초과 |
| `responseContract` | JSON 구조·필수 필드·인덱스·coverage 회귀 |
| `cancelled` | 작업 취소 |
| `unknown` | 공개 오류 계약으로 식별할 수 없는 실패 |

어떤 실패도 일괄 skip하거나 통과로 바꾸지 않는다. 성공 증거는 실제 실행의
`xcodebuild` 종료 코드 0과 xcresult 요약에서 두 테스트 통과·실패 0·skip 0을
함께 확인한 정제된 요약이다. 빌드만 성공, 실행 명령만 호출, 테스트 0건 또는
skip만 있는 결과는 실제 Gemini 성공 증거가 아니다. 실패한 실행도 고정 분류와
종료 코드를 남긴다. 원문 오류는 결과 요약에 복사하지 않는다.

경로 선택·설정 실패·종료 코드·빈 결과/skip 거부는
`scripts/tests/gemini-contract-ci.sh`로 외부 호출 없이 검증한다.
