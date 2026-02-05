

<img width="100" alt="AppIcon" src="https://github.com/user-attachments/assets/5e70afe9-66e6-44f9-9f3e-c03bbeb75803" />

# 렙

<img width="200" alt="Group 275 2@3x" src="https://github.com/user-attachments/assets/258da63a-f98b-4e3d-a5c7-1faf25ca04bf" /> |<img width="200" alt="Group 1000004742 3@3x" src="https://github.com/user-attachments/assets/52b8d433-115b-49fe-9000-2e7a856a6a47" /> |<img width="200" alt="Group 1000004744 2@3x" src="https://github.com/user-attachments/assets/d81afa66-5194-4161-a730-c57e88dd4606" /> |<img width="200" alt="IMG_3289 1@3x" src="https://github.com/user-attachments/assets/fee77c8c-8dfd-4a38-962b-d00854c406b6" /> |
|:-:|:-:|:-:|:-:|

| 구분 | 내용 |
|------|------|
| 팀 구성 | iOS 개발 1명, 백엔드 1명, Design 1명 |
| 개발 기간 | 2025.12 ~ 2026.01 |
| 최소 버전 | iOS 16.0+ |

## 주요 기능

- 위치 기반 매물 클러스터링 
- 매물 실시간 확인 및 필터링
- 실시간 1:1 채팅 및 파일 업로드 (Multipart/form-data)
- 카드 결제 (PG결제) 및 영수증 검증
- HLS 스트리밍 기반 숏폼 비디오
- WebView Bridge를 통한 출석 인증
- 카카오 / 애플 소셜 로그인
- 부동산 커뮤니티 (게시글 작성/ 댓글 / 답글 / 좋아요)

## 기술 스택

| 분류 | 기술 |
|------|------|
| UI | UIKit, PinLayout, FlexLayout, Then |
| 반응형 | RxSwift, RxCocoa |
| 데이터베이스 | Realm |
| 네트워크 | Alamofire, Kingfisher, Socket.IO |
| 아키텍처 | MVP + Input/Output, Repository Pattern |
| 인증 | KakaoSDK, AuthenticationService |
| Firebase | Firebase Cloud Messaging |
| 프레임워크 | MapKit, CoreLocation, PhotosUI, WebKit |

## 아키텍처

### MVP + Input/Output

View와 비즈니스 로직을 분리하고, 단방향 데이터 흐름을 유지하는 구조를 채택했습니다.

<img height = "200" alt="Frame 285" src="https://github.com/user-attachments/assets/28321fe8-2214-409c-b7d7-4b889a748b70" />|
:-:|


MVP + Input/Output 구조를 사용해 화면과 비즈니스 로직을 분리했습니다. 장기적으로 모듈 분리를 염두에 둔 구조를 지향했기 때문에, **View와 로직 간
의존성을 최소화**하고 **단방향 데이터 흐름**을 유지하는 아키텍처가 필요했습니다.

Presenter는 View를 직접 참조하지 않고 Input을 받아 Output으로 변환하는 역할만 수행하도록 설계했으며, 의존성은 프로토콜 기반으로 정의하고 생성 시점에
주입하는 방식(DI)을 사용해 구현체에 대한 결합을 최소화했습니다.

### Container + Factory

<img height = "220" alt="Frame 294" src="https://github.com/user-attachments/assets/d944bb20-3f0b-49b5-a317-42a86c40407c" />|
:-:|

의존성 관리는 **Container + Factory** 패턴을 사용해 구성했습니다. 네트워크, 인증, 레포지토리 등 공통 인프라는 Protocol로 추상화한 뒤,
AppContainer에서 실제 구현체를 생성·관리하도록 설계했습니다.

각 화면은 Factory를 통해 자신에게 필요한 의존성만 주입받으며, ViewController는 구체 구현이 아닌 추상화된 인터페이스에만 의존하도록 구성했습니다.


## 핵심 기능

### 지도 기반 매물 클러스터링

<img width="200" alt="IMG_3278 1@3x" src="https://github.com/user-attachments/assets/669f1e35-c165-45b8-8f22-63423e9f5504" /> |
:-:|

부동산 매물은 특정 지역에 밀집되는 특성이 있어, 이를 효과적으로 시각화하기 위해 클러스터링을 설계했습니다.

**문제 정의**
- 매물의 밀집도를 직관적으로 인지할 수 있을 것
- Zoom In/Out 시 UI Freezing이 없을 것

