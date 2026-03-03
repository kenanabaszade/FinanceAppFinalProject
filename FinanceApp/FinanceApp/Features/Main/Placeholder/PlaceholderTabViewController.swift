import UIKit
import SnapKit

final class PlaceholderTabViewController: UIViewController {

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .medium)
        l.textColor = AppConstants.Colors.authSubtitle
        l.textAlignment = .center
        return l
    }()

    init(title: String, tabTitle: String, imageName: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = tabTitle
        label.text = title
        tabBarItem = UITabBarItem(title: tabTitle, image: UIImage(systemName: imageName), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.Colors.dashboardBackground
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
