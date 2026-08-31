<!--
`dev -> main` 릴리스 승격 PR 전용 템플릿입니다.
코드, 버전, 설정 변경은 이 PR 이전에 dev로 병합되어야 합니다.
-->

## 🍀 Release Promotion

### 🏷️ 대상 버전

- Marketing Version:
- Build Number:
- 병합 후 생성할 태그:

### 📦 승격 범위

- Base: `main`
- Compare: `dev`
- 검토한 `main...dev` 변경 범위:

### 🧪 검증 내역

- [ ] Default Test Plan 통과
- [ ] iPad 수동 스모크 테스트 완료
- [ ] 릴리스 제외 항목 및 알려진 위험 검토

### 🙋 운영 확인

- [ ] Assignee를 수동으로 등록
- [ ] 적용 가능한 기존 Label을 수동으로 등록
- [ ] 병합 후 `main`의 병합 커밋에 태그 생성
