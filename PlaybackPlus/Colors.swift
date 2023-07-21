//
//  Colors.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/20/23.
//

import Foundation

import SwiftUI

extension Color {
    static func fromHex(_ hex: String) -> Color {
        let scanner = Scanner(string: hex)
        scanner.scanString("#", into: nil)
        
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}
