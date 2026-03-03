//
//  StoryItem.swift
//  FinanceApp
//
//  Created by Macbook on 06.02.26.
//

import UIKit

struct StoryItem {
    let title: String
    let subtitle: String
    let gradientColors: [UIColor]
}

extension StoryItem {
    static let defaultStories: [StoryItem] = [
        StoryItem(
            title: "Welcome to\nMandarin",
            subtitle: "Your smart finance companion",
            gradientColors: [
                UIColor(red: 0.96, green: 0.62, blue: 0.12, alpha: 1.0),
                UIColor(red: 0.85, green: 0.45, blue: 0.08, alpha: 1.0),
                UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
            ]
        ),
        StoryItem(
            title: "Track Every\nManat",
            subtitle: "Know exactly where your money goes",
            gradientColors: [
                UIColor(red: 0.98, green: 0.72, blue: 0.28, alpha: 1.0),
                UIColor(red: 0.90, green: 0.50, blue: 0.05, alpha: 1.0),
                UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1.0)
            ]
        ),
        StoryItem(
            title: "Budget\nSmarter",
            subtitle: "Set goals and watch your savings grow",
            gradientColors: [
                UIColor(red: 0.92, green: 0.55, blue: 0.10, alpha: 1.0),
                UIColor(red: 0.80, green: 0.38, blue: 0.05, alpha: 1.0),
                UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
            ]
        ),
        StoryItem(
            title: "Safe &\nSecure",
            subtitle: "Your financial data is always protected",
            gradientColors: [
                UIColor(red: 0.94, green: 0.58, blue: 0.15, alpha: 1.0),
                UIColor(red: 0.75, green: 0.35, blue: 0.05, alpha: 1.0),
                UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
            ]
        )
    ]
}
