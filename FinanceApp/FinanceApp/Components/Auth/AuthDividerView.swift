import UIKit
import SnapKit

final class AuthDividerView: UIView {

    private let label: UILabel = {
        let label = UILabel()
        label.text = "OR CONTINUE WITH"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = AppConstants.Colors.authDividerText
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let leftLine: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authDividerLine
        return v
    }()

    private let rightLine: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authDividerLine
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(leftLine)
        addSubview(label)
        addSubview(rightLine)

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        leftLine.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.trailing.equalTo(label.snp.leading).offset(-12)
            make.height.equalTo(1)
        }
        rightLine.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(label.snp.trailing).offset(12)
            make.height.equalTo(1)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
