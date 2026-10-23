import Foundation

enum AppDirectories {
    private static let directoryName = "MacWineManager"

    static func supportDirectory() throws -> URL {
        guard let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw DirectoryError.applicationSupportUnavailable
        }

        let directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        return directoryURL
    }

    enum DirectoryError: LocalizedError {
        case applicationSupportUnavailable

        var errorDescription: String? {
            "تعذر الوصول إلى مجلد بيانات التطبيق."
        }
    }
}
