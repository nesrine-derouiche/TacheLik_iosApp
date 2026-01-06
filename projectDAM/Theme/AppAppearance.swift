import SwiftUI
import UIKit

// Centralized navigation appearance + container to keep headers consistent.

enum AppNavigationBarStyle {
    case standard
    case transparent
    case hidden
}

struct AppNavigationContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
            .appNavigationBarStyle(.standard)
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(.stack)
            .appNavigationBarStyle(.standard)
        }
    }
}

private final class NavigationBarConfigViewController: UIViewController {
    var style: AppNavigationBarStyle = .standard
    var interfaceStyle: UIUserInterfaceStyle = .unspecified
    private var didScheduleRetry = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        apply()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        apply()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        apply()
    }

    func apply() {
        guard let navigationController = self.findNavigationController() else {
            if !didScheduleRetry {
                didScheduleRetry = true
                DispatchQueue.main.async { [weak self] in
                    self?.apply()
                }
            }
            return
        }
        didScheduleRetry = false

        // Ensure UIKit resolves dynamic colors with the correct scheme.
        navigationController.overrideUserInterfaceStyle = self.interfaceStyle

        let appearance = UINavigationBarAppearance()
        switch self.style {
        case .standard:
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .appNavBarBackground
            appearance.shadowColor = .appDivider
        case .transparent:
            appearance.configureWithTransparentBackground()
            appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
            appearance.backgroundColor = .appNavBarGlassBackground
            appearance.shadowColor = .appDivider
        case .hidden:
            appearance.configureWithTransparentBackground()
        }

        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

        navigationController.navigationBar.isTranslucent = (self.style != .standard)

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.prefersLargeTitles = true

        switch self.style {
        case .hidden:
            navigationController.setNavigationBarHidden(true, animated: false)
        case .standard, .transparent:
            navigationController.setNavigationBarHidden(false, animated: false)
        }
    }

    private func findNavigationController() -> UINavigationController? {
        if let nav = navigationController { return nav }
        var current = parent
        while let node = current {
            if let nav = node.navigationController { return nav }
            current = node.parent
        }
        return nil
    }
}

private struct NavigationBarConfigurator: UIViewControllerRepresentable {
    @Environment(\.colorScheme) private var colorScheme
    let style: AppNavigationBarStyle

    func makeUIViewController(context: Context) -> NavigationBarConfigViewController {
        NavigationBarConfigViewController()
    }

    func updateUIViewController(_ uiViewController: NavigationBarConfigViewController, context: Context) {
        uiViewController.style = style
        uiViewController.interfaceStyle = (colorScheme == .dark) ? .dark : .light
        uiViewController.apply()
    }
}

struct AppNavigationBarStyleModifier: ViewModifier {
    let style: AppNavigationBarStyle

    func body(content: Content) -> some View {
        content
            .background(NavigationBarConfigurator(style: style))
    }
}

private final class NavigationItemTitleViewController: UIViewController {
    var titleText: String = ""
    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode = .automatic
    private var didScheduleRetry = false
    private var didScheduleReapply = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        apply()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        apply()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        apply()
    }

    func apply() {
        guard let navigationController = self.findNavigationController() else {
            if !didScheduleRetry {
                didScheduleRetry = true
                DispatchQueue.main.async { [weak self] in
                    self?.apply()
                }
            }
            return
        }
        didScheduleRetry = false

        // Only mutate the title of the currently visible screen.
        guard let topViewController = navigationController.topViewController else {
            if !didScheduleRetry {
                didScheduleRetry = true
                DispatchQueue.main.async { [weak self] in
                    self?.apply()
                }
            }
            return
        }
        topViewController.navigationItem.title = titleText
        topViewController.navigationItem.largeTitleDisplayMode = largeTitleDisplayMode

        // SwiftUI can occasionally overwrite the title after we've set it.
        // Re-apply on the next runloop to stabilize.
        if !didScheduleReapply {
            didScheduleReapply = true
            DispatchQueue.main.async { [weak self] in
                self?.didScheduleReapply = false
                self?.apply()
            }
        }
    }

    private func findNavigationController() -> UINavigationController? {
        if let nav = navigationController { return nav }
        var current = parent
        while let node = current {
            if let nav = node.navigationController { return nav }
            current = node.parent
        }
        return nil
    }
}

private struct NavigationItemTitleConfigurator: UIViewControllerRepresentable {
    let title: String
    let largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode

    func makeUIViewController(context: Context) -> NavigationItemTitleViewController {
        NavigationItemTitleViewController()
    }

    func updateUIViewController(_ uiViewController: NavigationItemTitleViewController, context: Context) {
        uiViewController.titleText = title
        uiViewController.largeTitleDisplayMode = largeTitleDisplayMode
        uiViewController.apply()
    }
}

extension View {
    func appNavigationBarStyle(_ style: AppNavigationBarStyle) -> some View {
        modifier(AppNavigationBarStyleModifier(style: style))
    }

    func appForceNavigationTitle(
        _ title: String,
        displayMode: UINavigationItem.LargeTitleDisplayMode = .automatic
    ) -> some View {
        background(NavigationItemTitleConfigurator(title: title, largeTitleDisplayMode: displayMode))
    }

    func appHideNavigationBar() -> some View {
        Group {
            if #available(iOS 16.0, *) {
                self
                    .appNavigationBarStyle(.hidden)
            } else {
                self
                    .navigationBarHidden(true)
                    .appNavigationBarStyle(.hidden)
            }
        }
    }
}
