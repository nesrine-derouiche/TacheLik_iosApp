import SwiftUI

// MARK: - Teacher Profile Card
struct TeacherProfileCard: View {
    let teacher: Teacher
    @State private var selectedSocialLink: SocialLink?
    
    var hasSocialLinks: Bool {
        teacher.socialLinks != nil && !teacher.socialLinks!.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.paddingMD) {
            // Teacher Header
            Text("Teacher")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            // Teacher Info Container
            HStack(spacing: DS.paddingMD) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.brandPrimary, Color.brandPrimaryHover],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    if let profileImage = teacher.profileImage, profileImage.count > 0 {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 60, height: 60)
                .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Teacher Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(teacher.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(teacher.email)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let bio = teacher.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(DS.paddingMD)
            .background(Color(.systemBackground))
            .cornerRadius(DS.cornerRadiusMD)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            
            // Social Links Section
            if hasSocialLinks {
                VStack(alignment: .leading, spacing: DS.paddingSM) {
                    Text("Connect")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    // Social Links Grid
                    FlowLayout(spacing: DS.paddingSM) {
                        ForEach(teacher.socialLinks ?? []) { link in
                            SocialLinkButton(socialLink: link)
                        }
                    }
                }
            }
        }
        .padding(DS.paddingMD)
        .background(
            RoundedRectangle(cornerRadius: DS.cornerRadiusMD)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Social Link Button
struct SocialLinkButton: View {
    let socialLink: SocialLink
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // In a real app, this would open the URL
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: socialLink.platform.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .background(
                LinearGradient(
                    colors: [socialLink.platform.color, socialLink.platform.color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .shadow(color: socialLink.platform.color.opacity(0.3), radius: 6, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
    }
}

// MARK: - Flow Layout Helper
struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) {
                content()
                Spacer()
            }
        }
    }
}

// MARK: - Teacher Profile Card Preview
#Preview {
    let sampleTeacher = Teacher(
        id: "1",
        name: "Dr. Mohamed Trabelsi",
        email: "m.trabelsi@esprit.tn",
        bio: "Expert in formal verification and theoretical computer science",
        profileImage: nil,
        socialLinks: [
            SocialLink(id: "1", platform: .email, url: "mailto:m.trabelsi@esprit.tn"),
            SocialLink(id: "2", platform: .linkedin, url: "https://linkedin.com/in/mtrabelsi"),
            SocialLink(id: "3", platform: .github, url: "https://github.com/mtrabelsi"),
            SocialLink(id: "4", platform: .website, url: "https://example.com")
        ]
    )
    
    TeacherProfileCard(teacher: sampleTeacher)
        .padding()
}
