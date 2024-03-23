//
//  NSTextCheckingResult+groups.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//

import Foundation

extension NSTextCheckingResult {
    func groups(testedString:String) -> [String] {
        var groups = [String]()
        for i in  0 ..< self.numberOfRanges
        {
            let group = String(testedString[Range(self.range(at: i), in: testedString)!])
            groups.append(group)
        }
        return groups
    }
}
