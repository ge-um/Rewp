# 렙 (Rewp)

반려동물과 함께 살 집을 구하는 iOS 앱

|구분|내용|
|:--:|:--|
|**팀 인원**|iOS 개발 1명, 백엔드 1명, 디자인 1명|
|**기획 및 개발 기간**|2025.12 ~ 2026.01|
|**최소 지원 버전**|iOS 16.0+|

## 핵심 기능
- 위치 기반 매물 클러스터링
- 매물 실시간 확인 및 필터링
- 실시간 1:1 채팅
- 카드 결제 (PG 결제) 및 영수증 검증
- HLS 스트리밍 기반 숏폼 비디오
- 부동산 커뮤니티 (게시글, 댓글, 답글, 좋아요)
- 카카오 / 애플 소셜 로그인

## 기술 스택
|분류|기술 스택|
|:--:|:--|
|**UI**|![UIKit](https://img.shields.io/badge/UIKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![PinLayout](https://img.shields.io/badge/PinLayout-FF6B6B?style=flat-square) ![FlexLayout](https://img.shields.io/badge/FlexLayout-4ECDC4?style=flat-square) ![Then](https://img.shields.io/badge/Then-9B59B6?style=flat-square)|
|**반응형 프로그래밍**|![RxSwift](https://img.shields.io/badge/RxSwift-B7178C?style=flat-square&logo=reactivex&logoColor=white) ![RxCocoa](https://img.shields.io/badge/RxCocoa-B7178C?style=flat-square&logo=reactivex&logoColor=white)|
|**데이터베이스**|![Realm](https://img.shields.io/badge/Realm-39477F?style=flat-square&logo=realm&logoColor=white)|
|**네트워크**|![Alamofire](https://img.shields.io/badge/Alamofire-FF6F61?style=flat-square) ![Kingfisher](https://img.shields.io/badge/Kingfisher-5AC8FA?style=flat-square) ![SocketIO](https://img.shields.io/badge/SocketIO-010101?style=flat-square&logo=socketdotio&logoColor=white) ![Network](https://img.shields.io/badge/Network-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**아키텍처 / 디자인 패턴**|![MVP](https://img.shields.io/badge/MVP_+_Input/Output-6DB33F?style=flat-square) ![Repository](https://img.shields.io/badge/Repository_Pattern-6DB33F?style=flat-square) ![Router](https://img.shields.io/badge/Router_Pattern-6DB33F?style=flat-square)|
|**인증**|![KakaoSDK](https://img.shields.io/badge/KakaoSDK-FFCD00?style=flat-square&logo=kakao&logoColor=black) ![AuthenticationService](https://img.shields.io/badge/AuthenticationService-000000?style=flat-square&logo=apple&logoColor=white)|
|**Firebase**|![FCM](https://img.shields.io/badge/Cloud_Messaging-FFCA28?style=flat-square&logo=firebase&logoColor=black)|
|**프레임워크**|![MapKit](https://img.shields.io/badge/MapKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![CoreLocation](https://img.shields.io/badge/CoreLocation-007AFF?style=flat-square&logo=apple&logoColor=white) ![PhotosUI](https://img.shields.io/badge/PhotosUI-007AFF?style=flat-square&logo=apple&logoColor=white) ![WebKit](https://img.shields.io/badge/WebKit-007AFF?style=flat-square&logo=apple&logoColor=white) ![UserNotifications](https://img.shields.io/badge/UserNotifications-007AFF?style=flat-square&logo=apple&logoColor=white)|
|**기타**|![OSLog](https://img.shields.io/badge/OSLog-007AFF?style=flat-square&logo=apple&logoColor=white) ![Keychain](https://img.shields.io/badge/Keychain-007AFF?style=flat-square&logo=apple&logoColor=white)|

## 전체 구조

### MVP + Input/Output
- View와 비즈니스 로직을 분리하고, 단방향 데이터 흐름 유지
- Presenter는 View를 직접 참조하지 않고 Input을 받아 Output으로 변환
- 의존성은 Protocol 기반으로 정의하고 생성 시점에 주입 (DI)

### Container + Factory
- 네트워크, 인증, 레포지토리 등 공통 인프라는 Protocol로 추상화
- AppContainer에서 실제 구현체를 생성·관리
- 각 화면은 Factory를 통해 필요한 의존성만 주입

### Networking
#### Interceptor 패턴 기반 토큰(JWT) 갱신 시스템
- Alamofire AuthenticationInterceptor로 Access Token 자동 주입
- accessToken 만료(401/419) 시 refreshToken으로 자동 갱신
- 갱신 실패 시 Keychain 정리 후 로그인 화면 전환

#### 카드 결제
- 클라이언트 결제 성공 응답만으로 신뢰하지 않음
- 서버가 PG사에 직접 영수증 검증 후 결제 완료 판단

## 주요 기능

### 지도 기반 매물 클러스터링
- 계층적 그리디 + KD-Tree 방식으로 O(√n+k) 조회 성능 달성
- 줌 레벨 구간별 클러스터링 모델 전환
  - 저줌 구간 (Zoom 7~10): GeoJSON 행정구역(도) 폴리곤 기준 O(n) 스캔
  - 고줌 구간 (Zoom 11~16): KD-Tree 기반 공간 인덱싱
- 백그라운드 KD-Tree 구축 + Lazy Build fallback
- n=5,000 기준 트리 빌드 약 0.1초 (서울 밀집 분포)

### 실시간 1:1 채팅
- Socket.IO 기반 실시간 통신 (자동 재연결, 지수 백오프 재시도)
- 앱 생명주기 대응: 백그라운드 진입 시 소켓 해제, 포그라운드 복귀 시 재연결 + 동기화
- Realm 기반 로컬 저장소 (n=100,000 기준 READ 0.002s, UPDATE 0.049s)
- 읽지 않은 메시지 관리: Push 수신 / 채팅방 입장 / 포그라운드 진입 시점별 처리

### 숏폼 비디오
- HLS(m3u8) 스트리밍으로 초기 로딩 시간 최소화
- WebVTT 기반 자막 파싱 및 재생 시간 동기화
- 화질 변경 시 재생 위치와 상태 유지

### 부동산 커뮤니티
- 게시글 작성 / 댓글 / 답글 / 좋아요
- 좋아요 낙관적 UI 적용

### 피드
- 배너, Hot 매물, 토픽별 매물 표시
- 최근 본 매물 로컬 저장

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
