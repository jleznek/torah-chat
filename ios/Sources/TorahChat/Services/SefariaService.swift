import Foundation

/// Calls the Sefaria public REST API directly, replacing the MCP layer used on desktop.
///
/// Each method corresponds to an MCP tool from the desktop app so the LLM's
/// tool call names and schemas stay identical.
actor SefariaService {
    private static let baseURL = "https://www.sefaria.org/api"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Tool dispatch

    /// Route an LLM function call to the appropriate Sefaria API endpoint.
    func callTool(name: String, args: [String: JSONValue]) async throws -> JSONValue {
        switch name {
        case "get_text":
            let ref = args["reference"]?.stringValue ?? args["ref"]?.stringValue ?? ""
            return try await getText(reference: ref)

        case "english_semantic_search":
            let query = args["query"]?.stringValue ?? ""
            return try await semanticSearch(query: query)

        case "get_current_calendar":
            return try await getCalendar()

        case "get_topic_details":
            let slug = args["slug"]?.stringValue ?? args["topic"]?.stringValue ?? ""
            return try await getTopicDetails(slug: slug)

        case "search_in_book":
            let query  = args["query"]?.stringValue ?? ""
            let book   = args["book"]?.stringValue ?? args["path"]?.stringValue ?? ""
            return try await searchInBook(query: query, book: book)

        case "search_in_dictionaries":
            let query = args["query"]?.stringValue ?? args["word"]?.stringValue ?? ""
            return try await searchInDictionaries(query: query)

        case "get_english_translations":
            let ref = args["reference"]?.stringValue ?? args["ref"]?.stringValue ?? ""
            return try await getEnglishTranslations(reference: ref)

        case "get_text_catalogue_info":
            let title = args["title"]?.stringValue ?? ""
            return try await getTextCatalogueInfo(title: title)

        case "get_text_or_category_shape":
            let title = args["title"]?.stringValue ?? ""
            return try await getTextOrCategoryShape(title: title)

        case "get_links_between_texts":
            let ref = args["reference"]?.stringValue ?? args["ref"]?.stringValue ?? ""
            return try await getLinksBetweenTexts(reference: ref)

        case "clarify_name_argument":
            let name = args["name"]?.stringValue ?? ""
            return try await clarifyName(name: name)

        case "clarify_search_path_filter":
            let path = args["path"]?.stringValue ?? ""
            return try await clarifySearchPathFilter(path: path)

        case "get_available_manuscripts":
            let ref = args["reference"]?.stringValue ?? args["ref"]?.stringValue ?? ""
            return try await getAvailableManuscripts(reference: ref)

        default:
            return .object(["error": .string("Unknown tool: \(name)")])
        }
    }

    // MARK: - Individual API calls

    func getText(reference: String) async throws -> JSONValue {
        let encoded = reference.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? reference
        return try await get("\(Self.baseURL)/texts/\(encoded)")
    }

    func semanticSearch(query: String) async throws -> JSONValue {
        var comps = URLComponents(string: "\(Self.baseURL)/search-wrapper")!
        comps.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "type",  value: "text"),
            URLQueryItem(name: "field", value: "naive_lemmatizer"),
            URLQueryItem(name: "sort_type", value: "score"),
            URLQueryItem(name: "size",  value: "10"),
        ]
        return try await get(comps.url!.absoluteString)
    }

    func getCalendar() async throws -> JSONValue {
        return try await get("\(Self.baseURL)/calendars")
    }

    func getTopicDetails(slug: String) async throws -> JSONValue {
        let encoded = slug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? slug
        return try await get("\(Self.baseURL)/topics/\(encoded)?annotate_time_period=1&with_history=0")
    }

    func searchInBook(query: String, book: String) async throws -> JSONValue {
        var comps = URLComponents(string: "\(Self.baseURL)/search-wrapper")!
        comps.queryItems = [
            URLQueryItem(name: "query",     value: query),
            URLQueryItem(name: "type",      value: "text"),
            URLQueryItem(name: "filters[]", value: book),
            URLQueryItem(name: "size",      value: "10"),
        ]
        return try await get(comps.url!.absoluteString)
    }

    func searchInDictionaries(query: String) async throws -> JSONValue {
        var comps = URLComponents(string: "\(Self.baseURL)/search-wrapper")!
        comps.queryItems = [
            URLQueryItem(name: "query",     value: query),
            URLQueryItem(name: "type",      value: "text"),
            URLQueryItem(name: "filters[]", value: "Jastrow"),
            URLQueryItem(name: "filters[]", value: "BDB Dictionary"),
            URLQueryItem(name: "size",      value: "5"),
        ]
        return try await get(comps.url!.absoluteString)
    }

    func getEnglishTranslations(reference: String) async throws -> JSONValue {
        let encoded = reference.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? reference
        return try await get("\(Self.baseURL)/texts/\(encoded)?commentary=0&context=0&pad=0&multiple=1")
    }

    func getTextCatalogueInfo(title: String) async throws -> JSONValue {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        return try await get("\(Self.baseURL)/index/\(encoded)")
    }

    func getTextOrCategoryShape(title: String) async throws -> JSONValue {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        return try await get("\(Self.baseURL)/shape/\(encoded)")
    }

    func getLinksBetweenTexts(reference: String) async throws -> JSONValue {
        let encoded = reference.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? reference
        return try await get("\(Self.baseURL)/links/\(encoded)")
    }

    func clarifyName(name: String) async throws -> JSONValue {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        return try await get("\(Self.baseURL)/name/\(encoded)?autocomplete_redirects=1")
    }

    func clarifySearchPathFilter(path: String) async throws -> JSONValue {
        // Returns shape/index info so the LLM can build a valid filter string
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return try await get("\(Self.baseURL)/shape/\(encoded)")
    }

    func getAvailableManuscripts(reference: String) async throws -> JSONValue {
        let encoded = reference.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? reference
        return try await get("https://manuscripts.sefaria.org/api/manuscripts/\(encoded)")
    }

    // MARK: - HTTP helper

    private func get(_ urlString: String) async throws -> JSONValue {
        guard let url = URL(string: urlString) else {
            return .object(["error": .string("Invalid URL: \(urlString)")])
        }
        var request = URLRequest(url: url)
        request.setValue("TorahChat/1.0 iOS", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            return .object(["error": .string("HTTP \(http.statusCode)")])
        }
        guard let raw = try? JSONSerialization.jsonObject(with: data) else {
            return .object(["error": .string("Invalid JSON response")])
        }
        return JSONValue.from(raw)
    }
}

// MARK: - Convenience

private extension JSONValue {
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
}
