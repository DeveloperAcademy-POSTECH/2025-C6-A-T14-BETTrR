# Bettr 앱 가이드

먼저 저장소 루트의 `AGENTS.md`를 읽습니다. 이 파일은 `Bettr/` 아래의 iPad
앱, Xcode 프로젝트, 테스트 타깃에 적용됩니다.

## 앱 범위

- 현재 제품은 iPad 전용입니다. 이슈 범위가 명시되지 않으면 iPhone 전용 동작을
  추가하거나 지원 기기군을 변경하지 않습니다.
- [Developer Academy Swift 스타일 가이드](https://github.com/DeveloperAcademy-POSTECH/swift-style-guide)를 따릅니다.
- Xcode 프로젝트와 Swift Package Manager 변경은 검토 가능하게 유지합니다. 패키지
  요구사항을 바꾸면 추적 중인 `Package.resolved`도 갱신하고 관련 빌드 또는 테스트를
  실행합니다.

## 테스트와 비밀값

- 테스트를 추가하거나 수정할 때는 `BettrTests/AGENTS.md`를 따릅니다.
- Default 테스트는 `GoogleService-Info.plist` 없이 실행되어야 합니다. 실제 Gemini
  호출은 명시적인 GeminiContract 테스트 계층에만 둡니다.
- Firebase 설정 파일, App Check 토큰, Gemini 인증 정보 등 비밀값을 커밋하거나
  로그로 출력하지 않습니다.
- 이슈에서 명시하지 않으면 signing, bundle identifier, deployment target, SDK root,
  버전 설정을 변경하지 않습니다.
