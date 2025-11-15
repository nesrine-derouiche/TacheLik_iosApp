import Foundation
import SwiftUI

// MARK: - Teacher Model with Social Links
struct Teacher: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let bio: String?
    let profileImage: String?
    let socialLinks: [SocialLink]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, bio
        case profileImage = "profile_image"
        case socialLinks = "social_links"
    }
}

// MARK: - Social Link Model
struct SocialLink: Identifiable, Codable {
    let id: String
    let platform: SocialPlatform
    let url: String
    
    enum SocialPlatform: String, Codable {
        case email = "email"
        case linkedin = "linkedin"
        case github = "github"
        case facebook = "facebook"
        case twitter = "twitter"
        case instagram = "instagram"
        case website = "website"
        
        var icon: String {
            switch self {
            case .email:
                return "envelope.fill"
            case .linkedin:
                return "link.circle.fill"
            case .github:
                return "square.and.pencil"
            case .facebook:
                return "f.circle.fill"
            case .twitter:
                return "x.circle.fill"
            case .instagram:
                return "photo.circle.fill"
            case .website:
                return "globe"
            }
        }
        
        var color: Color {
            switch self {
            case .email:
                return Color(red: 1.0, green: 0.2, blue: 0.2)
            case .linkedin:
                return Color(red: 0.0, green: 0.467, blue: 0.835)
            case .github:
                return Color(red: 0.1, green: 0.1, blue: 0.1)
            case .facebook:
                return Color(red: 0.29, green: 0.44, blue: 0.77)
            case .twitter:
                return Color(red: 0.2, green: 0.2, blue: 0.2)
            case .instagram:
                return Color(red: 1.0, green: 0.5, blue: 0.2)
            case .website:
                return Color.brandPrimary
            }
        }
    }
}

// MARK: - Video Content Model
struct VideoContent: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let duration: Int // in seconds
    let videoUrl: String
    let thumbnailUrl: String?
    let description: String?
    let orderIndex: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, duration, description
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
        case orderIndex = "order_index"
    }
    
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Lesson Model
struct Lesson: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let teacher: Teacher
    let videos: [VideoContent]
    let courseId: String?
    let createdDate: String?
    let updatedDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, teacher, videos
        case courseId = "course_id"
        case createdDate = "created_date"
        case updatedDate = "updated_date"
    }
}

// MARK: - Video Player State
struct VideoPlayerState: Identifiable {
    let id = UUID()
    var currentVideo: VideoContent
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var totalDuration: Double = 0
}

// MARK: - Preview / Mock Helpers
extension Lesson {
    static let sampleLesson = Lesson(
        id: "lesson-sample-1",
        title: "Introduction et Création de Projet | FlutterFlow",
        description: "Découvrez les bases de FlutterFlow dans ce cours complet.",
        teacher: Teacher(
            id: "teacher-sample-1",
            name: "Dr. Mohamed Trabelsi",
            email: "m.trabelsi@esprit.tn",
            bio: "Expert en développement mobile et théorie des langages",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "social-1", platform: .email, url: "mailto:m.trabelsi@esprit.tn")
            ]
        ),
        videos: [
            VideoContent(
                id: "video-sample-1",
                title: "Partie 1 : Introduction",
                duration: 252,
                videoUrl: "https://youtube.com/watch?v=example1",
                thumbnailUrl: nil,
                description: "Tour d'horizon de FlutterFlow",
                orderIndex: 0
            ),
            VideoContent(
                id: "video-sample-2",
                title: "Partie 2 : Widgets de Base",
                duration: 525,
                videoUrl: "https://youtube.com/watch?v=example2",
                thumbnailUrl: nil,
                description: "Découverte des widgets essentiels",
                orderIndex: 1
            )
        ],
        courseId: "course-sample-1",
        createdDate: "2024-01-15",
        updatedDate: "2024-11-09"
    )
}

// MARK: - Sample Lessons Data for All Courses

extension Lesson {
    // MARK: - Algorithme Lessons (Section 1A)
    
