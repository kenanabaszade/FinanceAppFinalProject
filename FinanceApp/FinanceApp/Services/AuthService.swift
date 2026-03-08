//
//  AuthService.swift
//  FinanceApp
//
//  Created by Macbook on 06.02.26.
//

import Foundation
import FirebaseAuth

protocol AuthServiceProtocol {
    func createUser(email: String, password: String) async throws -> String
    func signIn(email: String, password: String) async throws
    func signOut() throws
    func sendEmailVerification() async throws
    func sendPasswordReset(email: String) async throws
    func reloadCurrentUser() async throws
    func isCurrentUserEmailVerified() -> Bool
    func currentUserId() -> String?
    func currentUserEmail() -> String?
}

class AuthService: AuthServiceProtocol {
    func createUser(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signIn(email: String, password: String) async throws {
        _ = try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.sendEmailVerification()
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func reloadCurrentUser() async throws {
        try await Auth.auth().currentUser?.reload()
    }

    func isCurrentUserEmailVerified() -> Bool {
        Auth.auth().currentUser?.isEmailVerified == true
    }

    func currentUserId() -> String? {
        Auth.auth().currentUser?.uid
    }

    func currentUserEmail() -> String? {
        Auth.auth().currentUser?.email
    }
}
