import UIKit
import Combine

/// Centralized haptic feedback with reused generators.
/// Injected through the environment so views never construct generators ad hoc.
final class HapticService: ObservableObject {

    enum ImpactStrength {
        case light, medium, heavy
    }

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private var impactGenerators: [ImpactStrength: UIImpactFeedbackGenerator] = [:]
    private let notificationGenerator = UINotificationFeedbackGenerator()

    init() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        impactGenerators[.light] = UIImpactFeedbackGenerator(style: .light)
        impactGenerators[.medium] = UIImpactFeedbackGenerator(style: .medium)
        impactGenerators[.heavy] = UIImpactFeedbackGenerator(style: .heavy)
        impactGenerators.values.forEach { $0.prepare() }
    }

    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    func impact(_ strength: ImpactStrength) {
        guard let generator = impactGenerators[strength] else { return }
        generator.impactOccurred()
        generator.prepare()
    }

    func success() { notificationGenerator.notificationOccurred(.success); notificationGenerator.prepare() }
    func warning() { notificationGenerator.notificationOccurred(.warning); notificationGenerator.prepare() }
    func error() { notificationGenerator.notificationOccurred(.error); notificationGenerator.prepare() }
}
