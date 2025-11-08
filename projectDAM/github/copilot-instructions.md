flowchart TD
  %% Project root
  subgraph projectDAM["projectDAM"]
    direction TB

    %% Folders / files
    subgraph Resources["Resources/"]
      direction TB
      Assets["Assets.xcassets"]
      Launch["LaunchScreen.storyboard"]
    end

    subgraph Models["Models/ (data models)"]
      direction TB
      User["User.swift"]
      Product["Product.swift"]
    end

    subgraph Views["Views/ (UI: SwiftUI / UIKit)"]
      direction TB
      LoginView["LoginView.swift"]
      UserView["UserViewController.swift"]
      SharedView["CommonViews/"]
    end

    subgraph ViewModels["ViewModels/ (presentation & logic)"]
      direction TB
      LoginVM["LoginViewModel.swift"]
      UserVM["UserViewModel.swift"]
      ListVM["ListViewModel.swift"]
    end

    subgraph Services["Services/ (network, repos, persistence)"]
      direction TB
      NetworkSvc["NetworkService.swift"]
      AuthSvc["AuthService.swift"]
      Repo["Repository.swift"]
    end

    subgraph DI["DI/ (dependency injection)"]
      direction TB
      DIContainer["DIContainer.swift"]
    end

    subgraph Utilities["Utilities/ (helpers, extensions)"]
      direction TB
      Logger["Logger.swift"]
      Extensions["Extensions.swift"]
    end

    subgraph Tests["Tests/ (unit & integration)"]
      direction TB
      LoginTests["LoginViewModelTests.swift"]
      NetworkTests["NetworkServiceTests.swift"]
    end

    subgraph Supporting["Supporting Files/"]
      direction TB
      InfoPlist["Info.plist"]
      AppDelegate["AppDelegate.swift"]
      SceneDelegate["SceneDelegate.swift"]
    end
  end

  %% Relationships (arrows)
  Views -->|binds to / observes| ViewModels
  ViewModels -->|reads/writes| Models
  ViewModels -->|calls / depends on| Services
  Services -->|performs network I/O| NetworkSvc
  DIContainer -->|injects into| ViewModels
  DIContainer -->|injects into| Services
  Resources -->|assets used by| Views
  Utilities -->|helpers used by| ViewModels & Views
  Tests -->|verify behavior of| ViewModels & Services
  Supporting -->|app lifecycle & config| Views & ViewModels

  %% Rule / legend node
  rules["Project Rules (quick):\n• Follow MVVM strictly.\n• Business logic only in ViewModels.\n• Networking & persistence in Services.\n• Use DIContainer for all deps.\n• Every feature -> View + ViewModel (+ Service if needed) + tests.\n• Use // MARK: and /// doc comments."]:::note

  rules -.-> projectDAM

  classDef folder fill:#f3f4f6,stroke:#111,stroke-width:1px;
  class Resources,Models,Views,ViewModels,Services,DI,Utilities,Tests,Supporting folder;
  classDef note fill:#fff7c0,stroke:#b08900,stroke-width:1px;
