//
//  ImportViewModel.swift
//  ANECompat4iOS
//
//  Created by Kacper Rączy on 26/04/2022.
//

import Foundation
import UIKit

final class ImportViewModel: ObservableObject {
    
    @Published var cpu: String
    @Published var model: String
    @Published var memory: String
    @Published var osVersion: String
    @Published var mlmodelUrl: URL?
    
    init() {
        let memoryInBytes = ProcessInfo.processInfo.physicalMemory
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = .useMB
        memory = byteFormatter.string(fromByteCount: Int64(memoryInBytes))
        
        let version = ProcessInfo.processInfo.operatingSystemVersion
        osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String(validatingUTF8: ptr)

            }
        }
        model = modelCode ?? UIDevice.current.model
        
        var cpuNameLength: Int = 0
        var cpuName: String
        if sysctlbyname("machdep.cpu.brand_string", nil, &cpuNameLength, nil, 0) != 0 {
            cpu = "<unknown>"
            return
        }
        
        cpuName = String(repeating: "\0", count: cpuNameLength)
        if sysctlbyname("machdep.cpu.brand_string", &cpuName, &cpuNameLength, nil, 0) != 0 {
            cpu = "<unknown>"
            return
        }
        cpu = cpuName
    }
    
    func onOpenModel(with url: URL) {
        mlmodelUrl = url
    }
}
