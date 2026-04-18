import Foundation

// MARK: - Provider metadata

let GEMINI_INFO = ProviderInfo(
    id: "gemini",
    name: "Google Gemini",
    models: [
        ProviderModel(id: "gemini-2.5-pro-preview-03-25", name: "Gemini 2.5 Pro"),
        ProviderModel(id: "gemini-2.0-flash",              name: "Gemini 2.0 Flash",      rpm: 15),
        ProviderModel(id: "gemini-2.0-flash-lite",         name: "Gemini 2.0 Flash Lite", rpm: 30),
        ProviderModel(id: "gemini-1.5-pro",                name: "Gemini 1.5 Pro"),
        ProviderModel(id: "gemini-1.5-flash",              name: "Gemini 1.5 Flash",      rpm: 15),
    ],
    defaultModel: "gemini-2.0-flash",
    rateLimit: ProviderInfo.RateLimit(rpm: 60, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "AIza...",
    keyHelpURL: "https://aistudio.google.com/app/apikey",
    keyHelpLabel: "Google AI Studio"
)

let OPENAI_INFO = ProviderInfo(
    id: "openai",
    name: "OpenAI",
    models: [
        ProviderModel(id: "gpt-4.1-mini", name: "GPT-4.1 Mini"),
        ProviderModel(id: "gpt-4.1",      name: "GPT-4.1"),
        ProviderModel(id: "gpt-4o-mini",  name: "GPT-4o Mini"),
        ProviderModel(id: "gpt-4o",       name: "GPT-4o"),
        ProviderModel(id: "o4-mini",      name: "o4 Mini"),
    ],
    defaultModel: "gpt-4.1-mini",
    rateLimit: ProviderInfo.RateLimit(rpm: 500, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "sk-...",
    keyHelpURL: "https://platform.openai.com/api-keys",
    keyHelpLabel: "OpenAI Platform"
)

let ANTHROPIC_INFO = ProviderInfo(
    id: "anthropic",
    name: "Anthropic",
    models: [
        ProviderModel(id: "claude-3-7-sonnet-20250219", name: "Claude 3.7 Sonnet"),
        ProviderModel(id: "claude-3-5-haiku-20241022",  name: "Claude 3.5 Haiku"),
        ProviderModel(id: "claude-3-5-sonnet-20241022", name: "Claude 3.5 Sonnet"),
        ProviderModel(id: "claude-3-opus-20240229",     name: "Claude 3 Opus"),
    ],
    defaultModel: "claude-3-7-sonnet-20250219",
    rateLimit: ProviderInfo.RateLimit(rpm: 50, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "sk-ant-...",
    keyHelpURL: "https://console.anthropic.com/settings/keys",
    keyHelpLabel: "Anthropic Console"
)

let GROK_INFO = ProviderInfo(
    id: "grok",
    name: "Grok (xAI)",
    models: [
        ProviderModel(id: "grok-3-mini", name: "Grok 3 Mini"),
        ProviderModel(id: "grok-3",      name: "Grok 3"),
        ProviderModel(id: "grok-2",      name: "Grok 2"),
    ],
    defaultModel: "grok-3-mini",
    rateLimit: ProviderInfo.RateLimit(rpm: 60, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "xai-...",
    keyHelpURL: "https://console.x.ai/",
    keyHelpLabel: "xAI Console"
)

let MISTRAL_INFO = ProviderInfo(
    id: "mistral",
    name: "Mistral",
    models: [
        ProviderModel(id: "mistral-small-latest",  name: "Mistral Small"),
        ProviderModel(id: "mistral-medium-latest", name: "Mistral Medium"),
        ProviderModel(id: "mistral-large-latest",  name: "Mistral Large"),
    ],
    defaultModel: "mistral-small-latest",
    rateLimit: ProviderInfo.RateLimit(rpm: 60, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "...",
    keyHelpURL: "https://console.mistral.ai/api-keys/",
    keyHelpLabel: "Mistral Console"
)

let DEEPSEEK_INFO = ProviderInfo(
    id: "deepseek",
    name: "DeepSeek",
    models: [
        ProviderModel(id: "deepseek-chat",     name: "DeepSeek V3"),
        ProviderModel(id: "deepseek-reasoner", name: "DeepSeek R1"),
    ],
    defaultModel: "deepseek-chat",
    rateLimit: ProviderInfo.RateLimit(rpm: 60, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "sk-...",
    keyHelpURL: "https://platform.deepseek.com/api_keys",
    keyHelpLabel: "DeepSeek Platform"
)

let GROQ_INFO = ProviderInfo(
    id: "groq",
    name: "Groq",
    models: [
        ProviderModel(id: "llama-3.3-70b-versatile",        name: "Llama 3.3 70B"),
        ProviderModel(id: "llama-3.1-8b-instant",           name: "Llama 3.1 8B"),
        ProviderModel(id: "meta-llama/llama-4-scout-17b-16e-instruct", name: "Llama 4 Scout"),
    ],
    defaultModel: "llama-3.3-70b-versatile",
    rateLimit: ProviderInfo.RateLimit(rpm: 30, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "gsk_...",
    keyHelpURL: "https://console.groq.com/keys",
    keyHelpLabel: "Groq Console"
)

let OPENROUTER_INFO = ProviderInfo(
    id: "openrouter",
    name: "OpenRouter",
    models: [
        ProviderModel(id: "google/gemini-2.0-flash-001",  name: "Gemini 2.0 Flash"),
        ProviderModel(id: "anthropic/claude-3.5-haiku",   name: "Claude 3.5 Haiku"),
        ProviderModel(id: "openai/gpt-4o-mini",           name: "GPT-4o Mini"),
        ProviderModel(id: "meta-llama/llama-3.3-70b-instruct", name: "Llama 3.3 70B"),
    ],
    defaultModel: "google/gemini-2.0-flash-001",
    rateLimit: ProviderInfo.RateLimit(rpm: 60, windowMs: 60_000),
    requiresKey: true,
    keyPlaceholder: "sk-or-...",
    keyHelpURL: "https://openrouter.ai/keys",
    keyHelpLabel: "OpenRouter"
)

// MARK: - Registry

let AVAILABLE_PROVIDERS: [ProviderInfo] = [
    GEMINI_INFO,
    OPENAI_INFO,
    ANTHROPIC_INFO,
    GROK_INFO,
    MISTRAL_INFO,
    DEEPSEEK_INFO,
    GROQ_INFO,
    OPENROUTER_INFO,
]

/// Instantiate the correct `LLMProvider` for a given provider ID and API key.
func createProvider(providerId: String, apiKey: String, model: String?) -> LLMProvider? {
    switch providerId {
    case "gemini":
        return GeminiProvider(info: GEMINI_INFO, apiKey: apiKey, model: model)

    case "openai":
        return OpenAICompatibleProvider(
            info: OPENAI_INFO, apiKey: apiKey, model: model,
            baseURL: "https://api.openai.com/v1")

    case "anthropic":
        return AnthropicProvider(info: ANTHROPIC_INFO, apiKey: apiKey, model: model)

    case "grok":
        return OpenAICompatibleProvider(
            info: GROK_INFO, apiKey: apiKey, model: model,
            baseURL: "https://api.x.ai/v1")

    case "mistral":
        return OpenAICompatibleProvider(
            info: MISTRAL_INFO, apiKey: apiKey, model: model,
            baseURL: "https://api.mistral.ai/v1")

    case "deepseek":
        return OpenAICompatibleProvider(
            info: DEEPSEEK_INFO, apiKey: apiKey, model: model,
            baseURL: "https://api.deepseek.com/v1")

    case "groq":
        return OpenAICompatibleProvider(
            info: GROQ_INFO, apiKey: apiKey, model: model,
            baseURL: "https://api.groq.com/openai/v1")

    case "openrouter":
        return OpenAICompatibleProvider(
            info: OPENROUTER_INFO, apiKey: apiKey, model: model,
            baseURL: "https://openrouter.ai/api/v1")

    default:
        return nil
    }
}

// MARK: - Sefaria tool declarations (passed to every LLM call)

let SEFARIA_TOOLS: [ToolDeclaration] = [
    ToolDeclaration(
        name: "get_text",
        description: "Retrieve a specific Jewish text from Sefaria by reference (e.g. 'Genesis 1:1', 'Berakhot 2a', 'Rashi on Genesis 1:1').",
        parameters: [
            "type": .string("object"),
            "properties": .object(["reference": .object(["type": .string("string"), "description": .string("The text reference to retrieve")])]),
            "required": .array([.string("reference")]),
        ]
    ),
    ToolDeclaration(
        name: "english_semantic_search",
        description: "Search Sefaria's library using semantic similarity to find conceptually related Jewish texts.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["query": .object(["type": .string("string"), "description": .string("Natural language search query")])]),
            "required": .array([.string("query")]),
        ]
    ),
    ToolDeclaration(
        name: "get_current_calendar",
        description: "Get the current Hebrew date, weekly parasha (Torah portion), Daf Yomi, and other daily/weekly Jewish calendar information. Always use this for calendar questions.",
        parameters: [
            "type": .string("object"),
            "properties": .object([:]),
            "required": .array([]),
        ]
    ),
    ToolDeclaration(
        name: "get_topic_details",
        description: "Get Sefaria's curated topic page for a Jewish concept or theme, including related sources, subtopics, and descriptions.",
        parameters: [
            "type": .string("object"),
            "properties": .object([
                "slug": .object(["type": .string("string"), "description": .string("The topic slug or name (e.g. 'shabbat', 'teshuvah')")]),
            ]),
            "required": .array([.string("slug")]),
        ]
    ),
    ToolDeclaration(
        name: "search_in_book",
        description: "Search within a specific book or commentary in Sefaria.",
        parameters: [
            "type": .string("object"),
            "properties": .object([
                "query": .object(["type": .string("string"), "description": .string("Search query")]),
                "book":  .object(["type": .string("string"), "description": .string("Book or commentary title to search in")]),
            ]),
            "required": .array([.string("query"), .string("book")]),
        ]
    ),
    ToolDeclaration(
        name: "search_in_dictionaries",
        description: "Search for a Hebrew, Aramaic, or Biblical word in Sefaria's lexicons (Jastrow, BDB, Klein, etc.).",
        parameters: [
            "type": .string("object"),
            "properties": .object([
                "query": .object(["type": .string("string"), "description": .string("The word or phrase to look up")]),
            ]),
            "required": .array([.string("query")]),
        ]
    ),
    ToolDeclaration(
        name: "get_english_translations",
        description: "Retrieve all available English translations of a specific text passage for comparison.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["reference": .object(["type": .string("string")])]),
            "required": .array([.string("reference")]),
        ]
    ),
    ToolDeclaration(
        name: "get_text_catalogue_info",
        description: "Get metadata about a text: author, date, structure, and literary context.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["title": .object(["type": .string("string")])]),
            "required": .array([.string("title")]),
        ]
    ),
    ToolDeclaration(
        name: "get_text_or_category_shape",
        description: "Get the structure and outline of a text or category (e.g. list of chapters, tractates).",
        parameters: [
            "type": .string("object"),
            "properties": .object(["title": .object(["type": .string("string")])]),
            "required": .array([.string("title")]),
        ]
    ),
    ToolDeclaration(
        name: "get_links_between_texts",
        description: "Find texts that are linked to or quoted in a given passage.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["reference": .object(["type": .string("string")])]),
            "required": .array([.string("reference")]),
        ]
    ),
    ToolDeclaration(
        name: "clarify_name_argument",
        description: "Validate and resolve a Sefaria text reference name before using it in other tool calls.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["name": .object(["type": .string("string")])]),
            "required": .array([.string("name")]),
        ]
    ),
    ToolDeclaration(
        name: "clarify_search_path_filter",
        description: "Validate a search path filter string for use with search_in_book.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["path": .object(["type": .string("string")])]),
            "required": .array([.string("path")]),
        ]
    ),
    ToolDeclaration(
        name: "get_available_manuscripts",
        description: "Check for available manuscript images for a given text passage.",
        parameters: [
            "type": .string("object"),
            "properties": .object(["reference": .object(["type": .string("string")])]),
            "required": .array([.string("reference")]),
        ]
    ),
]
