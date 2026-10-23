import Foundation

enum WineLauncher {
    static func launch(
        _ executableURL: URL,
        using wineURL: URL,
        prefixURL: URL,
        logName: String
    ) throws {
        guard FileManager.default.isExecutableFile(atPath: wineURL.path) else {
            throw LaunchError.invalidWineExecutable
        }

        guard FileManager.default.fileExists(atPath: executableURL.path) else {
            throw LaunchError.programFileMissing
        }

        let supportDirectory = try AppDirectories.supportDirectory()
        let logsDirectory = supportDirectory.appendingPathComponent("Logs", isDirectory: true)

        try FileManager.default.createDirectory(
            at: prefixURL,
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: logsDirectory,
            withIntermediateDirectories: true
        )

        let logURL = logsDirectory.appendingPathComponent(logName)
        if !FileManager.default.fileExists(atPath: logURL.path) {
            guard FileManager.default.createFile(atPath: logURL.path, contents: nil) else {
                throw LaunchError.couldNotCreateLog
            }
        }

        let logHandle = try FileHandle(forWritingTo: logURL)
        try logHandle.seekToEnd()
        let launchLine = "Launching \(executableURL.path) at \(Date())\n"
        try logHandle.write(contentsOf: Data(launchLine.utf8))

        let process = Process()
        process.executableURL = wineURL
        process.arguments = [executableURL.path]
        process.environment = ProcessInfo.processInfo.environment
        process.environment?["WINEPREFIX"] = prefixURL.path
        process.standardOutput = logHandle
        process.standardError = logHandle
        process.standardInput = FileHandle.nullDevice

        do {
            try process.run()
            try logHandle.close()
        } catch {
            try? logHandle.close()
            throw error
        }
    }

    enum LaunchError: LocalizedError {
        case invalidWineExecutable
        case programFileMissing
        case couldNotCreateLog

        var errorDescription: String? {
            switch self {
            case .invalidWineExecutable:
                return "مسار Wine غير صالح أو لا يملك صلاحية التشغيل."
            case .programFileMissing:
                return "ملف التثبيت أو البرنامج غير موجود."
            case .couldNotCreateLog:
                return "تعذر إنشاء ملف سجل Wine."
            }
        }
    }
}
