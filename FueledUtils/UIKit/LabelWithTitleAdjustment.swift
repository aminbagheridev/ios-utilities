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

#if canImport(UIKit) && !os(watchOS)
import UIKit
import Foundation

///
/// A subclass of `UILabel` allowing to easily specify line spacing and kerning.
///
/// This class exposes properties allowing to customize the title in Interface Builder.
/// Internally, this class works by setting `attributedText`. **Do not use**
/// this class if you're using `attributedText` anywhere.
///
open class LabelWithTitleAdjustment: UILabel {
	///
	/// The line spacing to apply to the label's text.
	///
	/// Negative values are **unsupported**. Please refer to the documentation for `NSAttributedString.Key.lineSpacing` for more info.
	///
	@IBInspectable public var adjustmentLineSpacing: CGFloat = 0.0 {
		didSet {
			self.setAdjustedText(self.text)
		}
	}

	///
	/// The kern value to apply to the label's text.
	///
	/// Please refer to the documentation for `NSAttributedString.Key.kernValue` for info about the possible values.
	///
	@IBInspectable public var adjustmentKerning: CGFloat = 0.0 {
		didSet {
			self.setAdjustedText(self.text)
		}
	}

	///
	/// Please refer to the documentation for `UILabel.text`
	///
	override open var text: String? {
		get {
			return super.text
		}
		set {
			super.text = newValue
			self.setAdjustedText(newValue)
		}
	}

	///
	/// Please refer to the documentation for `UILabel.attributedText`
	///
	override open var attributedText: NSAttributedString? {
		get {
			return super.attributedText
		}
		set {
			super.attributedText = newValue
			self.setAdjustedAttributedText(newValue)
		}
	}

	///
	/// Please refer to the documentation for `UILabel.init(frame:)`
	///
	override public init(frame: CGRect) {
		super.init(frame: frame)
		self.setAdjustedText(self.text)
	}

	///
	/// Please refer to the documentation for `UILabel.init(coder:)`
	///
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.setAdjustedText(self.text)
	}

	private func setAdjustedAttributedText(_ text: NSAttributedString?) {
		guard let text = text else {
			super.attributedText = nil
			return
		}

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = self.lineBreakMode
		paragraphStyle.lineSpacing = self.adjustmentLineSpacing
		paragraphStyle.alignment = self.textAlignment
		let attributedString = NSMutableAttributedString(attributedString: text)
		attributedString.addAttributes(
			[
				NSAttributedString.Key.paragraphStyle: paragraphStyle,
				NSAttributedString.Key.kern: self.adjustmentKerning,
			],
			range: NSRange(location: 0, length: attributedString.string.utf16.count))
		super.attributedText = attributedString
	}

	private func setAdjustedText(_ text: String?) {
		self.setAdjustedAttributedText(text.map { NSAttributedString(string: $0) })
	}
}
#endif
