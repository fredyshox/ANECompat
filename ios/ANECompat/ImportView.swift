//
//  ContentView.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 26/04/2022.
//

import SwiftUI

struct ImportView: View {
    struct HostInfoView: View {
        let model: String
        let cpu: String
        let memory: String
        let osVersion: String
        
        var body: some View {
            VStack {
                Text(model)
                    .font(.title)
                    .fontWeight(.bold)
                LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .trailing)]) {
                    Text("SoC:")
                    Text(cpu)
                        .fontWeight(.bold)
                    Text("RAM:")
                    Text(memory)
                        .fontWeight(.bold)
                    Text("iOS:")
                    Text(osVersion)
                        .fontWeight(.bold)
                }
            }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
        }
    }
    
    @ObservedObject var viewModel: ImportViewModel
    @State var documentPickerPresented: Bool = false
    @State var evaluationScreenPushed: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Text("""
                Check compatibility of CoreML model with Apple Neural Engine of current device (if present).

                Open mlmodel/mlpackage bundle to start.
                """)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
                .padding()
            Spacer()
            Button("Open model") {
                documentPickerPresented = true
            }
                .buttonStyle(BorderedProminentButtonStyle())
            Spacer()
            HostInfoView(
                model: viewModel.model,
                cpu: viewModel.cpu,
                memory: viewModel.memory,
                osVersion: viewModel.osVersion
            )
            NavigationLink(
                isActive: $evaluationScreenPushed,
                destination: {
                    if let url = viewModel.mlmodelUrl {
                        EvaluationView(viewModel: EvaluationViewModel(url: url))
                    } else {
                        EmptyView()
                    }
                },
                label: { EmptyView() }
            )
        }
            .navigationTitle("ANECompat")
            .onReceive(viewModel.$mlmodelUrl) { url in
                evaluationScreenPushed = url != nil
            }
            .sheet(isPresented: $documentPickerPresented) {
                ModelPicker(
                    onURL: { url in
                        viewModel.onOpenModel(with: url)
                    },
                    onDismiss: {}
                )
            }
            .onOpenURL { url in
                viewModel.onOpenModel(with: url)
            }
    }
}

struct ImportView_Previews: PreviewProvider {
    static var previews: some View {
        ImportView(viewModel: ImportViewModel())
    }
}
