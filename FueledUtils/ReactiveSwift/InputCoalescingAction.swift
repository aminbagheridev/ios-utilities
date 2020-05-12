// Copyright © 2020, Fueled Digital Media, LLC
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

import ReactiveSwift

///
/// Similar to `Action`, except if the action is already executing, subsequent `apply()` call will not fail,
/// and will be completed with the same output when the initial executing action completes.
/// Disposing any of the `SignalProducer` returned by 'apply()` will cancel the action.
///
/// The `Input` is used when sending inputs to the **initial** `apply()` call - for subsequent
/// calls to `apply()` when the action is executing, the inputs will be ignored until
/// the action terminates.
///
public class ReactiveCoalescingAction<Input, Output, Error: Swift.Error>: ReactiveActionProtocol {
	private let action: ReactiveSwift.Action<Input, Output, Error>
	private var observer: Signal<Output, Error>.Observer?

	private class DisposableContainer {
		private let disposable: Disposable
		private let count = AtomicValue(0)

		init(_ disposable: Disposable) {
			self.disposable = disposable
		}

		func add(_ lifetime: Lifetime) {
			self.count.modify { $0 += 1 }
			lifetime.observeEnded {
				self.count.modify {
					$0 -= 1
					if $0 == 0 {
						self.disposable.dispose()
					}
				}
			}
		}
	}
	private var disposableContainer: DisposableContainer?

	///
	/// Whether the action is currently executing.
	///
	public var isExecuting: Property<Bool> {
		return self.action.isExecuting
	}

	///
	/// Whether the action is currently executing.
	///
	public let isEnabled = Property<Bool>(value: true)

	///
	/// A signal of all events generated from all units of work of the `Action`.
	///
	/// In other words, this sends every `Event` from every unit of work that the `Action`
	/// executes.
	///
	public var events: Signal<Signal<Output, Error>.Event, Never> {
		return self.action.events
	}

	///
	/// A signal of all values generated from all units of work of the `Action`.
	///
	/// In other words, this sends every value from every unit of work that the `Action`
	/// executes.
	///
	public var values: Signal<Output, Never> {
		return self.action.values
	}

	///
	/// A signal of all errors generated from all units of work of the `Action`.
	///
	/// In other words, this sends every error from every unit of work that the `Action`
	/// executes.
	///
	public var errors: Signal<Error, Never> {
		return self.action.errors
	}

	///
	/// The lifetime of the `Action`.
	///
	public var lifetime: Lifetime {
		return self.action.lifetime
	}

	///
	/// Initializes a `CoalescingAction`.
	///
	/// When the `Action` is asked to start the execution with an input value, a unit of
	/// work — represented by a `SignalProducer` — would be created by invoking
	/// `execute` with the input value.
	///
	/// - parameters:
	///   - execute: A closure that produces a unit of work, as `SignalProducer`, to be
	///              executed by the `Action`.
	///
	public init(execute: @escaping (Input) -> SignalProducer<Output, Error>) {
		self.action = ReactiveSwift.Action(execute: execute)
	}

	///
	/// Create a `SignalProducer` that would attempt to create and start a unit of work of
	/// the `Action`. The `SignalProducer` would forward only events generated by the unit
	/// of work it created.
	///
	/// - Warning: Only the first call to `apply()` when the action's `isExecuting`'s `value` is `false` will be using its parameters.
	///   Subsequent calls when the action is already executing will ignore the input.
	///
	/// - Parameters:
	///   - input: The initial input to use for the action.
	///
	/// - Returns: A producer that forwards events generated by its started unit of work. If the action was already executing, it will create a `SignalProducer`
	///   that will forward the events of the initially created `SignalProducer`.
	///
	public func apply(_ input: Input) -> SignalProducer<Output, Error> {
		if self.isExecuting.value {
			return SignalProducer { [disposableContainer, weak self] observer, lifetime in
				disposableContainer?.add(lifetime)
				lifetime += self?.action.events.observeValues { event in
					observer.send(event)
				}
			}
		}

		return SignalProducer<Output, Error> { observer, lifetime in
			self.observer = observer
			let disposable = self.action.apply(input).flatMapError { error in
				guard case .producerFailed(let innerError) = error else {
					return SignalProducer.empty
				}

				return SignalProducer(error: innerError)
			}.start(observer)
			let disposableContainer = DisposableContainer(disposable)
			disposableContainer.add(lifetime)
			self.disposableContainer = disposableContainer
		}
	}
}
