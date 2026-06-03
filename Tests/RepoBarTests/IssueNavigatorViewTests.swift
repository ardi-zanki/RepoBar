import Foundation
@testable import RepoBar
@testable import RepoBarCore
import Testing

struct IssueNavigatorViewTests {
    @Test
    func `initial reference matches do not get overwritten by clipboard seed`() {
        #expect(!IssueNavigatorView.shouldSeedClipboardOnAppear(hasInitialMatches: true))
        #expect(IssueNavigatorView.shouldSeedClipboardOnAppear(hasInitialMatches: false))
    }

    @Test
    func `decorated issue navigator labels remain parseable for manual search`() {
        let queries = GitHubReferenceTranslator.queries(from: "1. openclaw/gogcli#673 · 1 PR · add --thread-id to G")

        #expect(queries == [.repositoryIssueNumber(repositoryFullName: "openclaw/gogcli", number: 673)])
    }

    @Test
    func `unresolved metadata uses reference label in navigator chrome`() throws {
        let match = try GitHubReferenceMatch(
            query: .repositoryIssueNumber(repositoryFullName: "openclaw/imsg", number: 135),
            title: "GitHub preview unavailable",
            url: #require(URL(string: "https://github.com/openclaw/imsg/issues/135")),
            repositoryFullName: "openclaw/imsg",
            kind: .issue,
            state: nil,
            createdAt: nil,
            updatedAt: Date(timeIntervalSince1970: 0),
            isResolved: false
        )

        #expect(match.issueNavigatorHeaderTitle == "openclaw/imsg#135")
        #expect(match.issueNavigatorTitle == "openclaw/imsg#135")
    }
}
