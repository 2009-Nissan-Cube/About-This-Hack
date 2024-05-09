//
//  InsertExtension.swift
//

import Darwin
import Foundation

var myself: String = "Extensions"

extension String {

	var length: Int {
		return count
	}

	subscript (i: Int) -> String {
		return self[i ..< i + 1]
	}

	func substring(fromIndex: Int) -> String {
		return self[min(fromIndex, length) ..< length]
	}

	func substring(toIndex: Int) -> String {
		return self[0 ..< max(0, toIndex)]
	}

	subscript (r: Range<Int>) -> String {
		let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
											upper: min(length, max(0, r.upperBound))))
		let start = index(startIndex, offsetBy: range.lowerBound)
		let end = index(start, offsetBy: range.upperBound - range.lowerBound)
		return String(self[start ..< end])
	}
	
    func inserting(separator: String, every n: Int) -> String {
        var result: String = ""
        let characters = Array(self)
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return result
    }

	func reverseString(separator: String, every n: Int, removeChars: String, hexencode: String) -> String {

		var outValue:  String = ""
		var workStr:   String = self
		let nbrSubStr = (workStr.count/n)

        if nbrSubStr > 1 {
			for _ in 0..<nbrSubStr  {
				if workStr.suffix(n) != removeChars {
					outValue += workStr.suffix(n)
				}
				workStr = String(workStr.dropLast(2))
			}
		}
		let intValue = outValue
		if hexencode.lowercased().starts(with: "y") {
			outValue = String(Int(outValue, radix: 16) ?? 0)
		}
//		print("\(myself) : From Hexa InVal : " + self + " by hexa invert. IntVal : \(intValue)  to Dec OutVal : \(outValue)")
		return ("\(outValue);\(intValue);\(self)")
	}

	var isNumber: Bool {
		return self.allSatisfy { character in
			character.isNumber
		}
	}
	
	func removedRegexMatches(pattern: String, replaceWith: String = "") -> String {
		do {
			let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
			let range = NSRange(location: 0, length: self.count)
			return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
		} catch {
			return self
		}
	}

}

extension Data {
	
	func hexadecimalString() -> String {
		self.reduce( "0x" ) {
			$0.appending( String( format: "%02X", $1  ) )
		}
	}
}
