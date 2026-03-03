//
//  HistoryTransactionCell.swift
//  FinanceApp
//

import UIKit
import SnapKit

final class HistoryTransactionCell: UITableViewCell {

    static let reuseId = "HistoryTransactionCell"
    static let cardVerticalSpacing: CGFloat = 6
    static let cardCornerRadius: CGFloat = 12
    static let horizontalInset: CGFloat = 16

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = HistoryTransactionCell.cardCornerRadius
        return v
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = AppConstants.History.iconSize / 2
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let merchantLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        return l
    }()

    private let subtitleLabel: UILabel = {
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(cardView)
        cardView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        cardView.addSubview(merchantLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(amountLabel)
        cardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(HistoryTransactionCell.horizontalInset)
            make.trailing.equalToSuperview().inset(HistoryTransactionCell.horizontalInset)
            make.top.equalToSuperview().offset(HistoryTransactionCell.cardVerticalSpacing / 2)
            make.bottom.equalToSuperview().offset(-HistoryTransactionCell.cardVerticalSpacing / 2)
        }
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Spacing.medium)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(AppConstants.History.iconSize)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        merchantLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(AppConstants.Spacing.medium)
            make.top.equalToSuperview().offset(14)
            make.trailing.lessThanOrEqualTo(amountLabel.snp.leading).offset(-AppConstants.Spacing.small)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(merchantLabel)
            make.top.equalTo(merchantLabel.snp.bottom).offset(2)
        }
        amountLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.Spacing.medium)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with transaction: TransactionRecord) {
        merchantLabel.text = transaction.merchantName
        let categoryName = Self.categoryDisplayName(category: transaction.category, type: transaction.type)
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        subtitleLabel.text = "\(categoryName) • \(timeFormatter.string(from: transaction.date))"
        iconContainer.backgroundColor = Self.iconBackgroundColor(category: transaction.category, type: transaction.type)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: Self.categoryIcon(category: transaction.category, type: transaction.type), withConfiguration: config)

        let symbol: String
        switch transaction.currency {
        case "AZN": symbol = " ₼"
        case "USD": symbol = " $"
        default: symbol = " " + transaction.currency
        }
        let isOutgoing = transaction.type == .send || transaction.type == .purchase
        let absAmount = abs(transaction.amount)
        if isOutgoing {
            amountLabel.text = "-" + String(format: "%.2f", absAmount) + symbol
            amountLabel.textColor = AppConstants.Colors.authTitle
        } else {
            amountLabel.text = "+" + String(format: "%.2f", absAmount) + symbol
            amountLabel.textColor = UIColor.systemGreen
        }
    }

    private static func categoryDisplayName(category: String?, type: TransactionType) -> String {
        switch type {
        case .send, .receive: return "Köçürmə"
        case .request: return "İstək"
        case .topUp: return "Yüklə"
        case .exchange: return "Mübadilə"
        case .purchase:
            switch category?.lowercased() {
            case "utilities": return "Kommunal"
            case "mobile": return "Mobil"
            case "bank": return "Bank"
            case "transport": return "Nəqliyyat"
            case "fines": return "Cərimə"
            case "internet": return "İnternet & TV"
            case "insurance": return "Sığorta"
            case "other": return "Digər"
            default: return "Alış-veriş"
            }
        }
    }

    private static func iconBackgroundColor(category: String?, type: TransactionType) -> UIColor {
        switch type {
        case .send, .receive: return UIColor.systemGreen.withAlphaComponent(0.25)
        case .topUp: return UIColor.systemBlue.withAlphaComponent(0.25)
        case .exchange: return UIColor.systemPurple.withAlphaComponent(0.25)
        case .request: return UIColor.systemOrange.withAlphaComponent(0.25)
        case .purchase:
            switch category?.lowercased() {
            case "utilities": return UIColor.systemOrange.withAlphaComponent(0.25)
            case "transport": return UIColor.systemBlue.withAlphaComponent(0.25)
            case "internet", "insurance": return UIColor.systemPurple.withAlphaComponent(0.25)
            case "fines": return UIColor.systemRed.withAlphaComponent(0.2)
            default: return UIColor.systemBlue.withAlphaComponent(0.25)
            }
        }
    }

    private static func categoryIcon(category: String?, type: TransactionType) -> String {
        switch type {
        case .send: return "arrow.up.right"
        case .receive: return "arrow.down.left"
        case .request: return "arrow.down.left"
        case .topUp: return "plus.circle"
        case .exchange: return "arrow.triangle.2.circlepath"
        case .purchase:
            switch category?.lowercased() {
            case "utilities": return "bolt.fill"
            case "mobile": return "iphone"
            case "bank": return "creditcard.fill"
            case "transport": return "bus.fill"
            case "fines": return "doc.badge.gearshape"
            case "internet": return "wifi"
            case "insurance": return "shield.fill"
            default: return "cart.fill"
            }
        }
    }
}