    static let algorithmeConditionsLesson = Lesson(
        id: "lesson-algo-1",
        title: "Algorithmes & Conditions",
        description: "Découvrez vos premiers pas en algorithmique à travers l'introduction, les conditions (if, else, switch) et des exercices pratiques. Idéal pour débuter et renforcer sa logique.",
        teacher: Teacher(
            id: "teacher-mb1",
            name: "MB1",
            email: "mb1@esprit.tn",
            bio: "Spécialiste en algorithmique et structures de données",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "s1", platform: .email, url: "mailto:mb1@esprit.tn")
            ]
        ),
        videos: [
            VideoContent(id: "vid-algo1-1", title: "Introduction aux Conditions", duration: 780, videoUrl: "https://youtube.com/watch?v=algo1", thumbnailUrl: nil, description: "Apprenez les fondamentaux des conditions", orderIndex: 0),
            VideoContent(id: "vid-algo1-2", title: "If, Else, Switch - Exercices", duration: 1200, videoUrl: "https://youtube.com/watch?v=algo2", thumbnailUrl: nil, description: "Pratique avec des exercices concrets", orderIndex: 1),
            VideoContent(id: "vid-algo1-3", title: "Conditions Imbriquées", duration: 900, videoUrl: "https://youtube.com/watch?v=algo3", thumbnailUrl: nil, description: "Maîtrisez les conditions complexes", orderIndex: 2)
        ],
        courseId: "course-1a",
        createdDate: "2024-01-15",
        updatedDate: "2024-11-09"
    )
    
    static let algorithmeStructuresLesson = Lesson(
        id: "lesson-algo-2",
        title: "Structures Répétitives en Algorithmes",
        description: "Découvrez comment utiliser les boucles en algorithmique pour automatiser les calculs et résoudre efficacement des problèmes.",
        teacher: Teacher(
            id: "teacher-mb1",
            name: "MB1",
            email: "mb1@esprit.tn",
            bio: "Spécialiste en algorithmique et structures de données",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb1@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-algo2-1", title: "Introduction aux Boucles", duration: 900, videoUrl: "https://youtube.com/watch?v=algo4", thumbnailUrl: nil, description: "Boucles for, while et do-while", orderIndex: 0),
            VideoContent(id: "vid-algo2-2", title: "Boucles Imbriquées", duration: 1050, videoUrl: "https://youtube.com/watch?v=algo5", thumbnailUrl: nil, description: "Travaillez avec plusieurs niveaux de boucles", orderIndex: 1)
        ],
        courseId: "course-1a",
        createdDate: "2024-01-20",
        updatedDate: "2024-11-09"
    )
    
    static let algorithmeTableauxLesson = Lesson(
        id: "lesson-algo-3",
        title: "Tableaux et Matrices en Algorithmique",
        description: "Apprenez la manipulation des tableaux et matrices en algorithmique pas à pas.",
        teacher: Teacher(
            id: "teacher-mb1",
            name: "MB1",
            email: "mb1@esprit.tn",
            bio: "Spécialiste en algorithmique et structures de données",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb1@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-algo3-1", title: "Les Tableaux - Bases", duration: 1200, videoUrl: "https://youtube.com/watch?v=algo6", thumbnailUrl: nil, description: "Déclaration et utilisation des tableaux", orderIndex: 0),
            VideoContent(id: "vid-algo3-2", title: "Matrices et Tableaux 2D", duration: 1500, videoUrl: "https://youtube.com/watch?v=algo7", thumbnailUrl: nil, description: "Travaillez avec des matrices", orderIndex: 1),
            VideoContent(id: "vid-algo3-3", title: "Exercices Pratiques", duration: 900, videoUrl: "https://youtube.com/watch?v=algo8", thumbnailUrl: nil, description: "Appliquez vos connaissances", orderIndex: 2)
        ],
        courseId: "course-1a",
        createdDate: "2024-01-25",
        updatedDate: "2024-11-09"
    )
    
    static let algorithmTriLesson = Lesson(
        id: "lesson-algo-4",
        title: "Tri et Recherche en Algorithmes",
        description: "Découvrez les méthodes de tri et recherche en algorithmique, leurs principes et implémentations.",
        teacher: Teacher(
            id: "teacher-mb1",
            name: "MB1",
            email: "mb1@esprit.tn",
            bio: "Spécialiste en algorithmique et structures de données",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb1@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-algo4-1", title: "Algorithmes de Tri", duration: 1080, videoUrl: "https://youtube.com/watch?v=algo9", thumbnailUrl: nil, description: "Tri par insertion, par sélection, par fusion", orderIndex: 0),
            VideoContent(id: "vid-algo4-2", title: "Algorithmes de Recherche", duration: 900, videoUrl: "https://youtube.com/watch?v=algo10", thumbnailUrl: nil, description: "Recherche linéaire et binaire", orderIndex: 1)
        ],
        courseId: "course-1a",
        createdDate: "2024-02-01",
        updatedDate: "2024-11-09"
    )
    
    static let algorithmeStringLesson = Lesson(
        id: "lesson-algo-5",
        title: "Chaînes de Caractères en Algorithmes",
        description: "Manipulez les chaînes de caractères - lecture, parcours et traitement textuel en algorithmique.",
        teacher: Teacher(
            id: "teacher-mb1",
            name: "MB1",
            email: "mb1@esprit.tn",
            bio: "Spécialiste en algorithmique et structures de données",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb1@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-algo5-1", title: "Manipulation de Chaînes", duration: 840, videoUrl: "https://youtube.com/watch?v=algo11", thumbnailUrl: nil, description: "Opérations sur les chaînes", orderIndex: 0),
            VideoContent(id: "vid-algo5-2", title: "Recherche et Remplacement", duration: 720, videoUrl: "https://youtube.com/watch?v=algo12", thumbnailUrl: nil, description: "Chercher et remplacer du texte", orderIndex: 1)
        ],
        courseId: "course-1a",
        createdDate: "2024-02-10",
        updatedDate: "2024-11-09"
    )
    
    static let algorithmeRevisionLesson = Lesson(
        id: "lesson-algo-6",
        title: "Révision du DS - Algorithme",
        description: "Révisez tous les algorithmes sur tache-lik.tn - préparez-vous efficacement !",
        teacher: Teacher(
            id: "teacher-mb1",
            name: "MB1",
            email: "mb1@esprit.tn",
            bio: "Spécialiste en algorithmique et structures de données",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb1@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-algo6-1", title: "Révision Globale", duration: 1800, videoUrl: "https://youtube.com/watch?v=algo13", thumbnailUrl: nil, description: "Résumé de tous les concepts clés", orderIndex: 0),
            VideoContent(id: "vid-algo6-2", title: "Questions Fréquentes", duration: 900, videoUrl: "https://youtube.com/watch?v=algo14", thumbnailUrl: nil, description: "Réponses aux questions communes", orderIndex: 1),
            VideoContent(id: "vid-algo6-3", title: "Exercices d'Examen", duration: 1200, videoUrl: "https://youtube.com/watch?v=algo15", thumbnailUrl: nil, description: "Préparation à l'examen", orderIndex: 2)
        ],
        courseId: "course-1a",
        createdDate: "2024-02-20",
        updatedDate: "2024-11-09"
    )
    
    // MARK: - Qt Lessons (Section 2A)
    
    static let qtIntroductionLesson = Lesson(
        id: "lesson-qt-1",
        title: "Introduction to Qt Framework",
        description: "Learn the basics of Qt framework for building cross-platform graphical applications with C++.",
        teacher: Teacher(
            id: "teacher-mb3",
            name: "MB3",
            email: "mb3@esprit.tn",
            bio: "Qt Expert and Cross-Platform Development Specialist",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "s1", platform: .email, url: "mailto:mb3@esprit.tn"),
                SocialLink(id: "s2", platform: .linkedin, url: "https://linkedin.com")
            ]
        ),
        videos: [
            VideoContent(id: "vid-qt1-1", title: "Qt Basics and Setup", duration: 1200, videoUrl: "https://youtube.com/watch?v=qt1", thumbnailUrl: nil, description: "Install Qt and create your first project", orderIndex: 0),
            VideoContent(id: "vid-qt1-2", title: "Qt Creator IDE Tour", duration: 900, videoUrl: "https://youtube.com/watch?v=qt2", thumbnailUrl: nil, description: "Navigate the Qt Creator interface", orderIndex: 1),
            VideoContent(id: "vid-qt1-3", title: "Your First Qt Application", duration: 1500, videoUrl: "https://youtube.com/watch?v=qt3", thumbnailUrl: nil, description: "Build a simple Hello World app", orderIndex: 2)
        ],
        courseId: "course-2a",
        createdDate: "2024-01-15",
        updatedDate: "2024-11-09"
    )
    
    static let qtSignalsLesson = Lesson(
        id: "lesson-qt-2",
        title: "Qt Signals and Slots",
        description: "Master the signal and slot mechanism - the heart of Qt programming.",
        teacher: Teacher(
            id: "teacher-mb3",
            name: "MB3",
            email: "mb3@esprit.tn",
            bio: "Qt Expert and Cross-Platform Development Specialist",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb3@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-qt2-1", title: "Understanding Signals and Slots", duration: 1200, videoUrl: "https://youtube.com/watch?v=qt4", thumbnailUrl: nil, description: "Core concepts explained", orderIndex: 0),
            VideoContent(id: "vid-qt2-2", title: "Connecting Signals to Slots", duration: 1080, videoUrl: "https://youtube.com/watch?v=qt5", thumbnailUrl: nil, description: "Practical connection examples", orderIndex: 1),
            VideoContent(id: "vid-qt2-3", title: "Custom Signals and Slots", duration: 1320, videoUrl: "https://youtube.com/watch?v=qt6", thumbnailUrl: nil, description: "Create your own signals", orderIndex: 2)
        ],
        courseId: "course-2a",
        createdDate: "2024-02-01",
        updatedDate: "2024-11-09"
    )
    
    static let qtWidgetsLesson = Lesson(
        id: "lesson-qt-3",
        title: "Qt Widget Design",
        description: "Design beautiful and responsive user interfaces using Qt Widgets.",
        teacher: Teacher(
            id: "teacher-mb3",
            name: "MB3",
            email: "mb3@esprit.tn",
            bio: "Qt Expert and Cross-Platform Development Specialist",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb3@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-qt3-1", title: "Qt Widgets Overview", duration: 1080, videoUrl: "https://youtube.com/watch?v=qt7", thumbnailUrl: nil, description: "Learn all available widgets", orderIndex: 0),
            VideoContent(id: "vid-qt3-2", title: "Layout Management", duration: 1200, videoUrl: "https://youtube.com/watch?v=qt8", thumbnailUrl: nil, description: "Organize your UI effectively", orderIndex: 1),
            VideoContent(id: "vid-qt3-3", title: "Styling and Theming", duration: 1440, videoUrl: "https://youtube.com/watch?v=qt9", thumbnailUrl: nil, description: "Make your UI beautiful", orderIndex: 2)
        ],
        courseId: "course-2a",
        createdDate: "2024-02-15",
        updatedDate: "2024-11-09"
    )
    
    static let qtDatabaseLesson = Lesson(
        id: "lesson-qt-4",
        title: "Qt Database Programming",
        description: "Connect your Qt applications to databases and manage data efficiently.",
        teacher: Teacher(
            id: "teacher-mb3",
            name: "MB3",
            email: "mb3@esprit.tn",
            bio: "Qt Expert and Cross-Platform Development Specialist",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:mb3@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-qt4-1", title: "Database Connections", duration: 1320, videoUrl: "https://youtube.com/watch?v=qt10", thumbnailUrl: nil, description: "Connect to SQL databases", orderIndex: 0),
            VideoContent(id: "vid-qt4-2", title: "SQL Queries in Qt", duration: 1200, videoUrl: "https://youtube.com/watch?v=qt11", thumbnailUrl: nil, description: "Execute and manage queries", orderIndex: 1),
            VideoContent(id: "vid-qt4-3", title: "Database Models and Views", duration: 1440, videoUrl: "https://youtube.com/watch?v=qt12", thumbnailUrl: nil, description: "Display database data in UI", orderIndex: 2)
        ],
        courseId: "course-2a",
        createdDate: "2024-03-01",
        updatedDate: "2024-11-09"
    )
    
    // MARK: - TLA Lessons (Section 3A & 3B)
    
    static let tlaIntroductionLesson = Lesson(
        id: "lesson-tla-1",
        title: "Introduction à TLA+",
        description: "Découvrez les fondamentaux de la spécification formelle avec TLA+.",
        teacher: Teacher(
            id: "teacher-tla",
            name: "Dr. Mohamed Trabelsi",
            email: "m.trabelsi@esprit.tn",
            bio: "Expert en vérification formelle et théorie des langages",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "s1", platform: .email, url: "mailto:m.trabelsi@esprit.tn"),
                SocialLink(id: "s2", platform: .linkedin, url: "https://linkedin.com"),
                SocialLink(id: "s3", platform: .github, url: "https://github.com")
            ]
        ),
        videos: [
            VideoContent(id: "vid-tla1-1", title: "Qu'est-ce que TLA+?", duration: 1080, videoUrl: "https://youtube.com/watch?v=tla1", thumbnailUrl: nil, description: "Introduction à la spécification formelle", orderIndex: 0),
            VideoContent(id: "vid-tla1-2", title: "Syntaxe et Concepts de Base", duration: 1320, videoUrl: "https://youtube.com/watch?v=tla2", thumbnailUrl: nil, description: "Apprenez la syntaxe TLA+", orderIndex: 1),
            VideoContent(id: "vid-tla1-3", title: "Votre Premier Modèle", duration: 1200, videoUrl: "https://youtube.com/watch?v=tla3", thumbnailUrl: nil, description: "Créez un simple modèle TLA+", orderIndex: 2)
        ],
        courseId: "course-3ab",
        createdDate: "2024-01-20",
        updatedDate: "2024-11-09"
    )
    
    static let tlaaAutomatesLesson = Lesson(
        id: "lesson-tla-2",
        title: "Automates et Transitions",
        description: "Comprenez la théorie des automates et les transitions d'état en TLA+.",
        teacher: Teacher(
            id: "teacher-tla",
            name: "Dr. Mohamed Trabelsi",
            email: "m.trabelsi@esprit.tn",
            bio: "Expert en vérification formelle et théorie des langages",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "s1", platform: .email, url: "mailto:m.trabelsi@esprit.tn"),
                SocialLink(id: "s2", platform: .linkedin, url: "https://linkedin.com")
            ]
        ),
        videos: [
            VideoContent(id: "vid-tla2-1", title: "Théorie des Automates", duration: 1440, videoUrl: "https://youtube.com/watch?v=tla4", thumbnailUrl: nil, description: "Concepts théoriques fondamentaux", orderIndex: 0),
            VideoContent(id: "vid-tla2-2", title: "Transitions d'État", duration: 1200, videoUrl: "https://youtube.com/watch?v=tla5", thumbnailUrl: nil, description: "Modéliser les transitions", orderIndex: 1),
            VideoContent(id: "vid-tla2-3", title: "Exercices Pratiques", duration: 1320, videoUrl: "https://youtube.com/watch?v=tla6", thumbnailUrl: nil, description: "Appliquez vos connaissances", orderIndex: 2)
        ],
        courseId: "course-3ab",
        createdDate: "2024-02-05",
        updatedDate: "2024-11-09"
    )
    
    static let tlaVerificationLesson = Lesson(
        id: "lesson-tla-3",
        title: "Vérification Formelle",
        description: "Apprenez les techniques de vérification formelle pour assurer la correction des algorithmes.",
        teacher: Teacher(
            id: "teacher-tla",
            name: "Dr. Mohamed Trabelsi",
            email: "m.trabelsi@esprit.tn",
            bio: "Expert en vérification formelle et théorie des langages",
            profileImage: nil,
            socialLinks: [SocialLink(id: "s1", platform: .email, url: "mailto:m.trabelsi@esprit.tn")]
        ),
        videos: [
            VideoContent(id: "vid-tla3-1", title: "Principes de Vérification", duration: 1320, videoUrl: "https://youtube.com/watch?v=tla7", thumbnailUrl: nil, description: "Fondamentaux de la vérification formelle", orderIndex: 0),
            VideoContent(id: "vid-tla3-2", title: "Model Checking", duration: 1500, videoUrl: "https://youtube.com/watch?v=tla8", thumbnailUrl: nil, description: "Vérifier vos modèles", orderIndex: 1),
            VideoContent(id: "vid-tla3-3", title: "Débogage de Modèles", duration: 1200, videoUrl: "https://youtube.com/watch?v=tla9", thumbnailUrl: nil, description: "Trouvez et corrigez les erreurs", orderIndex: 2)
        ],
        courseId: "course-3ab",
        createdDate: "2024-02-20",
        updatedDate: "2024-11-09"
    )
    
    static let tlaApplicationsLesson = Lesson(
        id: "lesson-tla-4",
        title: "Applications Pratiques",
        description: "Appliquez TLA+ à des problèmes réels et complexes de concurrence.",
        teacher: Teacher(
            id: "teacher-tla",
            name: "Dr. Mohamed Trabelsi",
            email: "m.trabelsi@esprit.tn",
            bio: "Expert en vérification formelle et théorie des langages",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "s1", platform: .email, url: "mailto:m.trabelsi@esprit.tn"),
                SocialLink(id: "s2", platform: .github, url: "https://github.com")
            ]
        ),
        videos: [
            VideoContent(id: "vid-tla4-1", title: "Problèmes de Concurrence", duration: 1440, videoUrl: "https://youtube.com/watch?v=tla10", thumbnailUrl: nil, description: "Cas d'usage en concurrence", orderIndex: 0),
            VideoContent(id: "vid-tla4-2", title: "Étude de Cas Réels", duration: 1560, videoUrl: "https://youtube.com/watch?v=tla11", thumbnailUrl: nil, description: "Apprenez par l'exemple", orderIndex: 1),
            VideoContent(id: "vid-tla4-3", title: "Optimisation de Modèles", duration: 1320, videoUrl: "https://youtube.com/watch?v=tla12", thumbnailUrl: nil, description: "Améliorez vos spécifications", orderIndex: 2)
        ],
        courseId: "course-3ab",
        createdDate: "2024-03-10",
        updatedDate: "2024-11-09"
    )
}
