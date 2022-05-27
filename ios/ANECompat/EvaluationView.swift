//
//  EvaluationView.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 27/05/2022.
//

import SwiftUI

struct EvaluationView: View {
    struct CompatibilityHeaderView: View {
        let status: StatusModel
        
        var body: some View {
            VStack(spacing: 16.0) {
                Image(systemName: status.systemImageName)
                    .font(.largeTitle)
                Text(status.title)
                    .font(.title2)
                    .bold()
            }
                .padding(.vertical, 32.0)
                .padding(.horizontal, 16.0)
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .background(RoundedRectangle(cornerRadius: 8.0).fill(status.color))
        }
    }
    
    struct SectionTitle: View {
        let text: String
        
        var body: some View {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    @ObservedObject var viewModel: EvaluationViewModel
    
    var body: some View {
        Group {
            if let status = viewModel.status {
                VStack(spacing: 24.0) {
                    VStack(spacing: 8.0) {
                        SectionTitle(text: "ANE Compatibility status:")
                        CompatibilityHeaderView(status: status)
                    }
                        .padding(.top, 12.0)
                    Divider()
                    VStack(spacing: 8.0) {
                        SectionTitle(text: "Captured output:")
                        ScrollView {
                            Text(viewModel.textOutput ?? "")
                                .font(.terminalFont(size: 15.0))
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .textSelection(.enabled)
                        }
                    }
                }
                    .padding(.horizontal, 10.0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView("Evaluating model...")
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(viewModel.title)
            .onAppear {
                viewModel.onAppear()
            }
    }
}

extension Font {
    static func terminalFont(size: CGFloat) -> Font {
        let font = UIFont(name: "Menlo", size: size)!
        return Font(font)
    }
}
