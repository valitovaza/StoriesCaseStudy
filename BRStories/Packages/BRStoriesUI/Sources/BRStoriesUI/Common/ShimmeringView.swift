import SwiftUI

struct ShimmerConfiguration {
    let gradient: Gradient
    let initialLocation: (start: UnitPoint, end: UnitPoint)
    let finalLocation: (start: UnitPoint, end: UnitPoint)
    let duration: TimeInterval
    let opacity: Double
    static let `default` = ShimmerConfiguration(
        gradient: Gradient(stops: [
            .init(color: .black, location: 0),
            .init(color: .white, location: 0.3),
            .init(color: .white, location: 0.7),
            .init(color: .black, location: 1),
        ]),
        initialLocation: (start: UnitPoint(x: -1, y: -1), end: UnitPoint(x: 0, y: 0)),
        finalLocation: (start: UnitPoint(x: 1, y: 1), end: UnitPoint(x: 2, y: 2)),
        duration: 2,
        opacity: 1
    )
}

struct ShimmeringView<Content: View>: View {
    private let content: () -> Content
    private let configuration: ShimmerConfiguration
    @State private var startPoint: UnitPoint
    @State private var endPoint: UnitPoint
    init(configuration: ShimmerConfiguration, @ViewBuilder content: @escaping () -> Content) {
        self.configuration = configuration
        self.content = content
        _startPoint = .init(wrappedValue: configuration.initialLocation.start)
        _endPoint = .init(wrappedValue: configuration.initialLocation.end)
    }
    var body: some View {
        ZStack {
            content()
            
            LinearGradient(
                gradient: configuration.gradient,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .opacity(configuration.opacity)
            .blendMode(.screen)
            .onAppear {
                resetAnimation()
                Task { @MainActor in
                    await Task.yield()
                    startAnimation()
                }
            }
            .layoutPriority(-10)
        }
    }
    
    private func resetAnimation() {
        startPoint = configuration.initialLocation.start
        endPoint = configuration.initialLocation.end
    }
    
    private func startAnimation() {
        withAnimation(Animation.linear(duration: configuration.duration).repeatForever(autoreverses: false)) {
            startPoint = configuration.finalLocation.start
            endPoint = configuration.finalLocation.end
        }
    }
}

struct ShimmerModifier: ViewModifier {
    let configuration: ShimmerConfiguration
    func body(content: Content) -> some View {
        ShimmeringView(configuration: configuration) { content }
    }
}

extension View {
    func shimmer(configuration: ShimmerConfiguration = .default) -> some View {
        modifier(ShimmerModifier(configuration: configuration))
    }
    
    func shimmerOptionally(
        _ isShimmering: Bool,
        isRedacted: Bool,
        configuration: ShimmerConfiguration = .default
    ) -> some View {
        Group {
            if isShimmering {
                if isRedacted {
                    self.redacted(reason: .placeholder)
                        .shimmer(configuration: configuration)
                        .mask(
                            self.redacted(reason: .placeholder)
                        )
                } else {
                    self.shimmer(configuration: configuration)
                }
            } else {
                self
            }
        }
    }
}
