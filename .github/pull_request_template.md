## 변경 목적과 결과
어떤 업무 요구/장애를 해결하며 실행 결과가 어떻게 달라지는지 적습니다.

## 담당 업무 및 영향
- 담당: Infrastructure / Development / DevOps
- 영향 unit, module 소비자, 애플리케이션, 환경:
- 협의가 필요한 다른 담당 업무:

## 검증 증거
실행 명령과 결과를 적습니다. mock/validate와 실제 AWS plan을 구분합니다.
인프라 변경은 add/change/destroy/replacement 수, State key, 데이터 보존 영향을 포함합니다.
Secret, State 원문, 자격증명을 첨부하지 않습니다.

## 배포 순서와 복구
의존 unit 순서, DB migration 호환성, 이전 버전 복구 방법을 적습니다.
기존 State/resource 주소 이동 여부를 명시합니다. IaC 변경 revert만으로 원격 복구가 완료되지는 않습니다.