**방안 탐색**

<img height= "200" alt="Group 1000004747" src="https://github.com/user-attachments/assets/fd2a76ea-592e-452d-9427-7d09236b6936" />|
:-:|

| 방식 | 시간 복잡도 | 특징 |
|------|------------|------|
| 그리드 | O(n) | 바둑판처럼 인위적으로 보임 |
| DBSCAN | O(n²) | 실시간 인터랙션에 부적합 |
| 계층적 그리디 + KD-Tree | O(√n+k) | 원형 단위로 자연스러운 군집 |

**최종 구조: 줌 레벨 구간별 클러스터링 모델 전환**

- **저줌 구간 (Zoom 7~10)**: GeoJSON 행정구역(도) 폴리곤 기준으로 매물 수 집계 → O(n) 스캔
- **고줌 구간 (Zoom 11~16)**: 계층적 그리디 클러스터링 + KD-Tree 기반 공간 인덱싱

<img width="320" alt="Group 1000004746@3x" src="https://github.com/user-attachments/assets/0f78eca9-700b-4d53-a1c3-3193c5d2c3fc" /> |
:-:|


**성능**
- n=5,000 기준 전체 트리 빌드 약 0.1초 (서울 밀집 분포)
- 균등 분포 시 Lazy Build fallback으로 최대 대기 시간 약 2.8초

### 2. 실시간 1:1 채팅

<img width="200" alt="IMG_3299 1@3x" src="https://github.com/user-attachments/assets/91acff61-7d94-4716-902f-87322c22f6e9" /> |
|:-:|

**Socket.IO 선택 이유**
- 자동 재연결, 지수 백오프 기반 재시도, 네트워크 변화 감지, 전송 방식 폴백을 기본 제공
- 모바일 환경에서 빈번한 네트워크 전환에 안정적으로 대응

**앱 생명주기 대응**

<img height = "100" alt="Frame 325" src="https://github.com/user-attachments/assets/7f05e96f-714a-43cb-ae94-d1b7078c58fd" />|
:-:|

- iOS는 백그라운드에서 소켓 연결 유지를 보장하지 않음
- 앱 상태 전환 시 명시적으로 연결 해제/재연결 처리
- 서버 측 CLOSE_WAIT 세션 방지

**채팅방 로딩 순서**

<img height="240" alt="Frame 1000005303" src="https://github.com/user-attachments/assets/ba5775bc-8562-4c36-a12e-47560abdf666" />|
:-:|

1. 소켓 연결 (실시간 수신 채널 확보)
2. 로컬 저장소 메시지 즉시 표시
3. 서버 동기화 (누락 메시지 보완)
4. 중복 메시지 ID 기준 필터링

**로컬 저장소: Realm 선택**

<img height= "200" alt="Group 144" src="https://github.com/user-attachments/assets/045831d2-5890-4c04-932d-d584d79a0c7b" />


- 채팅에서 빈번한 조회·갱신·삭제 작업에 최적화
- Results 타입의 Lazy Loading 활용으로 성능 이점 극대화
- Thread-confined 특성은 값 타입 도메인 모델 변환으로 해결

**읽지 않은 메시지 관리**

<img height = "200" alt="Group 250" src="https://github.com/user-attachments/assets/40f6a36f-df93-494f-90f8-e515bf783d25" /> |
:-:|

- Push 수신: 다른 방 메시지면 unreadCount += 1
- 채팅방 입장: 전체 읽음 처리 + 마지막 읽은 시간 갱신
- 포그라운드 진입: 서버 업데이트 시간 비교 후 동기화

### 3. 기타 기능

**카드 결제**
<img width="300" alt="Frame 264@3x" src="https://github.com/user-attachments/assets/fdf82e4e-63a9-4bb7-8eb5-b528a008ea25" /> |
|:-:|

- 클라이언트 결제 성공 응답만으로 신뢰하지 않음
- 서버가 PG사에 직접 영수증 검증 후 결제 완료 판단

**토큰 관리**
- Alamofire AuthenticationInterceptor로 Access Token 자동 주입
- 401/419 응답 시 Refresh Token으로 자동 갱신 및 요청 재시도
- 갱신 실패 시 Keychain 정리 후 로그인 화면 전환

**숏폼 비디오**
- HLS(m3u8) 스트리밍으로 초기 로딩 시간 최소화
- WebVTT 기반 자막 파싱 및 재생 시간 동기화
- 화질 변경 시 재생 위치와 상태 유지
