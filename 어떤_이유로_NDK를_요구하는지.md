# Flutter 프로젝트가 NDK를 요구하는 이유를 찾는 방법

이 문서는 `flutter run`(또는 `flutter build`) 중 **“NDK가 필요하다 / Install NDK”** 메시지가 뜰 때,  
**왜 NDK가 필요한지(어떤 플러그인/설정 때문인지)** 를 빠르게 찾아내는 절차를 정리한 것입니다.

---

## 0) NDK가 “필요”해지는 대표 이유

아래 중 하나면 안드로이드 빌드가 네이티브(C/C++) 툴체인(=NDK)을 요구할 수 있습니다.

- 플러그인/라이브러리가 C/C++ 코드를 포함 (예: 이미지/영상/암호화/ML 계열)
- `CMakeLists.txt` 또는 `Android.mk`/`Application.mk` 사용
- `externalNativeBuild { cmake { ... } }` 또는 `ndkBuild` 설정
- 특정 AGP(Android Gradle Plugin) / 플러그인이 `ndkVersion`을 요구

---

## 1) 가장 먼저: 빌드 로그에서 “누가 NDK를 요구했는지” 추적

### A. verbose 로그로 실행
프로젝트 루트에서 아래를 실행해 로그를 풍부하게 만듭니다.

```powershell
flutter run -v
```

### B. 로그에서 키워드 검색
출력에서 아래 키워드를 찾아보세요.

- `ndkVersion`
- `externalNativeBuild`
- `CMake`
- `ndk-build`
- `Prefab`
- `jniLibs`
- `No version of NDK matched`
- `NDK is missing` / `NDK not configured`

> 보통 “어떤 모듈(:app, :xxx 플러그인)”에서 NDK를 요구하는지 라인이 나옵니다.

---

## 2) Gradle 설정에서 NDK 요구 여부 확인 (가장 확실)

### A. `android/app/build.gradle` 또는 `android/build.gradle` 확인
아래 항목이 있으면, **프로젝트(또는 플러그인)가 특정 NDK 버전을 요구**하는 것입니다.

- `ndkVersion "..."`

예시:

```gradle
android {
  ndkVersion "25.2.9519653"
}
```

### B. `externalNativeBuild` 확인
아래가 있으면 CMake/ndk-build가 들어간 네이티브 빌드가 존재합니다.

```gradle
android {
  externalNativeBuild {
    cmake {
      path "CMakeLists.txt"
    }
  }
}
```

---

## 3) “어떤 플러그인 때문에?”를 찾는 빠른 방법 (플러그인/모듈 추적)

### A. `.pub-cache`에서 Android 네이티브 흔적 찾기
(대개 플러그인 내부에 `CMakeLists.txt`, `src/main/cpp`, `Android.mk` 등이 있으면 NDK 요구 가능성이 큽니다)

- `CMakeLists.txt`
- `Android.mk`, `Application.mk`
- `src/main/cpp`
- `jniLibs`
- `prefab`

### B. Gradle 모듈 목록/의존성 확인
`android` 폴더에서:

```powershell
cd android
.\gradlew :app:dependencies
```

또는 특정 변형으로:

```powershell
.\gradlew :app:dependencies --configuration debugRuntimeClasspath
```

출력에 “어떤 라이브러리/플러그인”이 들어오는지 확인할 수 있습니다.

---

## 4) 설치를 유도하는 NDK “버전”은 어떻게 결정되나?

보통 아래 우선순위로 결정됩니다.

1. `ndkVersion`이 `build.gradle`에 명시되어 있으면 그 버전
2. 플러그인/AGP가 요구하는 기본/호환 버전
3. 로컬에 설치된 NDK 중 적절한 버전 선택

---

## 5) 체크리스트 (원인 확정용)

아래 항목 중 “예”가 나오면, NDK 요구 이유를 거의 확정할 수 있습니다.

- [ ] `android/app/build.gradle`에 `ndkVersion`이 있다
- [ ] `externalNativeBuild` / `CMakeLists.txt`가 있다
- [ ] 특정 플러그인 폴더에 `src/main/cpp` 또는 `Android.mk`가 있다
- [ ] `flutter run -v` 로그에 “어떤 모듈(:app 또는 :플러그인)”이 NDK를 요구한다고 나온다

---

## 6) 사용자에게서 받으면 바로 원인 판별 가능한 자료 (추천)

아래 중 하나만 공유해도 “왜 NDK가 필요한지”를 대부분 정확히 집어낼 수 있습니다.

1) `flutter run -v` 로그에서 **NDK/CMake 관련 경고·에러 라인 20~50줄**  
2) `android/app/build.gradle`의 `android { ... }` 블록(특히 `ndkVersion`, `externalNativeBuild` 포함 부분)  
3) 설치를 요구한 NDK 버전 문자열(예: `ndk;25.2.9519653`)

---

## 참고: NDK는 “만들어지는” 것이 아니라 “설치되는” 것입니다

NDK는 Google이 배포하는 SDK 구성요소이며, 로컬에서 생성하는 패키지가 아닙니다.  
`flutter run` 과정에서의 “Install NDK”는 Gradle/AGP가 필요한 NDK를 SDK Manager(sdkmanager/Android Studio)로 설치하도록 유도하는 흐름입니다.
