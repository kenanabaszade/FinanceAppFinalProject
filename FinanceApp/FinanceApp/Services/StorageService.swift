//
//  StorageService.swift
//  FinanceApp
//

import Foundation
import FirebaseStorage

protocol StorageServiceProtocol: AnyObject {
    /// Uploads profile image data for the given user; returns the download URL.
    func uploadProfileImage(userId: String, imageData: Data) async throws -> String
}

final class StorageService: StorageServiceProtocol {
    private let storage = Storage.storage()

    func uploadProfileImage(userId: String, imageData: Data) async throws -> String {
        let ref = storage.reference()
            .child("profile_images")
            .child("\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
