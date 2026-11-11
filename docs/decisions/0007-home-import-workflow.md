# 홈 사진·OCR·PDF 입력 작업의 소유권

- 날짜: 2026-11-11
- 상태: 채택 — 설계 원칙이며 구현 완료는 관련 이슈에서 추적한다.
- 관련 이슈: [#321](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/321), [#292](https://github.com/DeveloperAcademy-POSTECH/2025-C6-A-T14-BETTrR/issues/292)
- 관련 결정: [0002](0002-feature-state-contract.md), [0004](0004-script-confirm-workflow.md)

## 배경

`HomeView`가 사진 로딩, OCR, PDF 추출, 결과 분기, `router.push`를 직접 조율했다.
사진 선택은 취소·대체 없는 `Task`로 실행되어 이전 선택의 늦은 완료가 새 선택과
겹쳐 navigation을 중복할 수 있었고, 이미지 로딩 실패는 `try?`로 사라졌다. OCR은
콜백으로 실패와 빈 결과를 모두 `""`로 돌려주었고, Vision 요청과 PDF 추출은 메인
스레드에서 동기로 실행되었다. 이 흐름은 View 렌더링 없이는 검증할 수 없었다.

## 결정

**입력 작업의 소유자는 `HomeImportModel` 하나다.** picker 표시 같은 UI 상태와
오류 알림, navigation 실행은 View에 남기고 로딩·OCR·추출과 그 결과 판단은 모델이 맡는다.

- 한 번에 하나의 작업만 유효하다. 새 선택은 이전 작업을 취소·대체하며, 대체되거나
  화면 이탈로 취소된 작업의 늦은 성공·실패는 요청 ID로 걸러 반영하지 않는다.
- 결과는 제목/텍스트 `HomeImportCompletion`으로 한 번만 전달한다. View가
  `consumeCompletion()`으로 가져가 ScriptConfirm으로 이동하며(ADR 0004의 완료
  소비 방식과 같다), 소비 전에 새 선택이 시작되면 전달 전 결과를 버린다.
- OCR·PDF 경계는 `async throws`로 둔다. 실패는 `DocumentImportError`로 던지고
  글자가 없는 빈 결과는 성공(`""`)이다. **빈 결과는 기존처럼 빈 텍스트로
  ScriptConfirm에 진입한다.** 사용자가 직접 입력할 수 있기 때문이다.
- 로딩·OCR·추출 실패는 오류 알림으로 알린다. 이전에는 OCR 실패가 빈 텍스트
  진입으로, 사진 로딩 실패가 무반응으로 보였다. 이것이 이번 변경의 유일한 사용자 동작 변화다.
- `fileImporter`의 사용자 취소(`CocoaError.userCancelled`)는 상태를 바꾸지 않으며
  진행 중인 작업도 취소하지 않는다. 그 밖의 선택 실패는 이전 작업을 대체한다.
- 화면 이탈(`onDisappear`)은 진행 중 작업과 전달 전 결과를 취소한다. 이미지 로딩 중
  취소되면 OCR을 시작하지 않는다.
- **파일 접근 수명은 `PDFTextExtractor`가 소유한다.** security-scoped 접근은 단일
  동기 구간에서 얻고 `defer`로 해제하며, 시작 전에 취소되었다면 얻지 않는다. 모델은
  접근을 보유하지 않으므로 취소·대체·오류 어느 경로에서도 해제가 호출 하나에 갇힌다.
- Vision 요청과 PDF 추출은 백그라운드에서 실행한다. detached 작업은 취소를 상속하지
  않으므로 `withTaskCancellationHandler`로 전달한다. PDF는 쪽마다 취소를 확인해 중단하고,
  Vision은 호출 한 번이라 시작 전에만 확인한다. 취소는 실패가 아니므로 `CancellationError`를 그대로 던진다.

## 대안과 보류 이유

- 범용 Import 프레임워크·소스별 프로토콜 계층: 입력은 세 가지뿐이고 결과 형태가
  같아 작은 모델 하나로 충분하다. 이슈 범위에서도 제외했다.
- 모델이 security-scoped 접근을 직접 시작·해제: 접근이 작업보다 오래 살아남는 경로가
  생기고 모델이 Foundation 파일 API에 묶인다.
- 새 선택이 진행 중 작업을 거부(첫 선택 우선): 사용자가 마지막에 고른 입력이 무시되어
  체감 동작이 어긋난다.
- 빈 결과를 오류로 처리: 기존 동작을 바꾸며 직접 입력 경로를 막는다. 필요해지면
  이 결정을 대체한다.

## 결과와 비용

작업 수명과 늦은 결과의 영향 범위가 모델 한 곳으로 줄고 View 없이 검증된다.
Fake OCR/PDF를 유지해야 한다. 처리를 백그라운드로 옮기면서 화면이 더 이상 멈추지 않아,
`isProcessing` 동안 홈에 진행 표시를 올리고 입력을 막는다. 처리가 보통 짧아 취소 버튼은
두지 않는다. 로딩이 매우 길어지는 경우(예: 느린 네트워크의 iCloud 사진)는 재검토 대상이다.
디자인 확정 전의 최소 표시이며 iPhone UI에서 다시 다듬을 수 있다.

## 검증

`HomeImportModelTests`가 기기 없이 위 규칙을 검증한다. `PDFTextExtractorCancellationTests`는
접근 요청 전 취소를 검증한다. 실제 picker·카메라·Files의 iPad acceptance 결과는 #321 PR에 남긴다.
