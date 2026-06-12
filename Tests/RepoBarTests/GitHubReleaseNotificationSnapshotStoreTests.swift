import Foundation
@testable import RepoBarCore
import Testing

struct GitHubReleaseNotificationSnapshotStoreTests {
    @Test
    func `snapshot store round trips and clears state`() throws {
        let suiteName = "GitHubReleaseNotificationSnapshotStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let store = GitHubReleaseNotificationSnapshotStore(defaults: defaults)
        let state = GitHubReleaseNotificationSnapshotState(
            repositories: ["steipete/repobar": ["v1.0.0": Date(timeIntervalSince1970: 100)]],
            repositoryBaselines: ["steipete/repobar": Date(timeIntervalSince1970: 150)]
        )

        store.save(state)

        let loaded = store.load()
        #expect(loaded == state)

        store.clear()

        #expect(store.load() == GitHubReleaseNotificationSnapshotState())
    }

    @Test
    func `snapshot store falls back to empty state for invalid data`() throws {
        let suiteName = "GitHubReleaseNotificationSnapshotStoreTests.invalid.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defaults.set(Data([0x00, 0x01]), forKey: GitHubReleaseNotificationSnapshotStore.storageKey)
        let store = GitHubReleaseNotificationSnapshotStore(defaults: defaults)

        #expect(store.load() == GitHubReleaseNotificationSnapshotState())
    }
}
