import UIKit
import SnapKit

final class TransactionRowView: UIView {

    private let iconContainer: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.transactionIconBg
        v.layer.cornerRadius = AppConstants.Dashboard.transactionIconSize / 2
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = AppConstants.Colors.mandarinOrange
        return iv
    }()

    private let merchantLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()

    private let amountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .bold)
        l.textAlignment = .right
        return l
    }()

    init(transaction: TransactionRecord) {
        super.init(frame: .zero)
        setupHierarchy()
        setupLayout()
        configure(with: transaction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupHierarchy() {
        addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        addSubview(merchantLabel)
        addSubview(dateLabel)
        addSubview(amountLabel)
    }

    private func setupLayout() {
        self.snp.makeConstraints { make in
            make.height.equalTo(AppConstants.Dashboard.transactionRowHeight)
        }
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Spacing.medium)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(AppConstants.Dashboard.transactionIconSize)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
        merchantLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(AppConstants.Spacing.medium)
            make.bottom.equalTo(iconContainer.snp.centerY).offset(-2)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-AppConstants.Spacing.small)
        }
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(merchantLabel)
            make.top.equalTo(iconContainer.snp.centerY).offset(3)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.Spacing.medium)
            make.centerY.equalToSuperview()
        }
    }

    private func configure(with transaction: TransactionRecord) {
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        iconImageView.image = UIImage(systemName: categoryIcon(for: transaction.category, type: transaction.type), withConfiguration: config)
        merchantLabel.text = transaction.merchantName
        dateLabel.text = formatDate(transaction.date)

        let symbol: String
        switch transaction.currency {
        case "AZN": symbol = "₼"
        case "USD": symbol = "$"
        default: symbol = transaction.currency
        }

        let isOutgoing = transaction.type == .send || transaction.type == .purchase
        let absAmount = abs(transaction.amount)
        if isOutgoing {
            amountLabel.text = "-" + String(format: "%.2f", absAmount) + symbol
            amountLabel.textColor = AppConstants.Colors.authTitle
        } else {
            amountLabel.text = "+" + String(format: "%.2f", absAmount) + symbol
            amountLabel.textColor = AppConstants.Colors.mandarinOrange
        }
    }

    private func categoryIcon(for category: String?, type: TransactionType) -> String {
        switch type {
        case .send:
            return "arrow.up.right"
        case .receive:
            return "arrow.down.left"
        case .request:
            return "arrow.down.left"
        case .topUp:
            return "plus.circle"
        case .exchange:
            return "arrow.triangle.2.circlepath"
        case .purchase:
            switch category?.lowercased() {
            case "shopping": return "cart.fill"
            case "food": return "fork.knife"
            case "transport": return "car.fill"
            default: return "cart.fill"
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Today, " + formatter.string(from: date)
        }
        if cal.isDateInYesterday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return "Yesterday, " + formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        return formatter.string(from: date)
    }
}
