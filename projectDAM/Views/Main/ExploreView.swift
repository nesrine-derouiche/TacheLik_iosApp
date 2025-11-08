import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
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
                    
                    // Tags
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
