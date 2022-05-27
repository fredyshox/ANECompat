//
//  ModelPicker.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 26/05/2022.
//

import SwiftUI
import UniformTypeIdentifiers

struct ModelPicker: UIViewControllerRepresentable {

    private let onURL: (URL) -> Void
    private let onDismiss: () -> Void

    init(onURL: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onURL = onURL
        self.onDismiss = onDismiss
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onURL: onURL, onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // mlmodelc cannot be picked
        let controller = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                UTType("com.apple.coreml.mlpackage")!,
                UTType("com.apple.coreml.model")!
            ]
        )
        controller.allowsMultipleSelection = false
        controller.shouldShowFileExtensions = true
        controller.delegate = context.coordinator
        return controller
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onURL: (URL) -> Void
        private let onDismiss: () -> Void
        
        init(onURL: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
            self.onURL = onURL
            self.onDismiss = onDismiss
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            defer { onDismiss() }
            guard let url = urls.first else {
                return
            }
            
            onURL(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onDismiss()
        }
    }
}
