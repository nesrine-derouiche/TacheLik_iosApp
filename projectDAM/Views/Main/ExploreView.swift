import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var showReelsView = false
    @State private var featuredReels: [Reel] = []
    @State private var isLoadingReels = false
    
    private let reelService = DIContainer.shared.reelService
    
    private let tags = ["All","Web","Data","AI","Cloud","Security","Mobile","DevOps"]
    private let categories: [ExploreCategory] = [
        .init(name: "Web Development", icon: "globe", colors: [.brandPrimary, .brandAccent], courses: 24),
        .init(name: "Data Science", icon: "chart.bar.doc.horizontal", colors: [.brandAccent, .brandSecondary], courses: 18),
        .init(name: "Cloud Computing", icon: "cloud.fill", colors: [.brandSecondary, .brandPrimary], courses: 16),
        .init(name: "Cybersecurity", icon: "lock.shield.fill", colors: [.brandPrimary, .brandWarning], courses: 12),
        .init(name: "Machine Learning", icon: "brain.head.profile", colors: [.brandAccent, .brandSuccess], courses: 20),
        .init(name: "Mobile Apps", icon: "iphone.homebutton", colors: [.brandSuccess, .brandAccent], courses: 14)
    ]
    
    private var filteredCategories: [ExploreCategory] {
        categories.filter { cat in
            let tagMatches = selectedTag == nil || selectedTag == "All" || cat.matches(tag: selectedTag!)
            let searchMatches = searchText.isEmpty || cat.name.lowercased().contains(searchText.lowercased())
            return tagMatches && searchMatches
        }
    }
    
    let adaptiveColumns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 20) {
                        // Search
                        searchBar
                        
                        // Tags
                        tagsScrollView
                        
                        // Reels Section - Always show
                        reelsSection
                        
                        // Categories Header
                        HStack {
                            Text("Browse Categories")
                                .font(.title3.weight(.bold))
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Categories Grid
                        LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                            ForEach(filteredCategories) { cat in
                                GradientCard(colors: cat.colors) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 26, weight: .semibold))
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(cat.courses) courses")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.85))
                                        }
                                        Text(cat.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        Button(action: {}) {
                                            HStack(spacing: 6) {
                                                Text("Browse")
                                                Image(systemName: "arrow.right")
                                            }
                                            .font(.footnote.bold())
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 14)
                                            .background(Color.white.opacity(0.18))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 150)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .padding(.top)
                    .padding(.bottom, DS.barHeight + 8)
                }
                .navigationTitle("Explore")
            }
        }
        .fullScreenCover(isPresented: $showReelsView) {
            ReelsView(reelService: reelService)
        }
        .task {
            await loadFeaturedReels()
        }
        .onReceive(NotificationCenter.default.publisher(for: .reelCreated)) { _ in
            // Refresh reels when a new one is created by teacher
            Task {
                await loadFeaturedReels()
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search courses, topics...", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemFill))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - Tags Scroll View
    private var tagsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tags, id: \.self) { tag in
                    Chip(title: tag, isSelected: tag == (selectedTag ?? "All")) {
                        if tag == "All" { selectedTag = nil } else { selectedTag = tag }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Reels Section
    private var reelsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.title3)
                        .foregroundColor(.brandPrimary)
                    Text("Reels")
                        .font(.title3.weight(.bold))
                }
                
                Spacer()
                
                Button {
                    showReelsView = true
                } label: {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.brandPrimary)
                }
            }
            .padding(.horizontal)
            
            // Reels Horizontal Scroll
            if isLoadingReels {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        ReelPreviewPlaceholder()
                    }
                }
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(featuredReels) { reel in
                            ReelPreviewCard(reel: reel) {
                                showReelsView = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Load Featured Reels
    private func loadFeaturedReels() async {
        isLoadingReels = true
        
        do {
            let reels = try await reelService.fetchFeaturedReels(limit: 6)
            // Use fetched reels if available, otherwise use ReelStorage (includes teacher-created + mock)
            featuredReels = reels.isEmpty ? ReelStorage.shared.getAllReels() : reels
        } catch {
            print("❌ [ExploreView] Failed to load reels: \(error)")
            // Use ReelStorage which includes teacher-created reels + mock data
            featuredReels = ReelStorage.shared.getAllReels()
        }
        
        isLoadingReels = false
    }
}

// MARK: - Reel Preview Card
private struct ReelPreviewCard: View {
    let reel: Reel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background Image
                AsyncImage(url: reel.displayImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        LinearGradient(
                            colors: [.brandPrimary, .brandAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: 140, height: 200)
                .clipped()
                
                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Type badge
                    HStack(spacing: 4) {
                        Image(systemName: reel.type.iconName)
                            .font(.system(size: 8))
                        Text(reel.type.displayName)
                            .font(.system(size: 8, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                    
                    Text(reel.title)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Stats
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 8))
                            Text(formatCount(reel.viewsCount))
                                .font(.system(size: 9))
                        }
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                            Text(formatCount(reel.likesCount))
                                .font(.system(size: 9))
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(10)
                
                // Play icon
                if reel.hasVideo {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 140, height: 200)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        } else if count >= 1_000 {
            return String(format: "%.1fK", Double(count) / 1_000)
        }
        return "\(count)"
    }
}

// MARK: - Reel Preview Placeholder
private struct ReelPreviewPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemFill))
            .frame(width: 140, height: 200)
            .overlay(
                ProgressView()
            )
    }
}

private struct Chip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient.brandPrimaryGradient
                        } else {
                            Color(.secondarySystemBackground)
                        }
                    }
                )
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

private struct GradientCard<Content: View>: View {
    let colors: [Color]
    let content: Content
    
    init(colors: [Color], @ViewBuilder content: () -> Content) {
        self.colors = colors
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: colors.first?.opacity(0.3) ?? Color.clear, radius: 12, x: 0, y: 6)
    }
}

private struct ExploreCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colors: [Color]
    let courses: Int
    
    func matches(tag: String) -> Bool {
        let lower = tag.lowercased()
        return name.lowercased().contains(lower) ||
            (lower == "web" && name.lowercased().contains("web")) ||
            (lower == "data" && name.lowercased().contains("data")) ||
            (lower == "ai" && name.lowercased().contains("machine")) ||
            (lower == "cloud" && name.lowercased().contains("cloud")) ||
            (lower == "security" && name.lowercased().contains("cyber")) ||
            (lower == "mobile" && name.lowercased().contains("mobile")) ||
            (lower == "devops" && name.lowercased().contains("cloud"))
    }
}

#Preview {
    ExploreView()
}
