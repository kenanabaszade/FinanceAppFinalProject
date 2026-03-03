//
//  NotificationCell.swift
//  FinanceApp
//

import UIKit
import SnapKit

final class NotificationCell: UITableViewCell {

    static let reuseId = "NotificationCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.authCardBackground
        v.layer.cornerRadius = AppConstants.Notifications.cardCornerRadius
        return v
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.layer.cornerRadius = AppConstants.Notifications.iconSize / 2
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = AppConstants.Fonts.bodySemibold(size: 15)
        l.textColor = AppConstants.Colors.authTitle
        l.numberOfLines = 2
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = AppConstants.Fonts.caption(size: 13)
        l.textColor = AppConstants.Colors.authSubtitle
        l.numberOfLines = 2
        return l
    }()

    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = AppConstants.Fonts.caption(size: 12)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = AppConstants.Fonts.caption(size: 11)
        return l
    }()

    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.mandarinOrange
        v.layer.cornerRadius = 4
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(cardView)
        cardView.addSubview(iconContainer)
        iconContainer.addSubview(iconImageView)
        cardView.addSubview(unreadDot)
        cardView.addSubview(statusLabel)
        cardView.addSubview(titleLabel)
        cardView.addSubview(bodyLabel)
        cardView.addSubview(timeLabel)
        cardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Notifications.horizontalInset)
            make.trailing.equalToSuperview().inset(AppConstants.Notifications.horizontalInset)
            make.top.equalToSuperview().offset(AppConstants.Notifications.cardVerticalSpacing / 2)
            make.bottom.equalToSuperview().offset(-AppConstants.Notifications.cardVerticalSpacing / 2)
        }
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Spacing.medium)
            make.top.equalToSuperview().offset(14)
            make.width.height.equalTo(AppConstants.Notifications.iconSize)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        unreadDot.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.Spacing.medium)
            make.top.equalToSuperview().offset(14)
            make.width.height.equalTo(8)
        }
        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppConstants.Spacing.medium)
            make.centerY.equalTo(timeLabel)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(AppConstants.Spacing.medium)
            make.trailing.lessThanOrEqualTo(unreadDot.snp.leading).offset(-8)
            make.top.equalTo(iconContainer)
        }
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(unreadDot.snp.leading).offset(-8)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(4)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with notification: NotificationRecord) {
        titleLabel.text = notification.title
        bodyLabel.text = notification.body
        bodyLabel.isHidden = (notification.body == nil || notification.body?.isEmpty == true)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: notification.createdAt)

        let isUnread = !notification.read
        unreadDot.isHidden = !isUnread
        statusLabel.text = isUnread ? "Unread" : "Read"
        statusLabel.textColor = isUnread ? AppConstants.Colors.mandarinOrange : AppConstants.Colors.authSubtitle
        titleLabel.font = isUnread ? AppConstants.Fonts.bodySemibold(size: 15) : AppConstants.Fonts.body(size: 15)
        titleLabel.textColor = isUnread ? AppConstants.Colors.authTitle : AppConstants.Colors.authSubtitle
        cardView.backgroundColor = isUnread
            ? AppConstants.Colors.authCardBackground
            : AppConstants.Colors.authCardBackground.withAlphaComponent(0.6)

        iconContainer.backgroundColor = Self.iconColor(for: notification.type)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: Self.iconName(for: notification.type), withConfiguration: config)
    }

    private static func iconColor(for type: String?) -> UIColor {
        switch type {
        case NotificationType.transferReceived.rawValue: return UIColor.systemGreen.withAlphaComponent(0.25)
        case NotificationType.payment.rawValue: return UIColor.systemOrange.withAlphaComponent(0.25)
        case NotificationType.topUp.rawValue: return UIColor.systemBlue.withAlphaComponent(0.25)
        default: return AppConstants.Colors.transactionIconBg
        }
    }

    private static func iconName(for type: String?) -> String {
        switch type {
        case NotificationType.transferReceived.rawValue: return "arrow.down.left"
        case NotificationType.payment.rawValue: return "creditcard"
        case NotificationType.topUp.rawValue: return "plus.circle"
        default: return "bell.fill"
        }
    }
}
