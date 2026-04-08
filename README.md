<div align="center">

<img src="projectDAM/Assets.xcassets/tache_lik_logo.imageset/AppLogo.png" width="140" alt="TacheLik Logo" />

# TacheLik iOS

### A premium iOS learning experience — built with SwiftUI, MVVM, and real-time capabilities.

<p>
  <a href="#screenshots">Screenshots</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#team--contributors">Team</a>
</p>

![iOS](https://img.shields.io/badge/iOS-15%2B-black)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Yes-0A84FF)
![Architecture](https://img.shields.io/badge/Architecture-MVVM%20%2B%20DI-informational)
![Realtime](https://img.shields.io/badge/Realtime-Socket.IO-blueviolet)
![Dark%20Mode](https://img.shields.io/badge/Dark%20Mode-Supported-111827)
![Status](https://img.shields.io/badge/Status-Product%20Ready-success)

</div>

---

## 🚀 Overview

**TacheLik iOS** is the native iOS client for the TacheLik platform. It delivers a role-based learning experience (**Student / Teacher / Admin**) with:

- Fast, modern SwiftUI UI
- Secure authentication and verification flows
- Real-time interactions via Socket.IO
- Feature modularity through MVVM + Services + DI

---

## ✨ Core Features

- Role-based app shell (Student / Teacher / Admin)
- Authentication + email verification (including 6-digit code flows)
- Real-time session state + messaging foundations (Socket.IO)
- Caching for resilience and performance (Caches directory)
- Consistent theming and navigation appearance across iOS versions

---

## 📱 Screenshots

Key screens (most representative flows across roles):

<div style="overflow-x:auto;">
  <table>
    <tr>
      <td><img src="screenshots/login.png" width="250" alt="Login" /></td>
      <td><img src="screenshots/student/student-home-light.png" width="250" alt="Student Home" /></td>
      <td><img src="screenshots/student/student-course-light.png" width="250" alt="Course Details" /></td>
      <td><img src="screenshots/student/student-chat-light.png" width="250" alt="Chat" /></td>
      <td><img src="screenshots/teacher/teacher-home-light.png" width="250" alt="Teacher Dashboard" /></td>
      <td><img src="screenshots/admin/admin-home-light.png" width="250" alt="Admin Dashboard" /></td>
    </tr>
  </table>
</div>

### 🧩 Student Features

<div style="overflow-x:auto;">
  <table>
    <tr>
      <td><img src="screenshots/student/student-classes-light.png" width="240" alt="Student Classes" /></td>
      <td><img src="screenshots/student/student-explore-light.png" width="240" alt="Student Explore" /></td>
      <td><img src="screenshots/student/student-messaging-light.png" width="240" alt="Student Messaging" /></td>
      <td><img src="screenshots/student/student-quiz-light.png" width="240" alt="Student Quiz" /></td>
      <td><img src="screenshots/student/student-wallet-light.png" width="240" alt="Student Wallet" /></td>
      <td><img src="screenshots/student/student-myBadges-light.png" width="240" alt="Student Badges" /></td>
    </tr>
  </table>
</div>

### 🧠 AI Experiences

<div style="overflow-x:auto;">
  <table>
    <tr>
      <td><img src="screenshots/student/student-AIGame-light.png" width="240" alt="AI Game" /></td>
      <td><img src="screenshots/student/student-generateReelAI-light.png" width="240" alt="AI Reel Generation" /></td>
      <td><img src="screenshots/student/student-generateQuizAI-light.png" width="240" alt="AI Quiz Generation" /></td>
    </tr>
  </table>
</div>

### 🧑‍🏫 Teaching Tools

<div style="overflow-x:auto;">
  <table>
    <tr>
      <td><img src="screenshots/teacher/teacher-myClasses-light.png" width="240" alt="Teacher My Classes" /></td>
    </tr>
  </table>
</div>

---

## 🛠️ Tech Stack

- **Language:** Swift
- **UI:** SwiftUI (UIKit bridging for navigation chrome where needed)
- **Architecture:** MVVM + Dependency Injection (`DIContainer`)
- **Networking:** `URLSession` + async/await (`NetworkService`)
- **Realtime:** Socket.IO (`SocketService`)
- **Persistence:**
  - Preferences and session flags: `AppStorage` / `UserDefaults`
  - Caches (non-sensitive): Caches directory (`HomeCacheStore`, `TeacherCourseContentCache`)
  - Core Data: stack scaffold (`PersistenceController`)
- **Testing:** XCTest (`projectDAMTests`)

---

## 🧠 Architecture

This project uses MVVM to keep screens **declarative**, state **testable**, and networking **centralized**.

```mermaid
flowchart LR
  V[View] --> VM[ViewModel]
  VM --> S[Service]
  S --> N[NetworkService]
  N --> API[(REST API)]

  VM --> SO[SocketService]
  SO --> RT[(Realtime Server)]
```

Key architecture properties:

- Clear View ↔ ViewModel ↔ Service separation
- Dependencies assembled in `DIContainer`
- Protocol-driven services support mocking in tests

---

## 📁 Folder Structure (Quick View)

```text
TacheLik_iosApp/
  projectDAM/
    Views/
    ViewModels/
    Services/
    DI/
    Theme/
    Utilities/ Utils/
    Models/
    Config/
    Assets.xcassets/
  projectDAMTests/
  Config.xcconfig
  Config.local.xcconfig
  screenshots/
```

---

## 🧭 Getting Started

### Prerequisites

- Xcode 15+ (recommended)
- iOS 15+ deployment target
- Backend API reachable from simulator/device

### Run

1. Open `projectDAM.xcodeproj` in Xcode.
2. Select the `projectDAM` scheme.
3. Run (⌘R).

---

## 🌍 Environment Configuration

This app uses **xcconfig** + **Info.plist** substitution.

- `Config.xcconfig`: default config (tracked)
- `Config.local.xcconfig`: local overrides (not committed)
- `projectDAM/Info.plist`: reads `API_BASE_URL` and `USE_MOCK_DATA`

Common setup:

- `API_BASE_URL`: `https://dev.api.tache-lik.tn/api`
- `USE_MOCK_DATA`: `false`

---

## 🔐 Security

Security posture is documented with a clear distinction between **current implementation** and **product-ready recommendations**.

- Token storage is currently `UserDefaults` (recommended: Keychain)
- ATS is currently permissive (recommended: tighten in Release)

---

## 📚 Documentation

Official product-ready documentation lives here:

- Documentation entry point: [Documentation/README.md](Documentation/README.md)

Additional developer/implementation notes (work-in-progress/internal) live here:

- Engineering notes entry point: [projectDAM/Docs/00_START_HERE.md](projectDAM/Docs/00_START_HERE.md)

Quick links:

- [Documentation/Project-Overview.md](Documentation/Project-Overview.md)
- [Documentation/Architecture.md](Documentation/Architecture.md)
- [Documentation/Networking.md](Documentation/Networking.md)
- [Documentation/Security.md](Documentation/Security.md)
- [Documentation/Testing.md](Documentation/Testing.md)

---

## 🏆 Our SDG Contributions

<div align="center">

| SDG Goal | Our Impact |
| --- | --- |
| **SDG 4 — Quality Education** | Mobile-first learning experiences, quizzes, and progress flows that promote consistent access to educational content. |
| **SDG 9 — Industry, Innovation & Infrastructure** | Scalable client architecture (MVVM + DI + services) enabling rapid feature evolution and maintainability. |
| **SDG 10 — Reduced Inequalities** | Cross-role access patterns and mobile usability improvements support broader access to learning services. |
| **SDG 12 — Responsible Consumption & Production** | Caching reduces unnecessary network usage and improves efficiency on constrained connections. |

</div>

### 🌱 Sustainability Initiatives

- Efficient caching to reduce repeated requests
- Lightweight networking patterns and controlled logging in Debug only
- UI designed to stay usable in low-connectivity conditions

---

## 🛠️ Advanced Technology Stack

This repository represents a broader product ecosystem beyond iOS. The following stack reflects the wider platform technologies used across the project.

<div align="center">
  <img src="https://skillicons.dev/icons?i=swift,apple,kotlin,androidstudio,react,nodejs,typescript,express,mysql,redis,nginx" alt="Tech Stack" />
</div>

Aligned with the codebase:

- **iOS:** Swift + SwiftUI (MVVM + DI), URLSession async/await, Socket.IO
- **Web:** React (socket.io-client, axios)
- **Backend:** Node.js + TypeScript (Express, Socket.IO, TypeORM)
- **Data/Infra:** MySQL, Redis, Nginx

---

## 🔗 Related Repository

- Android app: https://github.com/HamaBTW/TacheLik_androidApp

---

## 👨‍💻 Team & Contributors

<table align="center">
  <tr>
    <td align="center" width="180">
      <a href="https://github.com/fekikarim">
        <img src="https://github.com/fekikarim.png" width="96" height="96" alt="Karim Feki" />
      </a>
      <br />
      <b>Karim Feki</b>
      <br />
      <a href="https://www.linkedin.com/in/karimfeki/" title="LinkedIn">
        <img src="https://skillicons.dev/icons?i=linkedin" width="20" height="20" alt="LinkedIn" />
      </a>
      &nbsp;
      <a href="https://github.com/fekikarim" title="GitHub">
        <img src="https://skillicons.dev/icons?i=github" width="20" height="20" alt="GitHub" />
      </a>
      &nbsp;
      <a href="mailto:feki.karim28@gmail.com" title="Email">✉️</a>
    </td>
    <td align="center" width="180">
      <a href="https://github.com/nesrine77">
        <img src="https://github.com/nesrine77.png" width="96" height="96" alt="Nesrine Derouiche" />
      </a>
      <br />
      <b>Nesrine Derouiche</b>
      <br />
      <a href="https://www.linkedin.com/in/nesrine-derouiche/" title="LinkedIn">
        <img src="https://skillicons.dev/icons?i=linkedin" width="20" height="20" alt="LinkedIn" />
      </a>
      &nbsp;
      <a href="https://github.com/nesrine-derouiche" title="GitHub">
        <img src="https://skillicons.dev/icons?i=github" width="20" height="20" alt="GitHub" />
      </a>
      &nbsp;
      <a href="mailto:nesrine.derouiche15@gmail.com" title="Email">✉️</a>
    </td>
    <td align="center" width="180">
      <a href="https://github.com/hamabtw">
        <img src="https://github.com/hamabtw.png" width="96" height="96" alt="Mohamed Abidi" />
      </a>
      <br />
      <b>Mohamed Abidi</b>
      <br />
      <a href="https://www.linkedin.com/in/med-abidi/" title="LinkedIn">
        <img src="https://skillicons.dev/icons?i=linkedin" width="20" height="20" alt="LinkedIn" />
      </a>
      &nbsp;
      <a href="https://github.com/hamabtw" title="GitHub">
        <img src="https://skillicons.dev/icons?i=github" width="20" height="20" alt="GitHub" />
      </a>
      &nbsp;
      <a href="mailto:abidi.mohamed.1@esprit.tn" title="Email">✉️</a>
    </td>
    <td align="center" width="180">
      <a href="https://github.com/oussemissaoui">
        <img src="https://github.com/oussemissaoui.png" width="96" height="96" alt="Oussema Issaoui" />
      </a>
      <br />
      <b>Oussema Issaoui</b>
      <br />
      <span title="LinkedIn">—</span>
      &nbsp;
      <a href="https://github.com/oussemissaoui" title="GitHub">
        <img src="https://skillicons.dev/icons?i=github" width="20" height="20" alt="GitHub" />
      </a>
      &nbsp;
      <a href="mailto:oussema.issaoui@esprit.tn" title="Email">✉️</a>
    </td>
  </tr>
</table>

### 🙏 Mentor

Special thanks to our mentor **Khaled Guedria** for the guidance, feedback, and great mentoring throughout the project:

- https://github.com/khaledGuedria17

### 📇 Contacts

| Name | LinkedIn | GitHub | Email |
|---|---|---|---|
| Karim Feki | <a href="https://www.linkedin.com/in/karimfeki/" title="LinkedIn"><img src="https://skillicons.dev/icons?i=linkedin" width="18" height="18" alt="LinkedIn" /></a> | <a href="https://github.com/fekikarim" title="GitHub"><img src="https://skillicons.dev/icons?i=github" width="18" height="18" alt="GitHub" /></a> | <a href="mailto:feki.karim28@gmail.com" title="Email">✉️</a> |
| Nesrine Derouiche | <a href="https://www.linkedin.com/in/nesrine-derouiche/" title="LinkedIn"><img src="https://skillicons.dev/icons?i=linkedin" width="18" height="18" alt="LinkedIn" /></a> | <a href="https://github.com/nesrine-derouiche" title="GitHub"><img src="https://skillicons.dev/icons?i=github" width="18" height="18" alt="GitHub" /></a> | <a href="mailto:nesrine.derouiche15@gmail.com" title="Email">✉️</a> |
| Mohamed Abidi | <a href="https://www.linkedin.com/in/med-abidi/" title="LinkedIn"><img src="https://skillicons.dev/icons?i=linkedin" width="18" height="18" alt="LinkedIn" /></a> | <a href="https://github.com/hamabtw" title="GitHub"><img src="https://skillicons.dev/icons?i=github" width="18" height="18" alt="GitHub" /></a> | <a href="mailto:abidi.mohamed.1@esprit.tn" title="Email">✉️</a> |
| Oussema Issaoui | — | <a href="https://github.com/oussemissaoui" title="GitHub"><img src="https://skillicons.dev/icons?i=github" width="18" height="18" alt="GitHub" /></a> | <a href="mailto:oussema.issaoui@esprit.tn" title="Email">✉️</a> |

---

## 📬 Support

- For iOS issues: open a GitHub issue and include iOS version + device + reproduction steps.
- For API issues: verify `API_BASE_URL` first and share endpoint + response status.

---

## 📦 License

This project is released under the **MIT License**. See [LICENSE](LICENSE).

---

<div align="center">
  <sub><i>Keep learning. Keep building. Keep shipping.</i></sub>
</div>

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&height=120&section=footer" alt="Waving footer" />
