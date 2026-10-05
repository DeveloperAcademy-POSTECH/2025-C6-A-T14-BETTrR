# BettrAI의 공개 계약과 의존성 경계

- 날짜: 2026-10-05
- 상태: 채택 — 설계 원칙이며 구현 완료는 관련 이슈에서 추적한다.
- 관련 이슈: [#292](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/292), [#294](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/294), [#297](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/297), [#301](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/301), [#304](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/304)

## 배경

첫 추출 대상은 AI 계약과 외부 구현이다. 기존 AI 결과 DTO에는 DB 모델을 받는
변환 생성자가 있고, 호출·재시도·저장 책임도 분리해야 한다. 파일만 옮기면
GRDB 또는 앱 구현에 대한 역방향 의존성이 따라올 수 있다.

## 결정

BettrAI는 AI 공개 프로토콜, 입력·결과 DTO, 프롬프트, 파서, 오류·재시도 정책과
Firebase Adapter를 포함한다. SwiftUI·GRDB·앱 타깃에는 의존하지 않는다.
Firebase SDK는 Adapter 구현에 필요한 의존성으로 내부에 격리한다.

- 기존 DTO를 재사용하되, `SentenceData.init(sentence: ...)`와
  `ChunkData.init(chunk: ...)` 등 DB 변환 생성자는 앱 측 extension 또는
  변환 코드로 이동한다. AI 결과 타입에 persistence 모델을 연결하지 않는다.
- 기능 호출부는 공개 프로토콜을 사용한다. Composition Root는 제공된 생성
  경로로 실제 Adapter를 조립할 수 있다. 공개 함수·DTO·오류에 SDK 타입을 노출하지 않는다.
- 오류는 취소, 외부 호출 실패, 응답 해석 실패 등을 호출부에서 처리할 수 있게
  전달한다. 최종 실패를 `nil`로 소실하지 않는다.
- 취소는 재시도 대기에도 전파되며, 취소 이후 새로운 재시도를 시작하지 않는다.
  AI 호출 재시도는 DB 저장 재시도와 분리한다.
- actor 격리와 동시성 경계를 명시하고, 경계를 넘는 입력·결과의 `Sendable`
  계약을 검토한다. 불필요한 `@unchecked Sendable`로 제약을 우회하지 않는다.
- 패키지의 SDK 버전·지원 환경·실제 의존성을 기록한다. 기존 로거가 앱 내부에
  의존하면 내부 구현이나 좁은 주입 경계로 대체하여 앱 역의존을 제거한다.

마일스톤 3에서 계약·Adapter·Composition Root·ScriptConfirm 흐름을 안정화한
후 #301에서 물리적으로 추출한다. 순수 단위 테스트는 Firebase 설정이나 앱
호스트 없이 실행한다. 실제 스크립트 분석·단어 추출 계약 테스트는 별도 경로로
실행하고 운영 프롬프트·파서를 공유한다.

실제 연동 테스트의 변경 감지에는 BettrAI뿐 아니라 SDK 버전, Bootstrap,
계약 테스트와 관련 workflow 경로도 포함한다. 비밀값은 모듈·문서에 넣지 않는다.

## 대안과 보류 이유

- 모든 Domain·DB 모델 이중화: 첫 AI 경계에 필요한 변환 분리부터 수행한다.
  전체 모델 재설계는 [0001](0001-script-persistence-boundary.md)의 보류 결정을 유지한다.
- 추가 Feature 모듈 일괄 추출: 독립성이 확인된 기능에 한해 후속 단계에서 판단한다.
- Tuist 전환: 닫힌 [#302](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/302)의
  범위를 다시 열지 않는다. 빌드 관리 필요가 확인되면 별도 결정으로 검토한다.
- iPhone UI 구조 확정: [#300](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/300)의
  디자인 근거가 확정되기 전까지 화면·내비게이션 설계를 앞서 고정하지 않는다.

## 결과와 비용

AI 공급자 구현과 앱 업무 흐름을 독립적으로 교체·검증할 수 있다. 공개 API,
DTO 소유권, SDK 버전과 모듈 테스트를 관리하는 비용이 생긴다. Firebase 설정과
실제 네트워크 호출의 성공 여부는 순수 단위 테스트만으로 검증하지 못한다.

## 검증

모듈 독립 빌드·순수 테스트, Fake Adapter를 통한 기능 테스트, 앱 통합 빌드를
수행한다. 공개 API와 의존성을 검토하여 SwiftUI·GRDB·앱 역의존 및 SDK 타입
노출이 없는지 확인한다. 실제 연동 테스트는 두 AI 기능의 구조적 결과 계약을
검증하고, 실행 조건·비밀값 주입 방법·결과를 관련 PR에 기록한다.

## 재검토 조건

두 번째 공급자 도입, 여러 앱의 AI 모듈 재사용, SDK 크기·빌드 비용 또는 설정
제약이 실제 문제가 되면 계약과 Adapter의 별도 모듈 분리를 검토한다. 추가
Feature 모듈과 빌드 도구 변경은 첫 추출의 검증 결과를 근거로 별도 ADR에서 결정한다.
