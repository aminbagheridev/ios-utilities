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

#if canImport(UIKit) && !os(watchOS) && canImport(Combine)
import Combine
#if canImport(FueledUtilsCombine)
import FueledUtilsCombine
#endif
#if canImport(FueledUtilsUIKit)
import FueledUtilsUIKit
#endif
import UIKit

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension CombineExtensions where Base: UITextInput, Base: ControlProtocol {
	public var textValues: AnyPublisher<String, Never> {
		self.textPublisherForControlEvents([.editingDidEnd, .editingDidEndOnExit])
	}

	public var continuousTextValues: AnyPublisher<String, Never> {
		self.textPublisherForControlEvents(.allEditingEvents)
	}

	private func textPublisherForControlEvents(_ controlEvents: UIControl.Event) -> AnyPublisher<String, Never> {
		self.base.publisherForControlEvents(controlEvents)
			.map { textInput in
				textInput.textRange(
					from: textInput.beginningOfDocument,
					to: textInput.endOfDocument
				)
					.flatMap { textInput.text(in: $0) }
					?? ""
			}
			.eraseToAnyPublisher()
	}
}

#endif
