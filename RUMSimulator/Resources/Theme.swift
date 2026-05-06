#if os(iOS)
import UIKit

struct Theme {
    
    // MARK: - Colors
    
    struct Colors {
        static let backgroundStart = UIColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 1.0)
        static let backgroundEnd = UIColor(red: 0.12, green: 0.15, blue: 0.25, alpha: 1.0)
        
        static let primary = UIColor(red: 0.35, green: 0.55, blue: 1.0, alpha: 1.0)
        static let secondary = UIColor(red: 0.65, green: 0.35, blue: 1.0, alpha: 1.0)
        static let success = UIColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 1.0)
        static let warning = UIColor(red: 1.0, green: 0.65, blue: 0.25, alpha: 1.0)
        static let danger = UIColor(red: 1.0, green: 0.35, blue: 0.45, alpha: 1.0)
    }
    
    // MARK: - Utilities
    
    static func applyGlassEffect(to view: UIView, cornerRadius: CGFloat = 20) {
        view.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        
        let blur = UIBlurEffect(style: .systemThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurView, at: 0)
    }
    
    static func addGradientBackground(to view: UIView) {
        let gradient = CAGradientLayer()
        gradient.colors = [Colors.backgroundStart.cgColor, Colors.backgroundEnd.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        
        // Remove existing gradients if any
        view.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
        
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    static func premiumButtonConfig(title: String, systemImage: String, color: UIColor = Colors.primary) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePlacement = .leading
        config.imagePadding = 8
        config.cornerStyle = .large
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        
        return config
    }
    
    static func applyPremiumShadow(to button: UIButton, color: UIColor) {
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 8
        button.layer.masksToBounds = false
    }
}

#endif
