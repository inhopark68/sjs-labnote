# Git에서 user.name 및 user.email 설정하기

Git에서 `user.name`과 `user.email`을 설정해야 한다는 메시지는 보통
커밋을 할 때 Git이 **작성자 정보를 모르기 때문에** 나타납니다.\
Git은 모든 커밋에 작성자의 이름과 이메일을 기록해야 합니다.

------------------------------------------------------------------------

## 1. 전역(Global) 설정 -- 대부분 이 방법 사용

컴퓨터 전체 Git에 적용됩니다.

``` bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

예시:

``` bash
git config --global user.name "Hong Gil Dong"
git config --global user.email "hong@example.com"
```

------------------------------------------------------------------------

## 2. 현재 저장소(Local)만 설정

특정 프로젝트에서만 다른 정보를 사용하고 싶다면 다음과 같이 설정합니다.

``` bash
git config user.name "Your Name"
git config user.email "you@example.com"
```

------------------------------------------------------------------------

## 3. 설정 확인

현재 설정된 값을 확인하려면:

``` bash
git config --list
```

또는

``` bash
git config user.name
git config user.email
```

------------------------------------------------------------------------

## 4. 왜 필요한가

Git 커밋에는 다음 정보가 저장됩니다.

-   작성자 이름 (`user.name`)
-   작성자 이메일 (`user.email`)
-   커밋 시간
-   커밋 메시지

예시:

    Author: Hong Gil Dong <hong@example.com>
    Date:   Fri Mar 6

------------------------------------------------------------------------

## 팁 (GitHub 사용하는 경우)

GitHub 계정 이메일을 사용하는 것이 일반적입니다.

``` bash
git config --global user.email "your_github_email"
```

또는 GitHub의 **noreply 이메일**을 사용할 수도 있습니다.
