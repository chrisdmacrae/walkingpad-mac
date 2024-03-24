//
//  Constants.swift
//  walkingpad-mac
//
//  Created by Chris D. MacRae on 2024-03-23.
//
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleTreadmill = Self("toggleTreadmill", default: .init(.return, modifiers: [.command, .option]))
    static let decreaseSpeed = Self("decreaseSpeed", default: .init(.leftArrow, modifiers: [.command, .option]))
    static let increaseSpeed = Self("increaseSpeed", default: .init(.rightArrow, modifiers: [.command, .option]))

}
