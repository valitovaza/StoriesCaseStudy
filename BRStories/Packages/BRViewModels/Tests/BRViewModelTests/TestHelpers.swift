import XCTest

extension XCTestCase {
    @MainActor
    public func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}

extension Task where Success == Never, Failure == Never {
    public static func megaYield(count: Int = 20) async {
        for _ in 0..<count {
            await Task<Void, Never>.detached(priority: .background) {
                await Task.yield()
            }.value
        }
    }
}

@MainActor
public func withMainSerialExecutor(
    @_implicitSelfCapture operation: @MainActor @Sendable () async throws -> Void
) async rethrows {
    let didUseMainSerialExecutor = uncheckedUseMainSerialExecutor
    defer { uncheckedUseMainSerialExecutor = didUseMainSerialExecutor }
    uncheckedUseMainSerialExecutor = true
    try await operation()
}

public func withMainSerialExecutor(
    @_implicitSelfCapture operation: () throws -> Void
) rethrows {
    let didUseMainSerialExecutor = uncheckedUseMainSerialExecutor
    defer { uncheckedUseMainSerialExecutor = didUseMainSerialExecutor }
    uncheckedUseMainSerialExecutor = true
    try operation()
}

public var uncheckedUseMainSerialExecutor: Bool {
    get { swift_task_enqueueGlobal_hook != nil }
    set {
        swift_task_enqueueGlobal_hook =
        newValue
        ? { job, _ in MainActor.shared.enqueue(job) }
        : nil
    }
}

private typealias Original = @convention(thin) (UnownedJob) -> Void
private typealias Hook = @convention(thin) (UnownedJob, Original) -> Void

private var swift_task_enqueueGlobal_hook: Hook? {
    get { _swift_task_enqueueGlobal_hook.wrappedValue.pointee }
    set { _swift_task_enqueueGlobal_hook.wrappedValue.pointee = newValue }
}
private let _swift_task_enqueueGlobal_hook = UncheckedSendable(
dlsym(dlopen(nil, 0), "swift_task_enqueueGlobal_hook").assumingMemoryBound(to: Hook?.self)
)

@dynamicMemberLookup
@propertyWrapper
public struct UncheckedSendable<Value>: @unchecked Sendable {
  public var value: Value
    
  public init(_ value: Value) {
    self.value = value
  }

  public init(wrappedValue: Value) {
    self.value = wrappedValue
  }

  public var wrappedValue: Value {
    _read { yield self.value }
    _modify { yield &self.value }
  }

  public var projectedValue: Self {
    get { self }
    set { self = newValue }
  }

  public subscript<Subject>(dynamicMember keyPath: KeyPath<Value, Subject>) -> Subject {
    self.value[keyPath: keyPath]
  }

  public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Subject {
    _read { yield self.value[keyPath: keyPath] }
    _modify { yield &self.value[keyPath: keyPath] }
  }
}

extension UncheckedSendable: AsyncSequence where Value: AsyncSequence {
  public typealias AsyncIterator = Value.AsyncIterator
  public typealias Element = Value.Element

  public func makeAsyncIterator() -> AsyncIterator {
    value.makeAsyncIterator()
  }
}
