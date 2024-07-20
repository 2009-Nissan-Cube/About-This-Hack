//
//  InsertExtension.swift
//

import Foundation

extension String {
    subscript(i: Int) -> String {
        String(self[index(startIndex, offsetBy: i)])
    }

    subscript(r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, r.lowerBound))
        let end = index(startIndex, offsetBy: min(count, r.upperBound))
        return String(self[start..<end])
    }
    
    func inserting(separator: String, every n: Int) -> String {
        stride(from: 0, to: count, by: n).map {
            String(self[$0..<min($0+n, count)])
        }.joined(separator: separator)
    }

    func reverseString(separator: String, every n: Int, removeChars: String, hexencode: String) -> String {
        let reversedChunks = stride(from: count-n, through: 0, by: -n).compactMap { startIndex -> String? in
            let chunk = self[startIndex..<min(startIndex+n, count)]
            return chunk != removeChars ? String(chunk) : nil
        }
        
        let intValue = reversedChunks.joined()
        let outValue = hexencode.lowercased().starts(with: "y") ? String(Int(intValue, radix: 16) ?? 0) : intValue
        
        return "\(outValue);\(intValue);\(self)"
    }

    var isNumber: Bool {
        allSatisfy { $0.isNumber }
    }
    
    func removedRegexMatches(pattern: String, replaceWith: String = "") -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return self }
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: count), withTemplate: replaceWith)
    }
}

extension Data {
    func hexadecimalString() -> String {
        "0x" + map { String(format: "%02X", $0) }.joined()
    }
}
