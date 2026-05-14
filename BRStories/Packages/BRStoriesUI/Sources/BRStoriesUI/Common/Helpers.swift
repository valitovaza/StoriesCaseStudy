import SwiftUI

extension View {
    func _printSize() -> some View {
        modifier(SizeListenerViewModifier(onSize: { print($0) }))
    }
    
    func onSize(onSize: @escaping (CGSize) -> Void) -> some View {
        modifier(SizeListenerViewModifier(onSize: onSize))
    }
}

struct SizeListenerViewModifier: ViewModifier {
    @State private var uuid = UUID()
    let onSize: (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: ItemPositionsKey.self,
                        value: [ItemRec(uuid: uuid, p: proxy.frame(in: .global))]
                    )
                }
            )
            .onPreferenceChange(ItemPositionsKey.self) {
                if let ir = $0.filter({ $0.uuid == uuid }).first {
                    onSize(ir.p.size)
                }
            }
    }
}

struct ItemRec: Equatable {
    let uuid: UUID
    let p: CGRect
}

struct ItemPositionsKey: PreferenceKey {
    typealias Value = [ItemRec]
    static var defaultValue: Value { [] }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.append(contentsOf: nextValue())
    }
}
