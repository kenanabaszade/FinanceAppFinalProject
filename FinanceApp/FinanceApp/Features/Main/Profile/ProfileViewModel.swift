//
//  ProfileViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 2.24.26.
//

import Foundation
import Combine
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published private(set) var isUploadingImage = false
    @Published var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    private let storageService: StorageServiceProtocol
    
    private let profileImageMaxDimension: CGFloat = 200
    
    init(
        authService: AuthServiceProtocol,
        firestoreService: FirestoreServiceProtocol,
        storageService: StorageServiceProtocol
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.storageService = storageService
    }
    
    var displayName: String {
        guard let user = user else { return "—" }
        let name = user.fullName
        return name.isEmpty ? (user.email ?? "—") : name
    }
    
    var accountIdDisplay: String {
        guard let uid = user?.uid, uid.count >= 6 else { return "—" }
        return String(uid.suffix(6))
    }
    
    func loadUser() async {
        guard let uid = authService.currentUserId() else {
            user = nil
            return
        }
        if let cached = UserCache.shared.getCachedUser(uid: uid) {
            user = cached
        }
        do {
            let fetched = try await firestoreService.getUser(uid: uid)
            user = fetched
            if let fetched = fetched {
                UserCache.shared.setCachedUser(fetched)
            }
        } catch {
            user = UserCache.shared.getCachedUser(uid: uid)
        }
    }
    
    func uploadAndSetProfileImage(_ imageData: Data) async {
        guard authService.currentUserId() != nil else {
            errorMessage = "Not signed in"
            return
        }
        guard var currentUser = user else {
            errorMessage = "User not loaded"
            return
        }
        isUploadingImage = true
        errorMessage = nil
        defer { isUploadingImage = false }
        do {
            let base64 = compressAndEncodeProfileImage(imageData)
            currentUser.profileImageBase64 = base64
            currentUser.profileImageURL = nil
            try await firestoreService.updateUser(currentUser)
            UserCache.shared.setCachedUser(currentUser)
            user = currentUser
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func compressAndEncodeProfileImage(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = image.resized(maxDimension: profileImageMaxDimension)
        guard let jpeg = resized.jpegData(compressionQuality: 0.5) else { return nil }
        return jpeg.base64EncodedString()
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        guard w > maxDimension || h > maxDimension else { return self }
        let ratio = min(maxDimension / w, maxDimension / h)
        let newSize = CGSize(width: w * ratio, height: h * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
