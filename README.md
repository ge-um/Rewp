# Rewp (렙)

반려동물과 함께 살 집을 구하는 iOS 앱

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0+-000000?style=flat&logo=apple&logoColor=white"/>
  <img src="https://img.shields.io/badge/Swift-5.0-F05138?style=flat&logo=swift&logoColor=white"/>
  <img src="https://img.shields.io/badge/Architecture-MVP-blue?style=flat"/>
</p>

## 팀 정보

| 구분 | 내용 |
|------|------|
| 팀 구성 | iOS 1, Backend 1, Design 1 |
| 개발 기간 | 2025.12 ~ 2026.01 |
| 최소 버전 | iOS 16.0+ |

## 핵심 기능

- **위치 기반 매물 클러스터링** - 지도에서 매물 분포를 직관적으로 파악
- **매물 실시간 확인 및 필터링** - 다양한 조건으로 매물 탐색
- **실시간 1:1 채팅** - Socket.IO 기반 중개사와 실시간 소통
- **카드 결제** - PG사 영수증 검증을 통한 안전한 예약 결제
- **숏폼 비디오** - HLS 스트리밍 기반 매물 영상 콘텐츠
- **부동산 커뮤니티** - 게시글, 댓글, 답글, 좋아요
- **소셜 로그인** - 카카오 / 애플

## 기술 스택

| 분류 | 기술 |
|------|------|
| UI | UIKit, PinLayout, FlexLayout, Then |
| 반응형 | RxSwift, RxCocoa |
| 데이터베이스 | Realm |
| 네트워크 | Alamofire, Kingfisher, Socket.IO |
| 아키텍처 | MVP + Input/Output, Repository Pattern |
| 인증 | KakaoSDK, AuthenticationService |
| Firebase | Cloud Messaging |
| 프레임워크 | MapKit, CoreLocation, PhotosUI, WebKit |

## MVP + Input/Output

View와 비즈니스 로직을 분리하고, 단방향 데이터 흐름을 유지하는 구조를 채택했습니다.

```
User Action → ViewController → Input → Presenter → Repository → API
                    ↑                      ↓
               UI 업데이트  ←  Output  ← 결과 가공
```

- **Presenter**는 View를 직접 참조하지 않고 Input을 받아 Output으로 변환
- 의존성은 Protocol 기반으로 정의하고 생성 시점에 주입 (DI)
- 테스트 및 구조 확장 시 Presenter 수정 없이 의존성 교체 가능

### Container + Factory

```
AppContainer
     ↓
  Factory
     ↓
Repository ← Presenter
     ↓
ViewController
```

- 네트워크, 인증, 레포지토리 등 공통 인프라는 Protocol로 추상화
- AppContainer에서 실제 구현체를 생성·관리
- 각 화면은 Factory를 통해 필요한 의존성만 주입

## 네트워킹

### 토큰 관리

- Alamofire AuthenticationInterceptor로 Access Token 자동 주입
- 401/419 응답 시 Refresh Token으로 자동 갱신 및 요청 재시도
- 갱신 실패 시 Keychain 정리 후 로그인 화면 전환

### 카드 결제

- 클라이언트 결제 성공 응답만으로 신뢰하지 않음
- 서버가 PG사에 직접 영수증 검증 후 결제 완료 판단

```
Client                              Server
  │  estate_id, total_price           │
  │ ─────────────────────────────────→│ 주문 생성
  │              order_code 발급       │
  │ ←─────────────────────────────────│
  │                                   │
  │  카드 결제 → PG사 결제 처리         │
  │                                   │
  │  imp_uid (결제 완료 콜백)           │
  │ ─────────────────────────────────→│ 영수증 검증
  │              결제 완료 확인         │
  │ ←─────────────────────────────────│
```

## 지도 기반 매물 클러스터링

부동산 매물은 특정 지역에 밀집되는 특성이 있어, 이를 효과적으로 시각화하기 위해 클러스터링을 설계했습니다.

### 목표

- 매물의 밀집도를 직관적으로 인지할 수 있을 것
- Zoom In/Out 시 UI Freezing이 없을 것

### 방안 탐색

