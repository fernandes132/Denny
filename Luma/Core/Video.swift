import Foundation

struct Video: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var channel: String
    var category: String
    var detail: String
    var metadataDate: Date?

    var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(id)")! }
    var thumbnailURL: URL { URL(string: "https://i.ytimg.com/vi/\(id)/hqdefault.jpg")! }

    static func link(_ id: String) -> Video {
        Video(id: id, title: "YouTube-video", channel: "YouTube", category: "Eigen links",
              detail: "Je eigen videolink. Titel en beschikbaarheid worden door YouTube bepaald.")
    }

    func removingExpiredMetadata(now: Date = Date()) -> Video {
        guard let date = metadataDate, now.timeIntervalSince(date) > 29 * 86_400 else { return self }
        return .link(id)
    }
}

enum YouTubeLink {
    static func validID(_ value: String) -> Bool {
        value.utf8.count == 11 && value.utf8.allSatisfy {
            (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 95 || $0 == 45
        }
    }

    static func parse(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 4096 else { return nil }
        if validID(trimmed) { return trimmed }
        let candidate = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URLComponents(string: candidate),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              url.user == nil, url.password == nil,
              url.port == nil || url.port == 443 || url.port == 80,
              let host = url.host?.lowercased() else { return nil }
        let pieces = url.path.split(separator: "/").map(String.init)
        let id: String?
        if ["youtu.be", "www.youtu.be"].contains(host), pieces.count == 1 {
            id = pieces.first
        } else if ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "youtube-nocookie.com", "www.youtube-nocookie.com"].contains(host) {
            if url.path == "/watch" {
                id = url.queryItems?.first(where: { $0.name == "v" })?.value
            } else if pieces.count == 2, ["shorts", "embed", "live"].contains(pieces[0]) {
                id = pieces[1]
            } else { id = nil }
        } else { id = nil }
        guard let id, validID(id) else { return nil }
        return id
    }
}

enum Catalog {
    static let videos: [Video] = [
        Video(id: "aqz-KE-bpKQ", title: "Big Buck Bunny", channel: "Blender", category: "Film", detail: "Een open animatiefilm van de Blender Foundation. Bekijk de originele video en credits op YouTube."),
        Video(id: "Y-rmzh0PI3c", title: "Cosmos Laundromat — First Cycle", channel: "Blender", category: "Film", detail: "Een experimentele open film van Blender, gemaakt in Amsterdam. Voor een volwassen publiek; bekijk de inhoudsinformatie op YouTube."),
        Video(id: "21X5lGlDOfg", title: "NASA TV", channel: "NASA", category: "Ruimte", detail: "Een link naar NASA TV op YouTube. De huidige beschikbaarheid is niet bevestigd; livestreams kunnen wisselen, eindigen of tijdelijk niet beschikbaar zijn."),
        Video(id: "M7lc1UVf-VE", title: "YouTube Player API-demo", channel: "YouTube Developers", category: "Tech", detail: "De voorbeeldvideo uit de officiële YouTube IFrame API-documentatie. Handig om de speler te testen.")
    ]
}
