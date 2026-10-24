import Foundation

struct YouTubeService: YouTubeSearching {
    let session: URLSession
    init(session: URLSession = .shared) { self.session = session }

    enum APIError: LocalizedError, Equatable {
        case invalidKey, quota, restricted, disabled, connection, timeout, invalidResponse, server
        var errorDescription: String? {
            switch self {
            case .invalidKey: return "Controleer je API-sleutel en of YouTube Data API v3 is ingeschakeld."
            case .quota: return "Je YouTube-daglimiet is bereikt. Probeer later opnieuw of controleer je quota in Google Cloud."
            case .restricted: return "Deze API-sleutel heeft geen toegang. Controleer de API- en iOS-appbeperkingen in Google Cloud."
            case .disabled: return "Schakel YouTube Data API v3 in voor het Google Cloud-project van deze sleutel."
            case .connection: return "Geen verbinding met YouTube. Controleer je internet en probeer opnieuw."
            case .timeout: return "YouTube reageert te langzaam. Probeer opnieuw wanneer je verbinding stabiel is."
            case .invalidResponse: return "YouTube stuurde een onleesbaar antwoord. Probeer het later opnieuw."
            case .server: return "YouTube kon geen resultaten leveren. Probeer het later opnieuw."
            }
        }
    }

    func search(_ query: String, key: String) async throws -> [Video] {
        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        components.queryItems = [URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query), URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "20"), URLQueryItem(name: "videoEmbeddable", value: "true"),
            URLQueryItem(name: "safeSearch", value: "moderate")]
        var request = URLRequest(url: components.url!, cachePolicy: .reloadIgnoringLocalCacheData)
        request.timeoutInterval = 20
        request.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(Bundle.main.bundleIdentifier, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        let data: Data
        let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch is CancellationError { throw CancellationError() }
        catch let error as URLError where error.code == .cancelled { throw CancellationError() }
        catch let error as URLError where error.code == .timedOut { throw APIError.timeout }
        catch { throw APIError.connection }
        guard let http = response as? HTTPURLResponse else { throw APIError.server }
        switch http.statusCode {
        case 200: break
        case 400, 401: throw APIError.invalidKey
        case 403:
            let failure = try? JSONDecoder().decode(FailureResponse.self, from: data)
            let reasons = failure?.error.errors?.map(\.reason) ?? []
            if reasons.contains(where: { ["quotaExceeded", "dailyLimitExceeded", "rateLimitExceeded"].contains($0) }) { throw APIError.quota }
            if reasons.contains("accessNotConfigured") { throw APIError.disabled }
            throw APIError.restricted
        case 429: throw APIError.quota
        default: throw APIError.server
        }
        guard let result = try? JSONDecoder().decode(SearchResponse.self, from: data) else { throw APIError.invalidResponse }
        var seen = Set<String>()
        return result.items.compactMap { item in
            guard let id = item.id.videoId, YouTubeLink.validID(id), seen.insert(id).inserted else { return nil }
            return Video(id: id, title: Self.decodeEntities(item.snippet.title),
                         channel: Self.decodeEntities(item.snippet.channelTitle), category: "YouTube",
                         detail: Self.decodeEntities(item.snippet.description), metadataDate: Date())
        }
    }

    static func decodeEntities(_ text: String) -> String {
        // Decode exactly once, deterministically, without HTML rendering or double-decoding &amp;lt;.
        let pattern = "&(?:#[xX][0-9a-fA-F]+|#[0-9]+|amp|quot|apos|lt|gt);"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let output = NSMutableString(string: text)
        let named = ["amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">"]
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            let entity = (text as NSString).substring(with: match.range)
            let body = String(entity.dropFirst().dropLast())
            let replacement: String?
            if body.hasPrefix("#x") || body.hasPrefix("#X") {
                replacement = UInt32(body.dropFirst(2), radix: 16).flatMap { UnicodeScalar($0) }.map { String($0) }
            } else if body.hasPrefix("#") {
                replacement = UInt32(body.dropFirst()).flatMap { UnicodeScalar($0) }.map { String($0) }
            } else { replacement = named[body] }
            if let replacement { output.replaceCharacters(in: match.range, with: replacement) }
        }
        return output as String
    }

    private struct SearchResponse: Decodable { let items: [Item] }
    private struct FailureResponse: Decodable {
        let error: Failure
        struct Failure: Decodable { let errors: [Reason]? }
        struct Reason: Decodable { let reason: String }
    }
    private struct Item: Decodable { let id: VideoID; let snippet: Snippet }
    private struct VideoID: Decodable { let videoId: String? }
    private struct Snippet: Decodable { let title: String; let channelTitle: String; let description: String }
}
