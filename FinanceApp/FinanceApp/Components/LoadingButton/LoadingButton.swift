import UIKit
import SnapKit

class LoadingButton: AppButton {
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var originalTitle: String = ""
    
    override init(style: AppButton.ButtonStyle, title: String) {
        super.init(style: style, title: title)
        originalTitle = title
        setupLoadingIndicator()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLoadingIndicator() {
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
    }
    
    func setLoading(_ isLoading: Bool) {
        isEnabled = !isLoading
        alpha = isLoading ? 0.6 : 1.0
        
        if isLoading {
            activityIndicator.startAnimating()
            setTitle("", for: .normal)
        } else {
            activityIndicator.stopAnimating()
            setTitle(originalTitle, for: .normal)
        }
    }
}
