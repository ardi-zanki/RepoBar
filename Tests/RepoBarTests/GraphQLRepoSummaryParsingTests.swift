import Foundation
@testable import RepoBarCore
import Testing

struct GraphQLRepoSummaryParsingTests {
    @Test
    func `repo summary uses newest non draft release`() throws {
        let data = Data("""
        {
          "data": {
            "repository": {
              "releases": {
                "nodes": [
                  {
                    "name": "Draft",
                    "tagName": "v3.0.0",
                    "publishedAt": null,
                    "createdAt": "2026-01-03T00:00:00Z",
                    "url": "https://example.com/v3",
                    "isDraft": true,
                    "isPrerelease": false
                  },
                  {
                    "name": "Prerelease",
                    "tagName": "v2.1.0-beta",
                    "publishedAt": "2026-01-05T00:00:00Z",
                    "createdAt": "2026-01-05T00:00:00Z",
                    "url": "https://example.com/v2-beta",
                    "isDraft": false,
                    "isPrerelease": true
                  },
                  {
                    "name": "Created Later",
                    "tagName": "v2.0.0-created",
                    "publishedAt": "2026-01-02T00:00:00Z",
                    "createdAt": "2026-01-02T00:00:00Z",
                    "url": "https://example.com/v2-created",
                    "isDraft": false,
                    "isPrerelease": false
                  },
                  {
                    "name": "Published Later",
                    "tagName": "v2.0.0",
                    "publishedAt": "2026-01-04T00:00:00Z",
                    "createdAt": "2026-01-01T00:00:00Z",
                    "url": "https://example.com/v2",
                    "isDraft": false,
                    "isPrerelease": false
                  },
                  {
                    "name": "Old",
                    "tagName": "v1.0.0",
                    "publishedAt": "2026-01-01T00:00:00Z",
                    "createdAt": "2026-01-01T00:00:00Z",
                    "url": "https://example.com/v1",
                    "isDraft": false,
                    "isPrerelease": false
                  }
                ]
              },
              "issues": { "totalCount": 4 },
              "pullRequests": { "totalCount": 2 }
            }
          }
        }
        """.utf8)

        let summary = try GraphQLClient.decodeRepoSummary(from: data, owner: "owner", name: "repo")

        #expect(summary.openIssues == 4)
        #expect(summary.openPulls == 2)
        #expect(summary.release?.tag == "v2.0.0")
    }
}
