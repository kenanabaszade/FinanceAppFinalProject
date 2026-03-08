//
//  NotificationsViewController.swift
//  FinanceApp
//
//  Created by Macbook on 2.03.26.
//

import UIKit
import SnapKit
import Combine

final class NotificationsViewController: UIViewController {

    weak var coordinator: OnboardingCoordinator?
    private let viewModel: NotificationsViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = AppConstants.Colors.dashboardBackground
        tv.separatorStyle = .none
        tv.sectionHeaderTopPadding = 0
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No notifications"
        l.font = AppConstants.Fonts.body(size: 16)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        l.isHidden = true
        l.numberOfLines = 0
        return l
    }()


    private let activityIndicator: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()

    init(viewModel: NotificationsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        title = "Bildirişlər"
        navigationController?.setNavigationBarHidden(false, animated: false)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = AppConstants.Colors.dashboardBackground
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
        navigationController?.navigationBar.tintColor = AppConstants.Colors.authTitle
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: AppConstants.Colors.authTitle,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        let backImage = UIImage(systemName: "chevron.left")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Mark all read", style: .plain, target: self, action: #selector(markAllTapped))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 15, weight: .medium)], for: .normal)
        setupUI()
        setupConstraints()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = AppConstants.Notifications.rowHeight
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
        tableView.refreshControl = refresh
        bind()
        Task { await viewModel.loadNotifications() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await viewModel.loadNotifications() }
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(activityIndicator)
    }

    private func setupConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func bind() {
        viewModel.$sections
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sections in
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateEmptyState()
            }
            .store(in: &cancellables)
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading { self?.activityIndicator.startAnimating() } else { self?.activityIndicator.stopAnimating() }
                self?.tableView.refreshControl?.endRefreshing()
            }
            .store(in: &cancellables)
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func markAllTapped() {
        Task { await viewModel.markAllAsRead() }
    }

    @objc private func refreshPulled() {
        Task { await viewModel.loadNotifications() }
    }

    private func updateEmptyState() {
        if let err = viewModel.errorMessage, !err.isEmpty {
            emptyLabel.text = err
            emptyLabel.textColor = .systemRed
            emptyLabel.isHidden = false
        } else if viewModel.sections.isEmpty {
            emptyLabel.text = "No notifications"
            emptyLabel.textColor = AppConstants.Colors.authSubtitle
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }
    }
}

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].notifications.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.reuseId, for: indexPath) as! NotificationCell
        let notification = viewModel.sections[indexPath.section].notifications[indexPath.row]
        cell.configure(with: notification)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let wrap = UIView()
        wrap.backgroundColor = AppConstants.Colors.dashboardBackground
        let label = UILabel()
        label.text = viewModel.sections[section].title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = AppConstants.Colors.authSubtitle
        wrap.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppConstants.Notifications.horizontalInset)
            make.centerY.equalToSuperview()
        }
        return wrap
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        40
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notification = viewModel.sections[indexPath.section].notifications[indexPath.row]
        Task { await viewModel.markAsRead(notification) }
        if notification.type == "transfer_request" || notification.type == "money_request" { 
            let requestId = notification.transactionId ?? notification.id
            coordinator?.showAcceptTransfer(requestId: requestId)
        }
    }
}
