# BETTrR iPhone 지원 기반 리팩터링 계획

현재 iPad 정상 흐름을 유지하면서 테스트 기반, 외부 의존성, 기능 상태와 변경
영향 범위를 정리한다. iPhone 디자인 확정 뒤 공통 업무 흐름을 재사용할 수 있는
상태를 만든다. 이 문서는 단계 목적·의존 관계·착수 조건만 관리한다.
실행 범위·완료 기준·최신 진행 상태는 [#292](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/292)
및 하위 이슈에서 확인한다. ADR의 `채택`은 구현 완료를 의미하지 않는다.

## 설계 기준

- 기능 상태 관리와 모듈 간 계약: [ADR 0002](../decisions/0002-feature-state-contract.md).
- BettrAI의 공개 계약과 의존성 경계: [ADR 0003](../decisions/0003-ai-module-boundary.md).
- ScriptConfirm 요청·타임아웃·저장 정책: [ADR 0004](../decisions/0004-script-confirm-workflow.md).

기존 정책과 세부 테스트 시나리오는 여기에서 반복하지 않는다. Milestone 1~4는
기반 리팩터링, 5는 핵심 기능 안정화다. 6·7은 근거와 디자인에 따른 조건부 단계다.
앱 전체 MVI 전환, 선행 UI 모듈 생성, Tuist 도입, CD는 이번 계획의 전제가 아니다.

## Milestone 1. 테스트 실행 기반과 최소 CI

| 이슈 | 목적 |
| --- | --- |
| [#293](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/293) | Firebase/AppCheck Bootstrap 및 기본 테스트 격리 |
| [#296](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/296) | Unit/DatabaseIntegration/GeminiContract Test Plan 분리 |
| [#298](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/298) | Xcode 설정과 SPM 참조 정리 |
| [#295](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/295) | 외부 Gemini 호출 없는 기본 CI |

## Milestone 2. 회귀 테스트와 데이터 안정성

| 이슈 | 목적 |
| --- | --- |
| [#305](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/305) | AI 파서·오류·재시도/시간 의존성의 단위 테스트 |
| [#303](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/303) | GRDB migration과 복합 저장 transaction |
| [#299](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/299) | 구조화 로깅과 민감 정보 출력 정리 |

## Milestone 3. 외부 경계와 화면 흐름 분리

| 이슈 | 목적 |
| --- | --- |
| [#294](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/294) | AI 계약과 운영 Adapter 경계 |
| [#304](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/304) | Composition Root와 화면 상태 분리 |
| [#306](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/306) | ScriptConfirm 업무 흐름과 요청 수명 분리 |
| [#297](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/297) | 실제 AI 계약 검증과 별도 CI |

`#294 → #304 → #306`을 기본 순서로 한다. #297은 #294의 운영 계약/Adapter가
준비되면 #304·#306과 병렬 진행할 수 있다.

## Milestone 4. 검증된 AI 경계의 물리적 모듈화

[#301](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/301)에서
BettrAI를 local Swift Package 또는 별도 target으로 추출한다. Milestone 3의
계약·조립·기능 흐름·실제 연동 검증이 추출의 선행 조건이다.
모듈 경계는 ADR 0003을 따르고, 독립 실행과 앱 통합 검증의 완료 기준은 #301에서 관리한다.
실제 공개 API·설정·빌드/테스트 방법은 추출된 모듈 README에 남긴다.

## Milestone 5. 핵심 기능 흐름 안정화

Milestone 4 이후 녹음부터 시작한다. 독립적인 쓰기 경계는 병렬로 진행할 수 있다.
각 작업은 기존 정상 동작의 회귀 기준을 정하고 필요한 외부 경계만 분리한다.
이 단계 자체로 새 Feature 모듈을 요구하지 않는다.

| 이슈 | 목적 |
| --- | --- |
| [#319](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/319) | 녹음 상태 전이와 Speech·Audio 경계 분리 |
| [#320](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/320) | 암기 화면 재생 상태의 단일 소유권 정리 |
| [#321](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/321) | 홈 사진·OCR·PDF 입력 작업 흐름 분리 |

## Milestone 6. 필요한 Feature 모듈의 선택적 추출 — 조건부

독립 테스트, 변경 영향, 코드 소유권, 빌드 비용 중 해결할 문제가 확인된
기능만 추출한다. 새로운 경계의 근거·비용은 ADR, 작업 단위·검증·롤백은
이슈에 남긴다. 근거가 부족하면 보류하고 빈 Core/Domain/Data/Presentation
모듈이나 범용 Shared 저장소를 선행 생성하지 않는다.
포괄적 UI 경계 설계는
[#300](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/300)의
디자인 근거가 확정된 뒤 재검토한다.

## Milestone 7. iPhone 디자인 확정 후 UI 적용 — 조건부

디자인은 앞선 단계와 병렬 진행할 수 있다. 확정된 화면부터 안정된 기능 흐름을
재사용하며 모든 Feature 모듈의 완성을 기다리지 않는다. 실제 화면·navigation
차이를 근거로 적응형 View 또는 플랫폼 UI 경계를 선택하고, 중요한 구조 결정은
ADR에 남긴다. 화면별 이슈에서 iPhone acceptance와 기존 iPad 회귀를 검증한다.

## 기록과 유지

[문서별 책임과 갱신 기준](../decisions/README.md#문서별-책임과-갱신-기준)을 따른다.
이슈 완료·테스트 실행만으로 이 로드맵을 갱신하지 않는다. 단계 목적·순서·착수
조건이 바뀔 때만 수정한다. 검증 결과는 해당 PR, Xcode 성공 증거 기준은
[#316](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/316)에서 관리한다.
`.omx/plans/`에는 로컬 참조만 두며 실행 계획을 복제하지 않는다.
