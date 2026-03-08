//
//  ProfilePersonalInfoViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 2.24.26.
//

import Foundation
import Combine

@MainActor
final class ProfilePersonalInfoViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let authService: AuthServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    init(authService: AuthServiceProtocol, firestoreService: FirestoreServiceProtocol) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func load() async {
        guard let uid = authService.currentUserId() else {
            errorMessage = "Not signed in"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            if let u = try await firestoreService.getUser(uid: uid) {
                user = u
            } else {
                errorMessage = "Could not load your profile."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    
    var firstName: String {
        user?.firstName ?? "—"
    }
    
    var lastName: String {
        user?.lastName ?? "—"
    }
    
    var fatherName: String {
        "—"
    }
    
    var countryOfBirth: String {
        user?.country ?? "—"
    }
    
    var dateOfBirthText: String {
        guard let dob = user?.dateOfBirth else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: dob)
    }
    
    var email: String {
        user?.email ?? "—"
    }
}

