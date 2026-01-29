import Foundation
import FirebaseAuth

class LoginViewModel {
    
    var onLoginSuccess: (() -> Void)?
    var onLoginError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onEmailNotVerified: (() -> Void)?
    
    func login(email: String, password: String) {
        if let validationError = ValidationHelper.validateLoginFields(email: email, password: password) {
            onLoginError?(validationError.message)
            return
        }
        
        onLoadingStateChanged?(true)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.onLoadingStateChanged?(false)
            
            if let error = error {
                let errorMessage = FirebaseErrorHandler.handleAuthError(error)
                self.onLoginError?(errorMessage)
                return
            }
            
            guard let user = authResult?.user else {
                self.onLoginError?(FirebaseAuthError.loginFailed.message)
                return
            }
            
            if !user.isEmailVerified {
                self.onEmailNotVerified?()
                return
            }
            
            self.onLoginSuccess?()
        }
    }
}
