//
//  DIContainer.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation

// MARK: - Dependency Injection Container
/// Centralized container for managing all app dependencies
final class DIContainer {
    
    // MARK: - Singleton
    static let shared = DIContainer()
    
    // MARK: - Services
    let networkService: NetworkServiceProtocol
    let authService: AuthServiceProtocol
    let courseService: CourseServiceProtocol
    let socketService: SocketServiceProtocol
    
    // MARK: - Initialization
    private init() {
        // Initialize services in correct order
        self.networkService = NetworkService()
        self.authService = AuthService(networkService: networkService)
        self.courseService = CourseService(networkService: networkService, authService: authService)
        
        // Initialize socket service with configuration from AppConfig
        let socketConfig = SocketConfiguration(
            url: AppConfig.socketURL,
            enableLogging: AppConfig.enableLogging,
            reconnectAttempts: 5,
            reconnectWait: 2,
            heartbeatInterval: 30,
            connectionTimeout: 10
        )
        self.socketService = SocketService(configuration: socketConfig)
        
        // For development with mock data, use:
        // self.authService = MockAuthService()
        // self.courseService = MockCourseService()
    }
    
    // MARK: - Factory Methods
    
    /// Create LoginViewModel with injected dependencies
    func makeLoginViewModel() -> LoginViewModel {
        return LoginViewModel(authService: authService, socketService: socketService)
    }
    
    /// Create HomeViewModel with injected dependencies
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel(courseService: courseService, authService: authService)
    }
    
    /// Create ClassesViewModel with injected dependencies
    func makeClassesViewModel() -> ClassesViewModel {
        return ClassesViewModel(courseService: courseService)
    }
    
    /// Create ProgressViewModel with injected dependencies
    func makeProgressViewModel() -> ProgressViewModel {
        return ProgressViewModel(courseService: courseService, authService: authService)
    }
    
    /// Create SettingsViewModel with injected dependencies
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(authService: authService)
    }
}
