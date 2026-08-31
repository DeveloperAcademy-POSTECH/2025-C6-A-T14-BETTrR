# BETTrR 저장소 가이드

이 파일은 저장소 전체의 협업 규칙을 정의합니다. 이슈나 PR을 만들기 전에
`README.md`, 관련 이슈 템플릿, `.github/PULL_REQUEST_TEMPLATE.md`를 읽습니다.

## 작업 흐름

- 일반 작업 브랜치는 `dev`에서 `<type>/#<issue-number>` 형식으로 만듭니다.
- 일반 PR의 대상 브랜치는 `dev`입니다.
- 이슈와 PR은 하나의 관심사에 집중합니다. 비밀값,
  `GoogleService-Info.plist`, 로컬에서 생성된 Xcode 데이터는 포함하지 않습니다.

## 커밋과 PR

- 커밋 제목은 `[#<issue-number>] <type>: <한국어 요약>` 형식을 사용합니다.
- PR 제목은 `Gitmoji + Type: <한국어 요약>` 형식을 사용합니다.
- 일반 이슈 PR은 본문에 `Closes #<issue-number>`로 관련 이슈를 연결합니다.
- 이슈나 PR을 만들 때 Assignee와 적용 가능한 기존 Label은 수동으로 설정합니다.
- 저장소 PR 템플릿을 사용합니다. 앱 변경에는 `Bettr/AGENTS.md`도 적용합니다.

## 릴리스 승격

- `dev`에서 `main`으로의 PR은 이슈 PR이 아닌 릴리스 승격 PR입니다. 이 PR에
  코드, 버전, 설정 변경을 추가하지 않습니다.
- 제목은 `🍀 Chore: dev를 main에 병합`을 사용하고 `release.md` PR 템플릿을
  사용합니다.
- 병합 전 의도한 `main...dev` diff와 릴리스 검증 결과를 확인합니다. 태그는
  병합으로 생성된 `main` 커밋에 만듭니다.
