//
//  StoriesView.swift
//  FinanceApp
//
//  Created by Macbook on 26.01.26.
//

import UIKit
import SnapKit
 
class StoriesView: UIView {

    private var stories: [StoryItem] = []
    private var currentStoryIndex: Int = 0
    private var storyDuration: TimeInterval
    private var progressTimer: Timer?
    private var progressStartTime: Date?
    private var progressElapsedWhenPaused: TimeInterval = 0
    
    private let progressStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private var progressBars: [UIView] = []
    private var progressViews: [UIView] = []
    
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
    
    init(frame: CGRect = .zero, stories: [StoryItem] =
        StoryItem.defaultStories,
        storyDuration: TimeInterval = AppConstants.Stories.storyDuration) {
        self.stories = stories
        self.storyDuration = storyDuration
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            reapplyCurrentGradient()
        }
    }

    private func reapplyCurrentGradient() {
        guard currentStoryIndex >= 0 && currentStoryIndex < stories.count else { return }
        let story = stories[currentStoryIndex]
        gradientLayer.colors = story.gradientColors.map {
            $0.resolvedColor(with: traitCollection).cgColor
        }
    }
    
    private func addSubViews() {
        layer.insertSublayer(gradientLayer, at: 0)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(progressStackView)
    }
    
    private func setupUI() {
        addSubViews()
        setupProgressBars()
        let inset = AppConstants.Stories.horizontalInset
        let contentInset = AppConstants.Stories.contentHorizontalInset
        let barHeight = AppConstants.Stories.progressBarHeight
        
        progressStackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(inset)
            make.leading.trailing.equalToSuperview().inset(inset)
            make.height.equalTo(barHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-40)
            make.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppConstants.Spacing.medium)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(contentInset)
        }
        
        loadStory(at: 0)
    }
    
    private func containerWidth(for index: Int) -> CGFloat {
        let containerView = progressBars.indices.contains(index) ? progressBars[index] : nil
        let fallback = (UIScreen.main.bounds.width - AppConstants.Stories.contentHorizontalInset * 2) / CGFloat(max(1, stories.count)) - 4
        guard let containerView = containerView, containerView.bounds.width > 0 else { return fallback }
        return containerView.bounds.width
    }
    
    private func setupProgressBars() {
        progressBars.removeAll()
        progressViews.removeAll()
        progressStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let barHeight = AppConstants.Stories.progressBarHeight
        for _ in 0..<stories.count {
            let containerView = UIView()
            containerView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            containerView.layer.cornerRadius = barHeight / 2
            containerView.clipsToBounds = true
            
            let progressView = UIView()
            progressView.backgroundColor = UIColor.white
            progressView.frame = CGRect(x: 0, y: 0, width: 0, height: barHeight)
            containerView.addSubview(progressView)
            
            progressBars.append(containerView)
            progressViews.append(progressView)
            progressStackView.addArrangedSubview(containerView)
        }
    }
    
    func startStories() {
        loadStory(at: 0)
        progressElapsedWhenPaused = 0
        startProgressAnimation()
    }
    
    func pauseStories() {
        progressTimer?.invalidate()
        progressTimer = nil
        if let start = progressStartTime {
            progressElapsedWhenPaused += Date().timeIntervalSince(start)
        }
        progressStartTime = nil
    }
    
    func resumeStories() {
        startProgressAnimation()
    }
    
    private func loadStory(at index: Int) {
        guard index >= 0 && index < stories.count else { return }
        currentStoryIndex = index
        let story = stories[index]
        UIView.transition(with: titleLabel, duration: AppConstants.Animation.mediumDuration, options: .transitionCrossDissolve) {
            self.titleLabel.text = story.title
        }
        UIView.transition(with: subtitleLabel, duration: AppConstants.Animation.mediumDuration, options: .transitionCrossDissolve) {
            self.subtitleLabel.text = story.subtitle
        }
        gradientLayer.colors = story.gradientColors.map { $0.cgColor }
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
         
        resetProgressBars()
    }
    
    private func advanceInLoop() {
        let barHeight = AppConstants.Stories.progressBarHeight
        let w = containerWidth(for: currentStoryIndex)
        progressViews[currentStoryIndex].frame = CGRect(x: 0, y: 0, width: w, height: barHeight)
        let nextIndex = (currentStoryIndex + 1) % stories.count
        loadStory(at: nextIndex)
        progressElapsedWhenPaused = 0
        startProgressAnimation()
    }
    
    private static let progressUpdateInterval: TimeInterval = 0.05
    
    private func startProgressAnimation() {
        progressTimer?.invalidate()
        let containerWidth = self.containerWidth(for: currentStoryIndex)
        let barHeight = AppConstants.Stories.progressBarHeight
        
        progressStartTime = Date().addingTimeInterval(-progressElapsedWhenPaused)
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: Self.progressUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(self.progressStartTime ?? Date())
            if elapsed >= self.storyDuration {
                self.progressTimer?.invalidate()
                self.progressTimer = nil
                self.progressStartTime = nil
                self.progressElapsedWhenPaused = 0
                let w = self.containerWidth(for: self.currentStoryIndex)
                self.progressViews[self.currentStoryIndex].frame = CGRect(x: 0, y: 0, width: w, height: barHeight)
                self.advanceInLoop()
                return
            }
            let progress = min(1, elapsed / self.storyDuration)
            let width = containerWidth * CGFloat(progress)
            self.progressViews[self.currentStoryIndex].frame = CGRect(x: 0, y: 0, width: width, height: barHeight)
        }
        RunLoop.main.add(progressTimer!, forMode: .common)
    }
    
    private func resetProgressBars() {
        let barHeight = AppConstants.Stories.progressBarHeight
        for (index, progressView) in progressViews.enumerated() {
            let w = containerWidth(for: index)
            let filled = index < currentStoryIndex
            progressView.frame = CGRect(x: 0, y: 0, width: filled ? w : 0, height: barHeight)
        }
    }

    deinit {
        progressTimer?.invalidate()
    }
}
