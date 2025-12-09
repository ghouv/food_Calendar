# Codex Instructions

## 프로젝트 개요
- 이 리포지토리는 **iOS 앱**을 위한 Swift 프로젝트다.
- UI는 **SwiftUI**를 기본으로 사용한다.
- 타깃 OS: **iOS 17 이상**.
- 아키텍처는 **MVVM-ish (View + ViewModel + Model)** 스타일을 선호한다.

## 기술 스택 & 규칙
- UI: **SwiftUI** 사용, 특별한 이유가 없다면 UIKit / Storyboard / XIB는 사용하지 않는다.
- 비동기 작업: **Swift Concurrency (async/await, Task)**를 우선 사용한다.
- 의존성:
  - 우선 **표준 라이브러리 + Apple 프레임워크**로 구현을 시도한다.
  - 외부 라이브러리가 필요할 경우, 먼저 코드에 TODO로 제안만 하고 임의로 패키지를 추가하지 않는다.
- 언어:
  - **코드는 영어**로 작성한다. (타입, 변수, 함수 이름 등)
  - **주석과 설명은 한국어로 작성해도 된다.**

## 코드 스타일
- 타입/파일 이름:
  - View: `XXXView`
  - ViewModel: `XXXViewModel`
  - Model: `XXX`, `XXXModel`
- 파일 분리:
  - 하나의 Swift 파일에는 **하나의 주요 타입**만 정의하는 것을 선호한다.
  - View가 커질 경우, 하위 컴포넌트를 별도 파일의 서브뷰로 분리한다.
- 네이밍:
  - 명확하고 의미 있는 이름을 사용한다. (`data1`, `tmp` 등의 모호한 이름은 피한다.)
  - 비동기 메서드는 `async` 느낌이 드는 이름을 붙인다. (예: `fetchFlights()`, `loadMeals()`)

## 디렉터리 구조
가능한 한 아래 구조를 유지하면서 코드를 추가/수정한다.

```text
ProjectRoot/
 ├─ App/
 │   └─ ProjectApp.swift        // @main 진입점
 ├─ Models/                     // 데이터 모델
 ├─ ViewModels/                 // 상태 및 비즈니스 로직
 ├─ Views/                      // SwiftUI 화면
 │   ├─ Common/                 // 공용 컴포넌트
 │   └─ Screens/                // 개별 화면(Feature별 하위 폴더 가능)
 ├─ Services/                   // 네트워크, 로컬 저장소 등
 └─ Resources/                  // 에셋, 폰트, JSON 등
