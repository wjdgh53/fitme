import Foundation
import SwiftUI

@MainActor
final class UserProfileStore: ObservableObject {
    private static let legacyProfileImageDataKey = "fitme.profileImageData"
    private static let profileImageDirectoryName = "fitme"
    private static let profileImageFileName = "profile-avatar.jpg"

    private static func profileImageDirectoryURL() -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return FileManager.default.temporaryDirectory.appendingPathComponent("fitme")
        }
        return base.appendingPathComponent(profileImageDirectoryName, isDirectory: true)
    }

    private static func profileImageFileURL() -> URL {
        profileImageDirectoryURL().appendingPathComponent(profileImageFileName, isDirectory: false)
    }

    private static func ensureProfileImageDirectoryExists() throws {
        let dir = profileImageDirectoryURL()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // MARK: - Published State
    @Published var userName: String = "User"
    var profileImageURL: URL? = nil
    @Published var profileImageData: Data? = nil

    init() {
        let defaults = UserDefaults.standard

        let url = Self.profileImageFileURL()
        if let data = try? Data(contentsOf: url) {
            profileImageData = data
        }

        // Legacy migration from UserDefaults -> file
        if let legacyData = defaults.data(forKey: Self.legacyProfileImageDataKey) {
            do {
                try Self.ensureProfileImageDirectoryExists()
                try legacyData.write(to: url, options: [.atomic])
                profileImageData = legacyData
                defaults.removeObject(forKey: Self.legacyProfileImageDataKey)
            } catch {
                profileImageData = legacyData
            }
        }
    }

    func setProfileImageData(_ data: Data?) throws {
        profileImageData = data

        let url = Self.profileImageFileURL()
        if let data {
            try Self.ensureProfileImageDirectoryExists()
            try data.write(to: url, options: [.atomic])
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
