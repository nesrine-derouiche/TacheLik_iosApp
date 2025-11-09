import SwiftUI

// MARK: - Lessons View
struct LessonsView: View {
    let lesson: Lesson
    @State private var selectedVideo: VideoContent?
    @State private var isVideoListExpanded = true
    @State private var selectedVideoIndex: Int = 0
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.paddingMD) {
                // Header
                headerSection
                
                // Video Player Section
                videoPlayerSection
                
                // Video List (Expandable)
                videoListSection
                
                // Teacher Section
                TeacherProfileCard(teacher: lesson.teacher)
                    .padding(.horizontal, DS.paddingMD)
                
                // Lesson Description (if available)
                if let description = lesson.description, !description.isEmpty {
                    lessonDescriptionSection(description)
                }
                
                Spacer(minLength: DS.paddingXL)
            }
            .padding(.vertical, DS.paddingMD)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DS.paddingSM) {
            Text(lesson.title)
                .font(.system(size: 26, weight: .bold))
                .lineLimit(2)
                .foregroundColor(.primary)
                .padding(.horizontal, DS.paddingMD)
        }
        .padding(.top, DS.paddingSM)
        .padding(.bottom, DS.paddingMD)
    }
    
    // MARK: - Video Player Section
    private var videoPlayerSection: some View {
        VStack(spacing: 0) {
            // Video Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                    .fill(Color.black)
                
                VStack(spacing: DS.paddingMD) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 4) {
                        Text((selectedVideo ?? lesson.videos.first)?.title ?? "Video")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Ready to play")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(height: 200)
            .padding(DS.paddingMD)
            
            // Video Info Bar
            HStack(spacing: DS.paddingSM) {
                VStack(alignment: .leading, spacing: 2) {
                    Text((selectedVideo ?? lesson.videos.first)?.title ?? "Video")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text((selectedVideo ?? lesson.videos.first)?.formattedDuration ?? "00:00")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: DS.paddingSM) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.brandPrimary))
                    
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                }
            }
            .padding(DS.paddingMD)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(DS.cornerRadiusMD)
        .padding(.horizontal, DS.paddingMD)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Video List Section
    private var videoListSection: some View {
        VStack(spacing: 0) {
            // Header with Toggle
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isVideoListExpanded.toggle()
                }
            }) {
                HStack(spacing: DS.paddingMD) {
                    HStack(spacing: DS.paddingSM) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.brandPrimary))
                        
                        Text("\(lesson.videos.count) Videos")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isVideoListExpanded ? 0 : -90))
                }
                .padding(DS.paddingMD)
                .background(Color(.systemBackground))
                .contentShape(Rectangle())
            }
            
            // Video List
            if isVideoListExpanded {
                Divider()
                    .padding(.horizontal, DS.paddingMD)
                
                VStack(spacing: 0) {
                    ForEach(Array(lesson.videos.enumerated()), id: \.element.id) { index, video in
                        VideoListItemView(
                            video: video,
                            isSelected: selectedVideo?.id == video.id || (selectedVideo == nil && index == 0),
                            index: index + 1
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedVideo = video
                                selectedVideoIndex = index
                            }
                        }
                        
                        if index < lesson.videos.count - 1 {
                            Divider()
                                .padding(.horizontal, DS.paddingMD)
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(DS.cornerRadiusMD)
        .padding(.horizontal, DS.paddingMD)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Lesson Description Section
    private func lessonDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: DS.paddingSM) {
            Text("About this lesson")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(description)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .padding(DS.paddingMD)
        .background(Color(.systemBackground))
        .cornerRadius(DS.cornerRadiusMD)
        .padding(.horizontal, DS.paddingMD)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Video List Item
struct VideoListItemView: View {
    let video: VideoContent
    let isSelected: Bool
    let index: Int
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DS.paddingMD) {
            // Video Number/Icon
            ZStack {
                Circle()
                    .fill(isSelected ? 
                        LinearGradient(
                            colors: [Color.brandPrimary, Color.brandPrimaryHover],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) : LinearGradient(
                            colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                if isSelected {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Text("\(index)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 40, height: 40)
            .shadow(color: isSelected ? Color.brandPrimary.opacity(0.3) : Color.clear, radius: 6, x: 0, y: 2)
            
            // Video Info
            VStack(alignment: .leading, spacing: 2) {
                Text(video.title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(video.formattedDuration)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.brandPrimary)
                    .transition(.scale.combined(with: .opacity))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .opacity(0.5)
            }
        }
        .padding(DS.paddingMD)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, perform: {}) { isPressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = isPressing
            }
        }
    }
}

// MARK: - Sample Data
extension Lesson {
    static let sampleLesson = Lesson(
        id: "lesson-1",
        title: "Introduction et Création de Projet | FlutterFlow : Les Fondations",
        description: "Découvrez les bases de FlutterFlow dans ce cours complet. Apprenez à créer votre premier projet, configurer votre environnement de développement, et comprendre les principes fondamentaux de FlutterFlow. Ce cours couvre tout ce que vous devez savoir pour commencer avec FlutterFlow et construire des applications mobiles magnifiques sans écrire de code.",
        teacher: Teacher(
            id: "teacher-1",
            name: "Dr. Mohamed Trabelsi",
            email: "m.trabelsi@esprit.tn",
            bio: "Expert en développement mobile et théorie des langages",
            profileImage: nil,
            socialLinks: [
                SocialLink(id: "s1", platform: .email, url: "mailto:m.trabelsi@esprit.tn"),
                SocialLink(id: "s2", platform: .linkedin, url: "https://linkedin.com"),
                SocialLink(id: "s3", platform: .github, url: "https://github.com"),
                SocialLink(id: "s4", platform: .website, url: "https://example.com")
            ]
        ),
        videos: [
            VideoContent(
                id: "vid-1",
                title: "Partie 1 : Introduction et Création de Projet",
                duration: 252,
                videoUrl: "https://youtube.com/watch?v=example1",
                thumbnailUrl: nil,
                description: "Introduction complète aux fondamentaux de FlutterFlow",
                orderIndex: 0
            ),
            VideoContent(
                id: "vid-2",
                title: "Partie 2 : Widgets de Base – Exercice d'Application",
                duration: 525,
                videoUrl: "https://youtube.com/watch?v=example2",
                thumbnailUrl: nil,
                description: "Apprenez les widgets de base et pratiquez avec des exercices",
                orderIndex: 1
            ),
            VideoContent(
                id: "vid-3",
                title: "Partie 3 : Actions",
                duration: 216,
                videoUrl: "https://youtube.com/watch?v=example3",
                thumbnailUrl: nil,
                description: "Maîtrisez les actions dans FlutterFlow",
                orderIndex: 2
            ),
            VideoContent(
                id: "vid-4",
                title: "Partie 4 : Navigation",
                duration: 198,
                videoUrl: "https://youtube.com/watch?v=example4",
                thumbnailUrl: nil,
                description: "Implémentez la navigation entre les écrans",
                orderIndex: 3
            ),
            VideoContent(
                id: "vid-5",
                title: "Partie 5 : Création de Projet Firebase – Activation du Storage",
                duration: 412,
                videoUrl: "https://youtube.com/watch?v=example5",
                thumbnailUrl: nil,
                description: "Configurez Firebase et utilisez le stockage cloud",
                orderIndex: 4
            )
        ],
        courseId: "course-1",
        createdDate: "2024-01-15",
        updatedDate: "2024-11-09"
    )
}

// MARK: - Preview
#Preview {
    LessonsView(lesson: .sampleLesson)
}
