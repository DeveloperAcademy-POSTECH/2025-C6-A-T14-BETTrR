# 앱 로깅 정책

앱 소유 로그는 `AppLog`를 사용한다. 내부 구현은 Apple의
[Logger](https://developer.apple.com/documentation/os/logger)이며 subsystem은
`com.duracell.Bettr`이다. Console에서 subsystem과 category로 필터링한다.

| Category | 대상 |
| --- | --- |
| database | 초기화, 스크립트·제목·단어·피드백 저장 및 조회 |
| ai | Gemini 분석 단계, 응답 파싱, 단어 추출 |
| audio | 녹음 엔진과 재생 오디오 세션 |
| document | PDF 접근 및 OCR |
| ui | 개발용 Preview |

| Level | Debug | Release | 사용 기준 |
| --- | --- | --- | --- |
| debug | 사용 | 컴파일 조건으로 출력 제외 | 분석 시작·완료 등 필요한 단계 |
| error | 사용 | 사용 | 작업 실패, 복구 가능한 오류 |
| fault | 사용 | 사용 | DB 초기화 실패처럼 앱 실행을 지속할 수 없는 장애 |

`AppLog.ai.error("스크립트 응답 디코딩 실패")`처럼 고정된 사건 문구만
기록한다. 문자열 보간이나 런타임 `String`은 받지 않는 `StaticString` API로
민감 정보가 유입되는 것을 막는다. 고정 문구만 `.public`으로 기록한다.

토큰, 프롬프트 원문, AI 응답, 스크립트 제목·본문, 인식한 음성, 사용자 ID,
파일 경로 및 임의의 `Error`/`localizedDescription`은 **Debug에서도 기록하지
않는다**. 일부 글자나 해시를 남기는 대신 값을 완전히 제외한다. 오류 객체에는
SQL 인자나 서버 응답이 포함될 수 있으므로 원문을 기록하지 않는다. 필요한
진단 문구에는 실패한 작업을 명시한다. 사용자에게 보여주는 오류 UI는 별개다.

고정 문구에도 실제 비밀값이나 사용자 데이터를 직접 붙여 넣지 않는다.
`print`, `debugPrint`, `NSLog`, `dump`, 직접 만든 Logger로 우회하지 않는다.
SDK 내부 로그는 이 래퍼의 제어 범위 밖이다. Firebase App Check 디버그 토큰을
앱 코드에서 조회하거나 출력하는 코드를 추가하지 않는다.

검증은 제품 코드의 원시 출력 API 부재와 `AppLog`의 `StaticString` 경계를
정적으로 확인하고, Default Test Plan으로 동작을 확인한다. 기능 테스트는
반환값·상태·DB 결과를 검증하며 실제 로그 출력 내용이나 로그 수집 가능 여부에
의존하지 않는다.
