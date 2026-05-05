#if os(iOS)
import UIKit

// MARK: - S1: Basic Navigation Flow (Extended)
//
// Exercises every navigation action type across all 10 named screens:
//   push  → push one screen
//   popOne → pop just one level
//   popToRoot → unwind to Home
//   replaceStack → deep-link / state-restore simulation
//   presentModal (formSheet) + dismiss
//   presentFullScreen modal + dismiss

extension ScenarioLibrary {
    func s1() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S1",
            name: "UIKit Auto Navigation",
            steps: [

                // ── Open the playground ──────────────────────────────────────
                ScenarioStep(label: "Open Navigation Playground", action: {
                    nav?.openNavigationPlayground()
                }, delay: 1.0),

                // ── Screen 0 → Home ──────────────────────────────────────────
                // (root is already Home; just let RUM record the screen view)

                // ── push: Home → Dashboard ───────────────────────────────────
                ScenarioStep(label: "Push → Dashboard", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 1
                }, delay: 0.7),

                // ── push: Dashboard → Profile ─────────────────────────────────
                ScenarioStep(label: "Push → Profile", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 2
                }, delay: 0.7),

                // ── push: Profile → Settings ──────────────────────────────────
                ScenarioStep(label: "Push → Settings", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 3
                }, delay: 0.7),

                // ── popOne: Settings → Profile ────────────────────────────────
                ScenarioStep(label: "Pop ← Back to Profile", action: {
                    nav?.navigationPlaygroundVC?.popOne()
                }, delay: 0.7),

                // ── push: Profile → Order Details ─────────────────────────────
                ScenarioStep(label: "Push → Order Details", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 3 again → 4
                }, delay: 0.7),

                // ── push: Order Details → Checkout ───────────────────────────
                ScenarioStep(label: "Push → Checkout", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 5
                }, delay: 0.8),

                // ── push: Checkout → Payment ──────────────────────────────────
                ScenarioStep(label: "Push → Payment", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 6
                }, delay: 0.8),

                // ── Present modal (formSheet) on Payment ──────────────────────
                ScenarioStep(label: "Present Modal (formSheet) on Payment", action: {
                    nav?.navigationPlaygroundVC?.presentModal()
                }, delay: 1.2),

                // ── Dismiss formSheet modal ───────────────────────────────────
                ScenarioStep(label: "Dismiss Modal", action: {
                    nav?.navigationPlaygroundVC?.dismissModal()
                }, delay: 0.8),

                // ── push: Payment → Confirmation ──────────────────────────────
                ScenarioStep(label: "Push → Confirmation", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 7
                }, delay: 0.8),

                // ── Present full-screen modal on Confirmation ─────────────────
                ScenarioStep(label: "Present Full Screen Modal on Confirmation", action: {
                    nav?.navigationPlaygroundVC?.presentFullScreen()
                }, delay: 1.2),

                // ── Dismiss full-screen modal ─────────────────────────────────
                ScenarioStep(label: "Dismiss Full Screen Modal", action: {
                    nav?.navigationPlaygroundVC?.dismissModal()
                }, delay: 0.8),

                // ── push: Confirmation → Review ───────────────────────────────
                ScenarioStep(label: "Push → Review", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 8
                }, delay: 0.7),

                // ── push: Review → Done ───────────────────────────────────────
                ScenarioStep(label: "Push → Done", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()         // level 9
                }, delay: 0.7),

                // ── popToRoot from Done ───────────────────────────────────────
                ScenarioStep(label: "Pop ← Root (Home)", action: {
                    nav?.navigationPlaygroundVC?.popToRoot()
                }, delay: 1.0),

                // ── replaceStack: simulate deep-link to Order Details ─────────
                ScenarioStep(label: "Replace Stack → [Home, Order Details]", action: {
                    nav?.navigationPlaygroundVC?.replaceStack()
                }, delay: 1.0),

                // ── Pop one from Order Details → Home ─────────────────────────
                ScenarioStep(label: "Pop ← Back to Home", action: {
                    nav?.navigationPlaygroundVC?.popOne()
                }, delay: 0.8),

            ],
            loop: false
        )
    }
}

#endif