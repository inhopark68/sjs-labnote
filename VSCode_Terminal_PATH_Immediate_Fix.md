flutt# VS Code 터미널 PATH 즉시 복구 (1분)

아래 내용은 **VS Code 통합 터미널(PowerShell)** 에서 PATH가 `C:\Windows\System32` 같은 기본 경로까지 사라져  
`where.exe` / `git` / `flutter` 등이 제대로 동작하지 않을 때, **현재 터미널 세션에서만 임시로** 정상화하는 방법입니다.  
(영구 해결은 별도입니다.)

---

## 1) 즉시 복구 명령 (그대로 복사해서 실행)

> VS Code 터미널(PowerShell)에서 아래를 그대로 실행하세요.

```powershell
# 1) Windows 기본 경로 복구 (where.exe 등 기본 명령 되살리기)
$env:Path = "C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;" + $env:Path

# 2) Git 경로 추가(기본 설치 위치 기준)
$env:Path += ";C:\Program Files\Git\cmd"

# 3) 확인
where.exe where
where.exe git
git --version
flutter --version
```

---

## 2) 결과 해석

- `where.exe where` 가 경로를 출력하면  
  → **System32 경로 복구 성공**
- `git --version` 이 정상 출력되면  
  → **Git PATH 복구 성공**
- `flutter --version` 이 정상 출력되면  
  → **Flutter도 정상 동작**

---

## 3) Git 설치 위치가 기본 경로가 아닐 때

Git이 다른 위치에 설치되어 있으면 `where.exe git` 가 안 나올 수 있습니다.  
그럴 땐 아래로 설치 파일 존재 여부를 확인하세요.

```powershell
Test-Path "C:\Program Files\Git\cmd\git.exe"
Test-Path "C:\Program Files\Git\bin\git.exe"
```

- 둘 중 하나가 `True`면, 해당 폴더를 PATH에 추가하면 됩니다. 예:

```powershell
$env:Path += ";C:\Program Files\Git\cmd"
```

---

## 4) 중요: 이 방법은 “현재 터미널 세션만” 임시 복구입니다

VS Code를 닫거나 새 터미널을 열면 다시 PATH가 꼬일 수 있습니다.  
영구 해결(원인 제거/환경변수 복구)은 별도로 진행해야 합니다.
