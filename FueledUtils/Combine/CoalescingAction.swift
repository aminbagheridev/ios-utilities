// Copyright © 2020 Fueled Digital Media, LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Combine

///
/// Similar to `Action`, except if the action is already executing, subsequent `apply()` call will not fail,
/// and will be completed with the same output when the initial executing action completes.
/// Disposing any of the `AnyPublisher` returned by `apply()` will cancel the action.
///
/// The `Input` is used when sending inputs to the **initial** `apply()` call - for subsequent
/// calls to `apply()` when the action is executing, the inputs will be ignored until
/// the action terminates.
///
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public class CoalescingAction<Input, Output, Failure: Swift.Error>: ActionProtocol {
	public typealias ApplyFailure = Failure

	private let action: Action<Input, Output, Failure>
	private var passthroughSubject: PassthroughSubject<Output, Failure>?
	private var cancellableContainer: CancellableContainer?

	private class CancellableContainer {
		private let cancellable: AnyCancellable
		private let count = AtomicValue(0)

		init(_ cancellable: AnyCancellable) {
			self.cancellable = cancellable
		}

		func add(_ passthroughSubject: PassthroughSubject<Output, Failure>) -> ((Bool) -> Void) -> Void {
			self.count.modify { $0 += 1 }
			return { isFinal in
				let isCancelled = self.count.modify { count -> Bool in
					count -= 1
					let isCancelled = count == 0
					if isCancelled {
						self.cancellable.cancel()
					}
					return isCancelled
				}
				isFinal(isCancelled)
			}
		}
	}

	@Published public private(set) var isExecuting: Bool
	@Published public private(set) var isEnabled: Bool

	public var isExecutingPublisher: AnyPublisher<Bool, Never> {
		self.$isExecuting.eraseToAnyPublisher()
	}

	public var isEnabledPublisher: AnyPublisher<Bool, Never> {
		self.$isEnabled.eraseToAnyPublisher()
	}

	public var values: AnyPublisher<Output, Never> {
		self.action.values
	}

	public var errors: AnyPublisher<Failure, Never> {
		self.action.errors
	}

	private var cancellables = Set<AnyCancellable>([])

	///
	/// Initializes a `CoalescingAction`.
	///
	/// When the `Action` is asked to start the execution with an input value, a unit of
	/// work — represented by a `Publisher` — would be created by invoking
	/// `execute` with the input value.
	///
	/// - parameters:
	///   - execute: A closure that produces a unit of work, as `Publisher`, to be
	///              executed by the `Action`.
	///
	public init<ExecutePublisher: Combine.Publisher>(
		execute: @escaping (Input) -> ExecutePublisher
	) where ExecutePublisher.Output == Output, ExecutePublisher.Failure == Failure {
		self.action = Action(execute: execute)
		self.isEnabled = self.action.isEnabled
		self.isExecuting = self.action.isExecuting
		self.action.isEnabledPublisher.assign(to: \.isEnabled, withoutRetaining: self)
			.store(in: &self.cancellables)
		self.action.isExecutingPublisher.assign(to: \.isExecuting, withoutRetaining: self)
			.store(in: &self.cancellables)
	}

	///
	/// Create a `AnyPublisher` that would attempt to create and start a unit of work of
	/// the `Action`. The `AnyPublisher` would forward only events generated by the unit
	/// of work it created.
	///
	/// - Warning: Only the first call to `apply()` when the action's `isExecuting`'s `value` is `false` will be using its parameters.
	///   Subsequent calls when the action is already executing will ignore the input.
	///
	/// - Parameters:
	///   - input: The initial input to use for the action.
	///
	/// - Returns: A publisher that forwards events generated by its started unit of work. If the action was already executing, it will create a `AnyPublisher`
	///   that will forward the events of the initially created `AnyPublisher`.
	///
	public func apply(_ input: Input) -> AnyPublisher<Output, Failure> {
		let passthroughSubject = PassthroughSubject<Output, Failure>()
		var cancellable: AnyCancellable!
		let cancellableContainer: CancellableContainer
		let originalPassthroughSubject: PassthroughSubject<Output, Failure>
		if let existingPassthroughSubject = self.passthroughSubject {
			assert(self.isExecuting, "Action must be executing when `passthroughSubject` is non-nil")
			originalPassthroughSubject = existingPassthroughSubject
			cancellableContainer = self.cancellableContainer!
		} else {
			originalPassthroughSubject = PassthroughSubject<Output, Failure>()
			self.passthroughSubject = originalPassthroughSubject
			cancellable = self.action.apply(input)
				.unwrappingActionError()
				.subscribe(originalPassthroughSubject)
			cancellableContainer = CancellableContainer(cancellable)
			self.cancellableContainer = cancellableContainer
		}
		cancellable = originalPassthroughSubject.subscribe(passthroughSubject)
		let onCompletion = cancellableContainer.add(passthroughSubject)
		return passthroughSubject
			.handleEvents(
				receiveTermination: { [weak self] in
					onCompletion() { isCancelled in
						if isCancelled {
							self?.passthroughSubject = nil
							self?.cancellableContainer = nil
						}
					}
					cancellable = nil
				}
			)
			.eraseToAnyPublisher()
	}
}
