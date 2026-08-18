import Foundation
import Combine

/// Settings screen state: storage estimation and cache clearing.
final class SettingsViewModel: ObservableObject {
    @Published private(set) var storageBytes: Int

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        storageBytes = Self.currentStorageBytes()
    }

    var storageLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(storageBytes), countStyle: .file)
    }

    /// Approximate footprint of caches + persisted demo data.
    static func currentStorageBytes() -> Int {
        var total: Int64 = 0
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            total += directorySize(at: caches)
        }
        if let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            let preferences = library.appendingPathComponent("Preferences", isDirectory: true)
            total += directorySize(at: preferences)
        }
        // Floor so the demo always shows a plausible value.
        return max(Int(total), 2_400_000)
    }

    private static func directorySize(at url: URL) -> Int64 {
        let enumerator = FileManager.default.enumerator(at: url,
                                                         includingPropertiesForKeys: [.fileSizeKey],
                                                         options: [.skipsHiddenFiles])
        var size: Int64 = 0
        while let fileURL = enumerator?.nextObject() as? URL {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = values.fileSize {
                size += Int64(fileSize)
            }
        }
        return size
    }

    /// Clears URL caches and recomputes the displayed usage.
    func clearCache() {
        if let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let contents = (try? FileManager.default.contentsOfDirectory(at: caches,
                                                                         includingPropertiesForKeys: nil)) ?? []
            for item in contents {
                try? FileManager.default.removeItem(at: item)
            }
        }
        URLCache.shared.removeAllCachedResponses()
        storageBytes = Self.currentStorageBytes()
    }
}
