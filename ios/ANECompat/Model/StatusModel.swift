//
//  StatusModel.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 28/05/2022.
//

import Foundation
import SwiftUI

struct StatusModel {
    let status: ANECompatStatus
    let title: String
    
    var systemImageName: String {
        switch status {
        case .passed:
            return "checkmark.circle.fill"
        case .partial:
            return "minus.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        default:
            return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch status {
        case .passed:
            // #03BD5B
            return Color(red: 3.0/255.0, green: 189.0/255.0, blue: 91.0/255.0)
        case .partial:
            // #9DBF15
            return Color(red: 157.0/255.0, green: 191.0/255.0, blue: 21.0/255.0)
        case .failed:
            // #FF9947
            return Color(red: 255.0/255.0, green: 153.0/255.0, blue: 71.0/255.0)
        default:
            // #D1335B
            return Color(red: 209.0/255.0, green: 51.0/255.0, blue: 91.0/255.0)
        }
    }
}
