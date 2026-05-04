#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - GestureSimulator

/// Programmatic gesture dispatch for auto mode.
/// Fires simulated actions on the InteractionPlaygroundVC.
final class GestureSimulator {

    weak var targetVC: InteractionPlaygroundVC?

    init(targetVC: InteractionPlaygroundVC) {
        self.targetVC = targetVC
    }

    func simulateTapBurst(count: Int) {
        targetVC?.simulateTapBurst(count: count)
    }

    func simulateScrollDown() {
        targetVC?.simulateScrollDown()
    }

    func simulateScrollUp() {
        targetVC?.simulateScrollUp()
    }

    func simulateLongPress() {
        targetVC?.simulateLongPress()
    }

    func simulateSwipeLeft() {
        targetVC?.simulateSwipeLeft()
    }

    func simulateSwipeRight() {
        targetVC?.simulateSwipeRight()
    }
}

#endif