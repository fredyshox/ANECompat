//
//  EvaluationViewModel.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 27/05/2022.
//

import Foundation

final class EvaluationViewModel: ObservableObject {
    @Published var title: String
    @Published var status: StatusModel?
    @Published var textOutput: String?
    
    private let url: URL
    
    init(url: URL) {
        self.url = url
        self.title = url.lastPathComponent
    }
    
    func onAppear() {
        DispatchQueue.global(qos: .background).async { [weak self, url] in
            _ = url.startAccessingSecurityScopedResource()
            
            let (aneStatus, stdErrOutput) = performWithStdErrRedirection { () -> ANECompatStatus in
                let evaluator = ANECompatEvaluator()
                let aneStatus = evaluator.evaluateModel(at: url)
                return aneStatus
            }
            
            DispatchQueue.main.async {
                self?.status = StatusModel(status: aneStatus, title: ANECompatStatusDescription(aneStatus))
                self?.textOutput = stdErrOutput
                #if DEBUG
                print(stdErrOutput ?? "")
                #endif
            }
            url.stopAccessingSecurityScopedResource()
        }
    }
}

private func performWithStdErrRedirection<T>(_ block: () -> T) -> (T, String?) {
    let result: T
    var pipes: [Int32] = [0, 0]
    let stdErrCopyDesc = dup(STDERR_FILENO)
    
    // create pipes and redirect stderr to write pipe end
    pipe(&pipes)
    dup2(pipes[1], STDERR_FILENO)
    
    result = block()
    
    // close writable pipe end and defer closing readable one
    close(pipes[1])
    defer { close(pipes[0]) }
    
    // revert stderr back to original
    dup2(stdErrCopyDesc, STDERR_FILENO)
    close(stdErrCopyDesc)
    
    let fileHandle = FileHandle(fileDescriptor: pipes[0])
    guard let outputData = try? fileHandle.readToEnd() else {
        return (result, nil)
    }
    
    return (result, String(data: outputData, encoding: .utf8))
}
