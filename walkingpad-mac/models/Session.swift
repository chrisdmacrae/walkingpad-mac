//
//  Session.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-24.
//

import Foundation
import SwiftData

@Model
class Session {
    var date = Date.now
    var steps: Int = 0
    var distance: Double = 0
    var time: Double = 0
    
    init() {}
    
    static func todayPredicate() -> Predicate<Session> {
        let currentDate = Date.now
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
            fatalError("Unable to calculate yesterday's date")
        }
        
        return #Predicate<Session> { session in
            return session.date < currentDate && session.date > yesterday
        }
    }
}
