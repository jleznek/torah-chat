# Torah Chat — iPadOS

A native SwiftUI iPadOS port of the Torah Chat desktop app.
Calls the Sefaria REST API directly (no MCP relay needed), stores API keys
in the iOS Keychain, and persists chat history in the app's Documents directory.

## Requirements

| Tool | Version |
|------|---------|
| macOS | 13 Ventura or later |
| Xcode | 15 or later |
| iOS deployment target | iOS 17+ |

> **Note:** iOS apps must be compiled with Xcode, which runs **only on macOS**.
> If you're on Windows, you can use a cloud Mac service
> ([MacinCloud](https://www.macincloud.com), [MacStadium](https://www.macstadium.com))
> or a **GitHub Actions macOS runner** to build and archive.

---

## Project Setup (Xcode)

1. On your Mac, open **Xcode** and choose **File › New › Project**.
2. Select **iOS › App** and click **Next**.
3. Fill in:
   - **Product Name:** `TorahChat`
   - **Bundle Identifier:** `com.yourname.torahchat`  *(change before App Store submission)*
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployments:** iOS 17.0
4. Click **Next**, choose a save location, and click **Create**.
5. Delete the auto-generated `ContentView.swift` that Xcode creates.
6. Drag all files from `Sources/TorahChat/` into the Xcode project navigator, keeping the folder structure. When prompted, select **"Create groups"** and make sure **"Add to target: TorahChat"** is checked.

### Required Xcode settings

In the project target's **Info** tab (or `Info.plist`), add:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>sefaria.org</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
        <key>manuscripts.sefaria.org</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
        <key>cdn.jsdelivr.net</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

In **Signing & Capabilities**, add:
- **Keychain Sharing** (required for `KeychainService.swift`)
- Ensure your team and bundle ID are set for device/App Store builds.

---

## Architecture

```
Sources/TorahChat/
├── App/
│   └── TorahChatApp.swift       @main entry point
├── Models/
│   ├── Message.swift            Chat message + HistoryMessage + JSONValue
│   ├── Chat.swift               Chat session (messages + history)
│   └── ProviderInfo.swift       Provider metadata + tool types
├── Services/
│   ├── KeychainService.swift    Secure API key storage
│   ├── SefariaService.swift     Sefaria REST API (replaces MCP)
│   ├── ChatPersistence.swift    Chat/settings file I/O
│   ├── RateLimiter.swift        Sliding-window RPM limiter
│   ├── ChatEngine.swift         Tool-calling loop (port of desktop ChatEngine)
│   └── Prompts.swift            System prompt
├── Providers/
│   ├── LLMProvider.swift        Protocol + AbortSignal
│   ├── OpenAICompatibleProvider.swift  OpenAI / Groq / Grok / DeepSeek / Mistral / OpenRouter
│   ├── AnthropicProvider.swift  Claude streaming
│   ├── GeminiProvider.swift     Gemini streaming
│   └── Providers.swift          Registry, factory, tool declarations
├── ViewModels/
│   └── ChatViewModel.swift      @Observable main state
└── Views/
    ├── ContentView.swift         NavigationSplitView root
    ├── SidebarView.swift         Chat history list
    ├── ChatView.swift            Messages + input bar
    ├── MessageBubbleView.swift   Individual message
    ├── MarkdownView.swift        WKWebView markdown renderer
    └── SettingsView.swift        Provider/key/length config
```

### Key design decisions

| Decision | Reason |
|---|---|
| **Direct Sefaria REST API** instead of MCP | MCP uses Node.js, unavailable on iOS |
| **OpenAI-compatible class** shared by 6 providers | They all use the same JSON streaming API |
| **WKWebView for markdown** | Handles Hebrew RTL, tables, `<a>` links natively |
| **iOS Keychain** for API keys | Secure enclave; keys survive app updates |
| **`@Observable` (iOS 17)** | Eliminates `@Published` boilerplate |
| **`URLSession.bytes`** for SSE | Native async streaming without third-party SDKs |

---

## Adding a New Provider

1. Add a `let MYPROVIDER_INFO = ProviderInfo(...)` constant in `Providers.swift`.
2. Add the info to `AVAILABLE_PROVIDERS`.
3. Add a `case "myprovider":` in `createProvider()`.
4. If it's OpenAI-compatible (same `/chat/completions` API), just pass the correct
   `baseURL` to `OpenAICompatibleProvider`. Otherwise create a new `MyProvider.swift`
   conforming to `LLMProvider`.

---

## Bundling marked.js (recommended for production)

The current `MarkdownView.swift` loads `marked.js` from jsDelivr CDN.
For App Store submission and offline use, bundle it locally:

1. Download `marked.min.js` from https://github.com/markedjs/marked/releases
2. Add it to the Xcode project (drag into the project, add to target).
3. In `MarkdownView.swift`, change the `<script>` tag to load from the bundle:
   ```swift
   // Replace CDN script tag with:
   let markedURL = Bundle.main.url(forResource: "marked.min", withExtension: "js")!
   let markedJS  = try! String(contentsOf: markedURL)
   // Then inject markedJS inline in the HTML <script> block
   ```

---

## Building for the App Store

1. Set your **Bundle Identifier** and **Team** in Signing & Capabilities.
2. Choose an **iPad** simulator or real device as the build target.
3. **Product › Archive** to build a release archive.
4. Open **Organizer** (Window menu), select your archive, and click
   **Distribute App › App Store Connect**.

---

## Privacy

All LLM API calls go directly from the user's device to the provider's servers
using the user's own API key. No data passes through any intermediate server.
Sefaria API calls are unauthenticated read-only requests to `www.sefaria.org`.
