import UIKit
import SnapKit

struct StoryItem {
    let title: String
    let subtitle: String
    let gradientColors: [UIColor]
}

class StoriesView: UIView {
    
    private var stories: [StoryItem] = []
    private var currentStoryIndex: Int = 0
    private var progressTimer: Timer?
    private var storyDuration: TimeInterval = 4.0
    
    private let progressStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private var progressBars: [UIView] = []
    private var progressViews: [UIView] = []
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        return layer
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.textColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStories()
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
     
    private func setupStories() {
        stories = [
            StoryItem(
                title: "Welcome to\nFinanceApp",
                subtitle: "Manage your finances smarter",
                gradientColors: [
                    UIColor(red: 0.35, green: 0.20, blue: 0.85, alpha: 1.0),
                    UIColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 1.0),
                    UIColor(red: 0.15, green: 0.60, blue: 1.0, alpha: 1.0)
                ]
            ),
            StoryItem(
                title: "Track Your\nSpending",
                subtitle: "See where your money goes",
                gradientColors: [
                    UIColor(red: 0.95, green: 0.30, blue: 0.50, alpha: 1.0),
                    UIColor(red: 0.85, green: 0.20, blue: 0.70, alpha: 1.0),
                    UIColor(red: 0.75, green: 0.15, blue: 0.85, alpha: 1.0)
                ]
            ),
            StoryItem(
                title: "Save Money\nEasily",
                subtitle: "Set goals and achieve them",
                gradientColors: [
                    UIColor(red: 0.20, green: 0.80, blue: 0.50, alpha: 1.0),
                    UIColor(red: 0.15, green: 0.70, blue: 0.60, alpha: 1.0),
                    UIColor(red: 0.10, green: 0.60, blue: 0.70, alpha: 1.0)
                ]
            ),
            StoryItem(
                title: "Secure & Safe",
                subtitle: "Your data is protected",
                gradientColors: [
                    UIColor(red: 0.90, green: 0.60, blue: 0.20, alpha: 1.0),
                    UIColor(red: 0.85, green: 0.50, blue: 0.30, alpha: 1.0),
                    UIColor(red: 0.80, green: 0.40, blue: 0.40, alpha: 1.0)
                ]
            )
        ]
    }
    
    private func setupUI() {
        addSubview(backgroundImageView)
        layer.insertSublayer(gradientLayer, at: 0)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(progressStackView)
        
        setupProgressBars()
        
        progressStackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(3)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupGestures()
        
        loadStory(at: 0)
    }
    
    private func setupProgressBars() {
        progressBars.removeAll()
        progressViews.removeAll()
        progressStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for _ in 0..<stories.count {
            let containerView = UIView()
            containerView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            containerView.layer.cornerRadius = 1.5
            containerView.clipsToBounds = true
            
            let progressView = UIView()
            progressView.backgroundColor = UIColor.white
            progressView.frame = CGRect(x: 0, y: 0, width: 0, height: 3)
            containerView.addSubview(progressView)
            
            progressBars.append(containerView)
            progressViews.append(progressView)
            progressStackView.addArrangedSubview(containerView)
        }
    }
    
    private func setupGestures() {
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        leftSwipe.direction = .left
        addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rightSwipe.direction = .right
        addGestureRecognizer(rightSwipe)
        
        isUserInteractionEnabled = true
    }
    
    func startStories() {
        loadStory(at: 0)
        startProgressAnimation()
    }
    
    func pauseStories() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func resumeStories() {
        startProgressAnimation()
    }
    
    private func loadStory(at index: Int) {
        guard index >= 0 && index < stories.count else { return }
        
        currentStoryIndex = index
        let story = stories[index]
        
        UIView.transition(with: titleLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.titleLabel.text = story.title
        }
        
        UIView.transition(with: subtitleLabel, duration: 0.3, options: .transitionCrossDissolve) {
            self.subtitleLabel.text = story.subtitle
        }
        
        gradientLayer.colors = story.gradientColors.map { $0.cgColor }
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
         
        resetProgressBars()
    }
    
    private func nextStory() {
        let nextIndex = (currentStoryIndex + 1) % stories.count
        loadStory(at: nextIndex)
        startProgressAnimation()
    }
    
    private func previousStory() {
        let prevIndex = (currentStoryIndex - 1 + stories.count) % stories.count
        loadStory(at: prevIndex)
        startProgressAnimation()
    }
    
    private func startProgressAnimation() {
        progressTimer?.invalidate()
        
        let currentProgressView = progressViews[currentStoryIndex]
        currentProgressView.layer.removeAllAnimations()
        
        let containerView = progressBars[currentStoryIndex]
        let containerWidth = containerView.bounds.width > 0 ? containerView.bounds.width : (UIScreen.main.bounds.width - 32) / CGFloat(stories.count) - 4
        
        currentProgressView.frame = CGRect(x: 0, y: 0, width: 0, height: 3)
        
        UIView.animate(withDuration: storyDuration, delay: 0, options: [.curveLinear], animations: { [weak self] in
            guard let self = self else { return }
            self.progressViews[self.currentStoryIndex].frame = CGRect(x: 0, y: 0, width: containerWidth, height: 3)
        }, completion: nil)
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: storyDuration, repeats: false) { [weak self] _ in
            self?.nextStory()
        }
    }
     
    private func resetProgressBars() {
        for (index, progressView) in progressViews.enumerated() {
            let containerView = progressBars[index]
            let containerWidth = containerView.bounds.width > 0 ? containerView.bounds.width : (UIScreen.main.bounds.width - 32) / CGFloat(stories.count) - 4
            
            if index < currentStoryIndex {
                progressView.frame = CGRect(x: 0, y: 0, width: containerWidth, height: 3)
            } else if index == currentStoryIndex {
                progressView.frame = CGRect(x: 0, y: 0, width: 0, height: 3)
            } else {
                progressView.frame = CGRect(x: 0, y: 0, width: 0, height: 3)
            }
        }
    }
    
    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        progressTimer?.invalidate()
        progressTimer = nil
        
        if gesture.direction == .left {
            nextStory()
        } else if gesture.direction == .right {
            previousStory()
        }
    }
    
    deinit {
        progressTimer?.invalidate()
    }
}

