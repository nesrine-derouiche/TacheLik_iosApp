import SwiftUI

// MARK: - CourseDetail Model
struct CourseDetail: Identifiable {
    let id: String
    let title: String
    let description: String
    let duration: Int // in minutes
    let levelIndicator: Int // e.g., 5
    let category: String
    let icon: String
    let gradientColors: [Color]
}

// MARK: - Our Courses View
struct OurCoursesView: View {
    let section: ClassSection
    let courses: [CourseDetail]
    let className: String
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(className)
                                    .font(.system(size: 28, weight: .bold))
                                Text("All \(className) Courses")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(courses.count)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(section.color)
                                .opacity(0.3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                            
                        // Section Info
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("\(courses.count) Courses")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(section.color.opacity(0.1))
                            .foregroundColor(section.color)
                            .cornerRadius(8)
                                
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                    .background(
                        LinearGradient(
                            colors: [section.color.opacity(0.08), section.color.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                        
                    // Courses Grid
                    VStack(spacing: 16) {
                        ForEach(Array(courses.enumerated()), id: \.element.id) { index, course in
                            let lesson = OurCoursesView.getLessonForCourse(course, in: section)
                            if let lesson = lesson {
                                NavigationLink(destination: LessonsView(lesson: lesson)) {
                                    courseCardContent(course: course, sectionColor: section.color)
                                }
                            } else {
                                courseCardContent(course: course, sectionColor: section.color)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private func courseCardContent(course: CourseDetail, sectionColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Course Header with Icon
            HStack(spacing: 16) {
                // Icon Background
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: course.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: course.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 90, height: 90)
                .shadow(color: course.gradientColors.first?.opacity(0.3) ?? Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                
                // Course Info
                VStack(alignment: .leading, spacing: 10) {
                    Text(course.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Meta Info (Duration, Level, Category)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("\(course.duration) min")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("Level \(course.levelIndicator)")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        // Category Tag
                        Text(course.category)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(sectionColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(sectionColor.opacity(0.1))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            
            // Divider
            Divider()
                .padding(.horizontal, 16)
            
            // Description
            VStack(alignment: .leading, spacing: 0) {
                Text(course.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Sample Course Data
extension OurCoursesView {
    static func getCoursesForSection(_ section: ClassSection) -> [CourseDetail] {
        switch section.name {
        case "1A":
            return algorithmeCoursesData
        case "2A":
            return qtCoursesData
        case "3A & 3B":
            return tlaCoursesData
        default:
            return []
        }
    }
    
    static func getLessonForCourse(_ course: CourseDetail, in section: ClassSection) -> Lesson? {
        switch course.id {
        // 1A - Algorithme Lessons
        case "algo-1":
            return Lesson.algorithmeConditionsLesson
        case "algo-2":
            return Lesson.algorithmeStructuresLesson
        case "algo-3":
            return Lesson.algorithmeTableauxLesson
        case "algo-4":
            return Lesson.algorithmTriLesson
        case "algo-5":
            return Lesson.algorithmeStringLesson
        case "algo-6":
            return Lesson.algorithmeRevisionLesson
            
        // 2A - Qt Lessons
        case "qt-1":
            return Lesson.qtIntroductionLesson
        case "qt-2":
            return Lesson.qtSignalsLesson
        case "qt-3":
            return Lesson.qtWidgetsLesson
        case "qt-4":
            return Lesson.qtDatabaseLesson
            
        // 3A & 3B - TLA Lessons
        case "tla-1":
            return Lesson.tlaIntroductionLesson
        case "tla-2":
            return Lesson.tlaaAutomatesLesson
        case "tla-3":
            return Lesson.tlaVerificationLesson
        case "tla-4":
            return Lesson.tlaApplicationsLesson
            
        default:
            return nil
        }
    }
}

// MARK: - Course Data for Each Section

let algorithmeCoursesData = [
    CourseDetail(
        id: "algo-1",
        title: "Algorithmes & Conditions",
        description: "Découvrez vos premiers pas en algorithmique à travers l'introduction, les conditions (if, else, switch) et des exercices pratiques. Idéal pour débuter et renforcer sa logique.",
        duration: 39,
        levelIndicator: 5,
        category: "Introduction",
        icon: "flowchart.fill",
        gradientColors: [Color(red: 0.3, green: 0.8, blue: 1.0), Color(red: 0.0, green: 0.6, blue: 0.9)]
    ),
    CourseDetail(
        id: "algo-2",
        title: "Structures Répétitives en Algorithmes",
        description: "Découvrez comment utiliser les boucles en algorithmique pour automatiser les calculs et résoudre efficacement des problèmes.",
        duration: 34,
        levelIndicator: 4,
        category: "Introduction",
        icon: "repeat.circle.fill",
        gradientColors: [Color(red: 0.0, green: 0.7, blue: 0.9), Color(red: 0.1, green: 0.5, blue: 0.8)]
    ),
    CourseDetail(
        id: "algo-3",
        title: "Tableaux et Matrices en Algorithmique",
        description: "Apprenez la manipulation des tableaux et matrices en algorithmique pas à pas.",
        duration: 64,
        levelIndicator: 8,
        category: "Introduction",
        icon: "square.grid.2x2.fill",
        gradientColors: [Color(red: 0.2, green: 0.75, blue: 0.95), Color(red: 0.0, green: 0.55, blue: 0.85)]
    ),
    CourseDetail(
        id: "algo-4",
        title: "Tri et Recherche en Algorithmes",
        description: "Découvrez les méthodes de tri et recherche en algorithmique, leurs principes et implémentations.",
        duration: 26,
        levelIndicator: 5,
        category: "Introduction",
        icon: "magnifyingglass.circle.fill",
        gradientColors: [Color(red: 0.1, green: 0.8, blue: 0.92), Color(red: 0.05, green: 0.65, blue: 0.88)]
    ),
    CourseDetail(
        id: "algo-5",
        title: "Chaînes de Caractères en Algorithmes",
        description: "Manipulez les chaînes de caractères - lecture, parcours et traitement textuel en algorithmique.",
        duration: 21,
        levelIndicator: 4,
        category: "Introduction",
        icon: "character.textbox",
        gradientColors: [Color(red: 0.25, green: 0.78, blue: 0.98), Color(red: 0.05, green: 0.60, blue: 0.90)]
    ),
    CourseDetail(
        id: "algo-6",
        title: "Révision du DS - Algorithme",
        description: "Révisez tous les algorithmes sur tache-lik.tn - préparez-vous efficacement !",
        duration: 61,
        levelIndicator: 3,
        category: "Foundation",
        icon: "book.circle.fill",
        gradientColors: [Color(red: 0.15, green: 0.72, blue: 0.95), Color(red: 0.0, green: 0.50, blue: 0.80)]
    )
]

let qtCoursesData = [
    CourseDetail(
        id: "qt-1",
        title: "Introduction to Qt Framework",
        description: "Learn the basics of Qt framework for building cross-platform graphical applications with C++.",
        duration: 45,
        levelIndicator: 5,
        category: "Foundation",
        icon: "square.and.pencil",
        gradientColors: [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.7, green: 0.2, blue: 0.9)]
    ),
    CourseDetail(
        id: "qt-2",
        title: "Qt Signals and Slots",
        description: "Master the signal and slot mechanism - the heart of Qt programming.",
        duration: 38,
        levelIndicator: 6,
        category: "Intermediate",
        icon: "bolt.circle.fill",
        gradientColors: [Color(red: 0.75, green: 0.3, blue: 0.95), Color(red: 0.65, green: 0.1, blue: 0.85)]
    ),
    CourseDetail(
        id: "qt-3",
        title: "Qt Widget Design",
        description: "Design beautiful and responsive user interfaces using Qt Widgets.",
        duration: 52,
        levelIndicator: 7,
        category: "Intermediate",
        icon: "rect.3.offscreen.bubble",
        gradientColors: [Color(red: 0.85, green: 0.5, blue: 1.0), Color(red: 0.75, green: 0.3, blue: 0.92)]
    ),
    CourseDetail(
        id: "qt-4",
        title: "Qt Database Programming",
        description: "Connect your Qt applications to databases and manage data efficiently.",
        duration: 48,
        levelIndicator: 8,
        category: "Advanced",
        icon: "cylinder.split.1x2.fill",
        gradientColors: [Color(red: 0.78, green: 0.35, blue: 0.98), Color(red: 0.68, green: 0.15, blue: 0.88)]
    )
]

let tlaCoursesData = [
    CourseDetail(
        id: "tla-1",
        title: "Introduction à TLA+",
        description: "Découvrez les fondamentaux de la spécification formelle avec TLA+.",
        duration: 42,
        levelIndicator: 6,
        category: "Foundation",
        icon: "function",
        gradientColors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.5, blue: 0.0)]
    ),
    CourseDetail(
        id: "tla-2",
        title: "Automates et Transitions",
        description: "Comprenez la théorie des automates et les transitions d'état en TLA+.",
        duration: 55,
        levelIndicator: 7,
        category: "Intermediate",
        icon: "arrow.triangle.2.circlepath",
        gradientColors: [Color(red: 1.0, green: 0.65, blue: 0.3), Color(red: 0.98, green: 0.55, blue: 0.1)]
    ),
    CourseDetail(
        id: "tla-3",
        title: "Vérification Formelle",
        description: "Apprenez les techniques de vérification formelle pour assurer la correction des algorithmes.",
        duration: 67,
        levelIndicator: 8,
        category: "Advanced",
        icon: "checkmark.circle.fill",
        gradientColors: [Color(red: 1.0, green: 0.58, blue: 0.1), Color(red: 0.92, green: 0.45, blue: 0.0)]
    ),
    CourseDetail(
        id: "tla-4",
        title: "Applications Pratiques",
        description: "Appliquez TLA+ à des problèmes réels et complexes de concurrence.",
        duration: 59,
        levelIndicator: 9,
        category: "Advanced",
        icon: "star.circle.fill",
        gradientColors: [Color(red: 1.0, green: 0.62, blue: 0.2), Color(red: 0.96, green: 0.50, blue: 0.05)]
    )
]
