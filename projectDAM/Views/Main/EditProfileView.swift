import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPhotoSheet = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var pendingImageData: Data?
    @State private var pendingImageMimeType: String?
    @State private var pendingImageFileName: String?
    @State private var showTeacherPhotoSheet = false
    @State private var teacherPhotoPickerItem: PhotosPickerItem?
    @State private var pendingTeacherImageData: Data?
    @State private var pendingTeacherImageMimeType: String?
    @State private var pendingTeacherImageFileName: String?
    
    init(viewModel: EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let maxContentWidth: CGFloat = 640
            let horizontalPadding = max((geometry.size.width - maxContentWidth) / 2, 20)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    personalInfoSection
                    if viewModel.isTeacher {
                        teacherInfoSection
                    }
                }
                .frame(maxWidth: maxContentWidth)
                .padding(.vertical, 24)
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, DS.barHeight + 8)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadTeacherProfileIfNeeded()
        }
        .alert(item: $viewModel.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK")) {
                    if alert.title == "Profile Updated" {
                        dismiss()
                    }
                }
            )
        }
        .sheet(isPresented: $showPhotoSheet) {
            PhotoSelectionSheet(
                pendingImageData: $pendingImageData,
                pendingImageMimeType: $pendingImageMimeType,
                pendingImageFileName: $pendingImageFileName,
                photoPickerItem: $photoPickerItem,
                onCancel: {
                    pendingImageData = nil
                    pendingImageMimeType = nil
                    pendingImageFileName = nil
                    showPhotoSheet = false
                },
                onSave: {
                    if let data = pendingImageData {
                        viewModel.setSelectedImage(
                            data: data,
                            fileName: pendingImageFileName,
                            mimeType: pendingImageMimeType
                        )
                    }
                    showPhotoSheet = false
                }
            )
        }
        .onChange(of: photoPickerItem) { _ in
            guard let newItem = photoPickerItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    pendingImageData = data
                    pendingImageMimeType = newItem.supportedContentTypes.first?.preferredMIMEType
                    let fileExtension = newItem.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                    pendingImageFileName = "profile_\(UUID().uuidString).\(fileExtension)"
                }
            }
        }
        .sheet(isPresented: $showTeacherPhotoSheet) {
            PhotoSelectionSheet(
                pendingImageData: $pendingTeacherImageData,
                pendingImageMimeType: $pendingTeacherImageMimeType,
                pendingImageFileName: $pendingTeacherImageFileName,
                photoPickerItem: $teacherPhotoPickerItem,
                onCancel: {
                    pendingTeacherImageData = nil
                    pendingTeacherImageMimeType = nil
                    pendingTeacherImageFileName = nil
                    showTeacherPhotoSheet = false
                },
                onSave: {
                    if let data = pendingTeacherImageData {
                        viewModel.setSelectedTeacherImage(
                            data: data,
                            fileName: pendingTeacherImageFileName,
                            mimeType: pendingTeacherImageMimeType
                        )
                    }
                    showTeacherPhotoSheet = false
                }
            )
        }
        .onChange(of: teacherPhotoPickerItem) { _ in
            guard let newItem = teacherPhotoPickerItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    pendingTeacherImageData = data
                    pendingTeacherImageMimeType = newItem.supportedContentTypes.first?.preferredMIMEType
                    let fileExtension = newItem.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                    pendingTeacherImageFileName = "teacher_\(UUID().uuidString).\(fileExtension)"
                }
            }
        }
    }
    
    // MARK: - Sections
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                profileImage
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 8)
                Button {
                    pendingImageData = nil
                    pendingImageMimeType = nil
                    pendingImageFileName = nil
                    showPhotoSheet = true
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.brandPrimary)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
            }
            Text(viewModel.username)
                .font(.title2.weight(.semibold))
            Text(viewModel.role.rawValue)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.brandPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.brandPrimary.opacity(0.1))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("Username", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    if !viewModel.usernameValidation.isValid,
                       let message = viewModel.usernameValidation.errorMessage {
                        validationMessage(message)
                    }
                }
                readOnlyField(label: "Email", value: viewModel.email)
                if let date = viewModel.formattedCreationDate {
                    readOnlyField(label: "Creation Date", value: date)
                }
                readOnlyField(label: "Role", value: viewModel.role.rawValue)
                
                // Save Personal Info Button
                Button {
                    Task { await viewModel.savePersonalInfo() }
                } label: {
                    Text(viewModel.isSavingPersonalInfo ? "Saving..." : "Save Personal Info")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSavePersonalInfo ? Color.brandPrimary : Color.brandPrimary.opacity(0.4))
                        .cornerRadius(16)
                }
                .disabled(!viewModel.canSavePersonalInfo)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    private var teacherInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Teacher Information")
                .font(.headline)
            VStack(spacing: 16) {
                // Teacher Image Section
                VStack(spacing: 12) {
                    Text("Teacher Profile Image")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ZStack(alignment: .bottomTrailing) {
                        teacherProfileImage
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(radius: 6)
                        
                        Button {
                            pendingTeacherImageData = nil
                            pendingTeacherImageMimeType = nil
                            pendingTeacherImageFileName = nil
                            showTeacherPhotoSheet = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(Color.brandPrimary))
                                .shadow(radius: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                nameField(label: "First Name", text: $viewModel.firstName, validation: viewModel.firstNameValidation)
                nameField(label: "Last Name", text: $viewModel.lastName, validation: viewModel.lastNameValidation)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $viewModel.bio)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                }
                socialField(label: "GitHub", placeholder: "https://github.com/username", text: $viewModel.github, validation: viewModel.githubValidation)
                socialField(label: "LinkedIn", placeholder: "https://www.linkedin.com/in/username", text: $viewModel.linkedin, validation: viewModel.linkedinValidation)
                socialField(label: "Facebook", placeholder: "https://www.facebook.com/username", text: $viewModel.facebook, validation: viewModel.facebookValidation)
                
                // Save Teacher Info Button
                Button {
                    Task { await viewModel.saveTeacherInfo() }
                } label: {
                    Text(viewModel.isSavingTeacherInfo ? "Saving..." : "Save Teacher Info")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSaveTeacherInfo ? Color.brandPrimary : Color.brandPrimary.opacity(0.4))
                        .cornerRadius(16)
                }
                .disabled(!viewModel.canSaveTeacherInfo)
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    
    // MARK: - Subviews
    private var profileImage: some View {
        Group {
            if let data = pendingImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let data = viewModel.selectedImageData,
                      let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = viewModel.existingImageURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderAvatar
                    case .empty:
                        ProgressView()
                    @unknown default:
                        placeholderAvatar
                    }
                }
            } else {
                placeholderAvatar
            }
        }
    }
    
    private var teacherProfileImage: some View {
        Group {
            if let data = pendingTeacherImageData,
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let data = viewModel.selectedTeacherImageData,
                      let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlString = viewModel.existingTeacherImageURL,
                      !urlString.isEmpty {
                if urlString.hasPrefix("data:image") {
                    // Handle base64 data URL
                    if let data = Data(base64Encoded: urlString.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")),
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        teacherPlaceholderAvatar
                    }
                } else {
                    // Handle regular URL
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            teacherPlaceholderAvatar
                        case .empty:
                            ProgressView()
                        @unknown default:
                            teacherPlaceholderAvatar
                        }
                    }
                }
            } else {
                teacherPlaceholderAvatar
            }
        }
    }
    
    private var placeholderAvatar: some View {
        ZStack {
            Circle().fill(Color.brandPrimary.opacity(0.2))
            Image(systemName: "person.fill")
                .font(.system(size: 48))
                .foregroundColor(.brandPrimary)
        }
    }
    
    private var teacherPlaceholderAvatar: some View {
        ZStack {
            Circle().fill(Color.brandAccent.opacity(0.2))
            Image(systemName: "person.fill.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.brandAccent)
        }
    }
    
    private func readOnlyField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemFill))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.03))
                )
        }
    }
    
    private func nameField(label: String, text: Binding<String>, validation: ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(label, text: text)
                .textInputAutocapitalization(.words)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            if !validation.isValid, let message = validation.errorMessage {
                validationMessage(message)
            }
        }
    }
    
    private func socialField(label: String, placeholder: String, text: Binding<String>, validation: ValidationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            if !validation.isValid, let message = validation.errorMessage {
                validationMessage(message)
            }
        }
    }
    
    private func validationMessage(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
    }
}

// MARK: - Photo Selection Sheet
private struct PhotoSelectionSheet: View {
    @Binding var pendingImageData: Data?
    @Binding var pendingImageMimeType: String?
    @Binding var pendingImageFileName: String?
    @Binding var photoPickerItem: PhotosPickerItem?
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Edit Profile Photo")
                    .font(.title3.weight(.semibold))
                Text("Click to upload or drag & drop PNG, JPG, GIF (max 10MB)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                PhotosPicker(
                    selection: $photoPickerItem,
                    matching: .images
                ) {
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 32))
                        Text("Choose Photo")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(18)
                }
                if let data = pendingImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(pendingImageData == nil)
                }
            }
        }
    }
}
