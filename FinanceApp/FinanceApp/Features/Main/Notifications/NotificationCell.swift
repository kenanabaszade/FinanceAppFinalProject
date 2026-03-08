//
//  NotificationCell.swift
//  FinanceApp
//
//  Created by Macbook on 2.03.26.
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
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = AppConstants.Colors.authTitle
        l.numberOfLines = 2
        return l
    }()
    
    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = AppConstants.Colors.authSubtitle
        l.numberOfLines = 2
        return l
    }()
    
    private let timeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        return l
    }()
    
    private let unreadDot: UIView = {
        let v = UIView()
        v.backgroundColor = AppConstants.Colors.mandarinOrange
        v.layer.cornerRadius = 5
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
        cardView.addSubview(titleLabel)
        cardView.addSubview(bodyLabel)
        cardView.addSubview(timeLabel)
        setupConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupConstraints() {
        let pad = AppConstants.Notifications.cardInnerPadding
        let vert = AppConstants.Notifications.cardVerticalSpacing
        
        cardView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Notifications.horizontalInset)
            make.trailing.equalToSuperview().inset(AppConstants.Notifications.horizontalInset)
            make.top.equalToSuperview().offset(vert / 2)
            make.bottom.equalToSuperview().offset(-vert / 2)
        }
        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(pad)
            make.top.equalToSuperview().offset(pad)
            make.width.height.equalTo(AppConstants.Notifications.iconSize)
        }
        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }
        unreadDot.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(pad)
            make.top.equalToSuperview().offset(pad)
            make.width.height.equalTo(10)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(pad)
            make.trailing.lessThanOrEqualTo(unreadDot.snp.leading).offset(-8)
            make.top.equalTo(iconContainer)
        }
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-pad)
        }
    }
    
    func configure(with notification: NotificationRecord) {
        titleLabel.text = notification.title
        bodyLabel.text = notification.body
        bodyLabel.isHidden = (notification.body == nil || notification.body?.isEmpty == true)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: notification.createdAt)
        
        let isUnread = !notification.read
        unreadDot.isHidden = !isUnread
        titleLabel.font = isUnread ? .systemFont(ofSize: 16, weight: .semibold) : .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = isUnread ? AppConstants.Colors.authTitle : AppConstants.Colors.authSubtitle
        cardView.backgroundColor = isUnread
        ? AppConstants.Colors.authCardBackground
        : AppConstants.Colors.authCardBackground.withAlphaComponent(0.7)
        
        iconContainer.backgroundColor = Self.iconColor(for: notification.type)
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconImageView.image = UIImage(systemName: Self.iconName(for: notification.type), withConfiguration: config)
    }
    
    private static func iconColor(for type: String?) -> UIColor {
        switch type {
        case NotificationType.transferReceived.rawValue: return UIColor.systemGreen.withAlphaComponent(0.3)
        case NotificationType.payment.rawValue: return UIColor.systemOrange.withAlphaComponent(0.3)
        case NotificationType.topUp.rawValue: return UIColor.systemBlue.withAlphaComponent(0.3)
        case "money_request": return UIColor.systemOrange.withAlphaComponent(0.3)
        case "transfer_request": return UIColor.systemBlue.withAlphaComponent(0.3)
        default: return AppConstants.Colors.transactionIconBg
        }
    }
    
    private static func iconName(for type: String?) -> String {
        switch type {
        case NotificationType.transferReceived.rawValue: return "arrow.down.left"
        case NotificationType.payment.rawValue: return "creditcard"
        case NotificationType.topUp.rawValue: return "plus.circle"
        case "money_request": return "arrow.up.circle"
        case "transfer_request": return "arrow.down.circle"
        default: return "bell.fill"
        }
    }
}
