# Script 복합 저장 경계

## 결정

`Script`, `Sentence`, `Chunk` 생성은 `ScriptRepository.createScript(with:)`의 단일
GRDB write transaction에서 처리한다. 각 생성은 `insert`를 사용하고, 입력
`ScriptData`의 `orderIndex`를 그대로 저장한다.

`Script`는 기존 레코드의 상태 변경을 표현하는 `markViewed(at:)`를 제공한다.
일반 갱신에는 `save`를 유지하고, 존재가 확인된 제목 갱신에는 `update`를 사용한다.

## 근거

하위 레코드는 상위 레코드의 DB 생성 ID가 있어야 저장할 수 있으므로, 현재 GRDB
모델에서는 명시적인 순차 `for` 반복이 가장 직접적이다. 이 저장 순서를 하나의
트랜잭션 안에 둬 중간 실패 시 전체가 롤백되도록 한다.

## 보류한 선택지

`Script`를 완전한 도메인 aggregate root로 만들지는 않는다. 현재 모델은 GRDB
row model이고 ID도 DB가 생성하므로, 이를 수행하려면 persistence model과 별도의
도메인 aggregate/draft를 도입해야 한다. 그 경계 분리는 모듈화 또는 도메인 모델의
GRDB 의존성 분리 작업에서 다시 검토한다.
