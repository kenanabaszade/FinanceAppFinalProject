import Foundation
import FirebaseAuth

class SignupViewModel {
    
    var onSignupSuccess: (() -> Void)?
    var onSignupError: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    func signup(email: String, password: String, confirmPassword: String) {
        if let validationError = ValidationHelper.validateSignupFields(email: email, password: password, confirmPassword: confirmPassword) {
            onSignupError?(validationError.message)
            return
        }
        
        onLoadingStateChanged?(true)
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }
            
            self.onLoadingStateChanged?(false)
            
            if let error = error {
                let errorMessage = FirebaseErrorHandler.handleAuthError(error)
                self.onSignupError?(errorMessage)
                return
            }
            
            guard let user = authResult?.user else {
                self.onSignupError?(FirebaseAuthError.signupFailed.message)
                return
            }
            
            user.sendEmailVerification { error in
                if let error = error {
                    let errorMessage = FirebaseErrorHandler.handleVerificationError(error)
                    self.onSignupError?(errorMessage)
                    return
                }
                
                self.onSignupSuccess?()
            }
        }
    }
}
