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
    let lessonService: LessonServiceProtocol
    let profileService: ProfileServiceProtocol
    let socketService: SocketServiceProtocol
    let roleManager: RoleManager
    let transactionService: TransactionServiceProtocol
    let invitationService: InvitationServiceProtocol
    let cashPaymentService: CashPaymentServiceProtocol
    let giftCardService: GiftCardServiceProtocol
    let d17PaymentService: D17PaymentServiceProtocol
    let vdoCipherService: VdoCipherServiceProtocol
    let quizService: QuizServiceProtocol
    let badgeService: BadgeServiceProtocol
    let teacherCoursesService: TeacherCoursesServiceProtocol
    let teacherAnalyticsService: TeacherAnalyticsServiceProtocol
    let studentHomeService: StudentHomeServiceProtocol
    let homeDashboardService: HomeDashboardServiceProtocol
    let homeCacheStore: HomeCacheStore
    let networkMonitor: NetworkMonitor
    let puzzleService: PuzzleServiceProtocol
    let reelsService: ReelsServiceProtocol
    let adminDashboardService: AdminDashboardServiceProtocol
    
    // MARK: - Observable Services
    /// Access AuthService as ObservableObject for SwiftUI
    var observableAuthService: AuthService {
        return authService as! AuthService
    }
    
    // MARK: - Initialization
    private init() {
        // Initialize services in correct order
        self.networkService = NetworkService()
        self.authService = AuthService(networkService: networkService)
        self.courseService = CourseService(networkService: networkService, authService: authService)
        self.lessonService = LessonService(
            networkService: networkService,
            authService: authService,
            courseService: courseService
        )
        self.profileService = ProfileService(networkService: networkService, authService: authService)
        self.transactionService = TransactionService(networkService: networkService, authService: authService)
        self.invitationService = InvitationService(networkService: networkService, authService: authService)
        self.cashPaymentService = CashPaymentService(networkService: networkService, authService: authService)
        self.giftCardService = GiftCardService(networkService: networkService, authService: authService)
        self.d17PaymentService = D17PaymentService(networkService: networkService, authService: authService)
        self.vdoCipherService = VdoCipherService(networkService: networkService, authService: authService)
        self.quizService = QuizService(networkService: networkService, authService: authService)
        self.badgeService = BadgeService(networkService: networkService, authService: authService)
        self.teacherCoursesService = TeacherCoursesService(networkService: networkService, authService: authService)
        self.teacherAnalyticsService = TeacherAnalyticsService(authService: authService)
        self.studentHomeService = StudentHomeService(networkService: networkService, authService: authService)
        self.homeDashboardService = HomeDashboardService(networkService: networkService, authService: authService)
        self.homeCacheStore = HomeCacheStore()
        self.networkMonitor = NetworkMonitor()
        self.puzzleService = PuzzleService(networkService: networkService, authService: authService)
        self.reelsService = ReelsService(networkService: networkService, authService: authService)
        self.roleManager = RoleManager()
        self.adminDashboardService = AdminDashboardService(authService: authService)
        
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
    
    /// Create LessonsViewModel with injected dependencies
    func makeLessonsViewModel(courseId: String, accessType: LessonAccessType, isOwned: Bool = false) -> LessonsViewModel {
        return LessonsViewModel(
            courseId: courseId,
            accessType: accessType,
            isOwned: isOwned,
            lessonService: lessonService
        )
    }
    
    /// Create ProgressViewModel with injected dependencies
    func makeProgressViewModel() -> ProgressViewModel {
        return ProgressViewModel(courseService: courseService, authService: authService)
    }
    
    /// Create SettingsViewModel with injected dependencies
    func makeSettingsViewModel() -> SettingsViewModel {
        return SettingsViewModel(authService: authService)
    }
    
    /// Create EditProfileViewModel with injected dependencies
    func makeEditProfileViewModel(user: User) -> EditProfileViewModel {
        return EditProfileViewModel(
            user: user,
            profileService: profileService,
            authService: authService
        )
    }
    
    func makeWalletViewModel() -> WalletViewModel {
        return WalletViewModel(transactionService: transactionService, invitationService: invitationService)
    }
    
    /// Create TeacherMyClassesViewModel with injected dependencies
    func makeTeacherMyClassesViewModel() -> TeacherMyClassesViewModel {
        return TeacherMyClassesViewModel(teacherCoursesService: teacherCoursesService)
    }
    
    /// Create TeacherDashboardViewModel with injected dependencies
    func makeTeacherDashboardViewModel() -> TeacherDashboardViewModel {
        return TeacherDashboardViewModel(analyticsService: teacherAnalyticsService)
    }
    
    /// Create StudentHomeViewModel with injected dependencies
    func makeStudentHomeViewModel() -> StudentHomeViewModel {
        return StudentHomeViewModel(studentHomeService: studentHomeService, authService: authService)
    }

    /// Create StudentDashboardHomeViewModel (home-v1 endpoint)
    func makeStudentDashboardHomeViewModel() -> StudentDashboardHomeViewModel {
        return StudentDashboardHomeViewModel(
            service: homeDashboardService,
            cache: homeCacheStore,
            networkMonitor: networkMonitor
        )
    }

    /// Create TeacherDashboardHomeViewModel (home-v1 endpoint)
    func makeTeacherDashboardHomeViewModel() -> TeacherDashboardHomeViewModel {
        return TeacherDashboardHomeViewModel(
            service: homeDashboardService,
            cache: homeCacheStore,
            authService: authService,
            networkMonitor: networkMonitor
        )
    }

    func makeAdminHomeViewModel() -> AdminHomeViewModel {
        return AdminHomeViewModel(service: adminDashboardService)
    }
}
