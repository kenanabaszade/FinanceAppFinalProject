import UIKit
import SnapKit

final class AuthHeaderView: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = AppConstants.Colors.authTitle
        label.numberOfLines = 1
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = AppConstants.Colors.authSubtitle
        label.numberOfLines = 2
        return label
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
