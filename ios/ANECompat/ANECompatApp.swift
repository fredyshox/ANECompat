//
//  ANECompatApp.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 26/04/2022.
//

import SwiftUI

@main
struct ANECompatApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ImportView(viewModel: ImportViewModel())
            }
        }
    }
}
