# Flutter + Android (Windows 10/11) 개발 환경 설정 가이드

## 1. 필수 설치

### 1-1. Flutter SDK 설치

1.  Flutter SDK zip 다운로드

2.  예: `C:\src\flutter` 경로에 압축 해제 (공백/한글 없는 경로 권장)

3.  환경 변수 PATH에 추가:

        C:\src\flutter\bin

4.  PowerShell에서 확인:

    ``` powershell
    flutter --version
    ```

------------------------------------------------------------------------

### 1-2. Android Studio 설치 (권장)

1.  Android Studio 설치 후 실행
2.  SDK 설치 진행
3.  SDK Manager에서 아래 항목 확인:
    -   Android SDK Platform
    -   Android SDK Build-Tools
    -   Android SDK Platform-Tools (adb)

------------------------------------------------------------------------

### 1-3. VS Code + 확장 설치

1.  VS Code 설치
2.  확장(Extensions)에서 설치:
    -   Flutter
    -   Dart

------------------------------------------------------------------------

## 2. Flutter 상태 점검

``` powershell
flutter doctor -v
```

아래 항목이 모두 OK(초록색)인지 확인: - Flutter - Android toolchain - VS
Code

### Android 라이선스 문제 해결

``` powershell
flutter doctor --android-licenses
```

→ 전부 `y` 입력

------------------------------------------------------------------------

## 3. 스마트폰 연결 (USB 디버깅)

### 3-1. 스마트폰 설정

1.  설정 → 휴대전화 정보 → 빌드 번호 7번 터치
2.  개발자 옵션 활성화
3.  설정 → 개발자 옵션 → USB 디버깅 ON
4.  PC와 USB 연결
5.  "USB 디버깅 허용?" 팝업 → 허용

### 3-2. PC에서 연결 확인

``` powershell
adb devices
```

-   `device` 표시 → 정상 연결
-   `unauthorized` → 폰 화면에서 허용 확인

※ 데이터 전송 지원 USB 케이블 사용 권장

------------------------------------------------------------------------

## 4. Flutter 프로젝트 생성

### 방법 1: VS Code에서 생성

-   `Ctrl + Shift + P`
-   `Flutter: New Project`
-   Application 선택 후 생성

### 방법 2: PowerShell에서 생성

``` powershell
flutter create my_app
cd my_app
code .
```

------------------------------------------------------------------------

## 5. 스마트폰에서 앱 실행

VS Code에서 디바이스 선택 후:

-   실행: `F5` 또는:

``` powershell
flutter run
```

코드 수정 후 저장하면 Hot Reload 자동 적용

------------------------------------------------------------------------

## 6. APK 빌드 (배포용)

``` powershell
flutter build apk --release
```

생성 위치:

    build/app/outputs/flutter-apk/app-release.apk

------------------------------------------------------------------------

## 7. 자주 발생하는 오류

### Android toolchain not found

-   Android Studio 또는 SDK 미설치
-   `flutter doctor -v` 출력 확인

### adb not recognized

-   Platform-tools 미설치
-   Android SDK 경로 문제

### 폰이 인식되지 않음

-   충전 전용 케이블 사용
-   USB 디버깅 미허용
-   드라이버 문제

------------------------------------------------------------------------

## 완료 🎉

이제 Windows 10/11 환경에서 Android 스마트폰을 이용한 Flutter 앱 개발이
가능합니다.