| 방식 | 시간 복잡도 | 특징 |
|------|------------|------|
| 그리드 | O(n) | 바둑판처럼 인위적으로 보임 |
| DBSCAN | O(n²) | 실시간 인터랙션에 부적합 |
| 계층적 그리디 + KD-Tree | O(√n+k) | 원형 단위로 자연스러운 군집 |

### 최종 구조: 줌 레벨 구간별 클러스터링 모델 전환

- **저줌 구간 (Zoom 7~10)**: GeoJSON 행정구역(도) 폴리곤 기준으로 매물 수 집계 → O(n) 스캔
- **고줌 구간 (Zoom 11~16)**: KD-Tree 기반 공간 인덱싱으로 클러스터링

```
지도 진입 (한반도 Zoom Level)
         ↓
GeoJSON 경계 기반 도별 데이터 표시 ←──→ 백그라운드 KD-Tree 구축 (병렬)
         ↓
      Zoom in
         ↓
    트리 존재? ─── YES ──→ 클러스터 표시
         │
        NO
         ↓
해당 Zoom Level KD-Tree Lazy build
         ↓
    클러스터 표시
```

### 성능

- n=5,000 기준 전체 트리 빌드 약 0.1초 (서울 밀집 분포)
- 균등 분포 시 Lazy Build fallback으로 최대 대기 시간 약 2.8초

## 실시간 1:1 채팅

### Socket.IO 선택 이유

- 자동 재연결, 지수 백오프 기반 재시도, 네트워크 변화 감지, 전송 방식 폴백을 기본 제공
- 모바일 환경에서 빈번한 네트워크 전환에 안정적으로 대응

### 앱 생명주기 대응

```
Foreground(채팅방 진입) → Background(소켓 연결 해제) → Foreground(소켓 재연결 + 메시지 동기화)
```

- iOS는 백그라운드에서 소켓 연결 유지를 보장하지 않음
- 앱 상태 전환 시 명시적으로 연결 해제/재연결 처리
- 서버 측 CLOSE_WAIT 세션 방지

### 채팅방 로딩 순서

1. 소켓 연결 (실시간 수신 채널 확보)
2. 로컬 저장소 메시지 즉시 표시
3. 서버 동기화 (누락 메시지 보완)
4. 중복 메시지는 ID 기준 필터링

### 로컬 저장소: Realm 선택

| 작업 | Realm | CoreData |
|------|-------|----------|
| READ | 0.002s | 0.052s |
| UPDATE | 0.049s | 0.579s |
| DELETE | 0.016s | 0.701s |

*n=100,000 기준*

- 채팅에서 빈번한 조회·갱신·삭제 작업에 최적화
- Results 타입의 Lazy Loading 활용으로 성능 이점 극대화
- Thread-confined 특성은 값 타입 도메인 모델 변환으로 해결

### 읽지 않은 메시지 관리

- Push 수신: 다른 방 메시지면 unreadCount += 1
- 채팅방 입장: 전체 읽음 처리 + 마지막 읽은 시간 갱신
- 포그라운드 진입: 서버 업데이트 시간 비교 후 동기화

## 숏폼 비디오

- HLS(m3u8) 스트리밍으로 초기 로딩 시간 최소화
- WebVTT 기반 자막 파싱 및 재생 시간 동기화
- 화질 변경 시 재생 위치와 상태 유지

## 프로젝트 구조

```
Rewp/
├── App/                    # AppDelegate, SceneDelegate, AppContainer
├── Feature/                # 화면별 MVP 구조
│   ├── Feed/              # 홈 피드
│   ├── MapSearch/         # 지도 검색 + 클러스터링
│   ├── EstateDetail/      # 매물 상세
│   ├── ChatList/          # 채팅 목록
│   ├── ChatRoom/          # 채팅방
│   ├── Community/         # 커뮤니티
│   ├── Video/             # 숏폼 비디오
│   └── ...
├── Core/                   # 공통 인프라
│   ├── Network/           # API, Router, DTO
│   ├── Repository/        # 데이터 추상화
│   ├── Storage/           # Realm, Keychain
│   ├── Service/           # 도메인 서비스
│   └── ...
├── Component/              # 재사용 UI 컴포넌트
├── DesignSystem/           # 디자인 토큰
└── Resource/               # 폰트, GeoJSON
```
