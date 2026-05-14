import SwiftUI

enum RemoteValue<Value> {
    case loaded(Value)
    case loading
    case failure(String?)
    
    enum Error: Swift.Error {
        case loading
        case failure(String?)
    }
    
    @inlinable func get() throws -> Value {
        switch self {
            case .loaded(let value):
                return value
            case .loading:
                throw Error.loading
            case .failure(let string):
                throw Error.failure(string)
        }
    }
    
    @inlinable var failureString: String? {
        if case .failure(let string) = self {
            return string
        }
        return nil
    }
    
    @inlinable static var failure: Self {
        .failure(nil)
    }
}

extension RemoteValue: Equatable where Value: Equatable {
    static func == (lhs: RemoteValue, rhs: RemoteValue) -> Bool {
        switch (lhs, rhs) {
            case let (.loaded(lhsValue), .loaded(rhsValue)): return lhsValue == rhsValue
            case (.loading, .loading): return true
            case let (.failure(lhsError), .failure(rhsError)): return lhsError == rhsError
            default: return false
        }
    }
}

extension RemoteValue {
    @discardableResult
    mutating func changeOptionally<Field>(field: Field, keyPath: WritableKeyPath<Value, Field>) -> Bool {
        guard var value = try? get() else { return false }
        
        value[keyPath: keyPath] = field
        self = .loaded(value)
        return true
    }
}

extension RemoteValue {
    func map<T>(_ transform: (Value) throws -> T) rethrows -> RemoteValue<T> {
        switch self {
            case .loaded(let value):
                return .loaded(try transform(value))
            case .loading:
                return .loading
            case .failure(let string):
                return .failure(string)
        }
    }
}

struct LoaderView<Value, Content: View, Placeholder: View, Failure: View>: View {
    enum ViewToPresent {
        case content(Content)
        case loading(Placeholder)
        case failure(Failure)
    }
    
    private let viewToPresent: ViewToPresent
    
    init(
        _ remoteValue: RemoteValue<Value>,
        @ViewBuilder content: (Value) -> Content,
        @ViewBuilder placeholder: () -> Placeholder,
        @ViewBuilder failureView: (String?) -> Failure
    ) {
        switch remoteValue {
            case let .loaded(value):
                viewToPresent = .content(content(value))
                
            case .loading:
                viewToPresent = .loading(placeholder())
                
            case let .failure(string):
                viewToPresent = .failure(failureView(string))
        }
    }
    
    init(
        _ remoteValue: RemoteValue<Value>,
        @ViewBuilder content: (Value) -> Content,
        @ViewBuilder placeholderAndFailure: () -> Failure
    ) where Placeholder == Failure {
        switch remoteValue {
            case let .loaded(value):
                viewToPresent = .content(content(value))
                
            case .loading:
                viewToPresent = .loading(placeholderAndFailure())
                
            case .failure:
                viewToPresent = .failure(placeholderAndFailure())
        }
    }
    
    init(
        _ remoteValue: RemoteValue<Value>,
        @ViewBuilder contentAndPlaceholder: (Value?) -> Content,
        @ViewBuilder failureView: (String?) -> Failure
    ) where Content == Placeholder {
        switch remoteValue {
            case let .loaded(value):
                viewToPresent = .content(contentAndPlaceholder(value))
                
            case .loading:
                viewToPresent = .loading(contentAndPlaceholder(nil))
                
            case let .failure(string):
                viewToPresent = .failure(failureView(string))
        }
    }
    
    init(
        _ remoteValue: RemoteValue<Value>,
        @ViewBuilder content: (Value?) -> Content
    ) where Content == Failure, Content == Placeholder {
        switch remoteValue {
            case let .loaded(value):
                viewToPresent = .content(content(value))
                
            case .loading:
                viewToPresent = .loading(content(nil))
                
            case .failure:
                viewToPresent = .failure(content(nil))
        }
    }
    
    var body: some View {
        ZStack {
            switch viewToPresent {
                case let .content(content):
                    content
                    
                case let .loading(content):
                    content
                        .redacted(reason: .placeholder)
                        .shimmer()
                        .mask(
                            content
                                .redacted(reason: .placeholder)
                        )
                    
                case let .failure(failure):
                    failure
            }
        }
    }
}
