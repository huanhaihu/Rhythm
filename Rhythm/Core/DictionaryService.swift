import Foundation

/// Local English→Chinese dictionary backed by a bundled ECDICT TSV.
///
/// Each TSV row: `word \t phonetic \t translation`
/// `translation` is multi-POS, separated by literal `\n` (backslash-n, two chars).
/// Each POS line typically begins with a token like `n.`, `v.`, `vt.`, `vi.`, `adj.`, `adv.`,
/// `prep.`, `conj.`, `pron.`, `art.`, `num.`, `interj.`, `aux.`, `abbr.`, or a tag like `[网络]` / `[经]`.
final class DictionaryService {
    static let shared = DictionaryService()

    struct Entry {
        let phonetic: String
        let senses: [WordSense]
    }

    @Published private(set) var isReady: Bool = false

    private var entries: [String: Entry] = [:]
    private let queue = DispatchQueue(label: "rhythm.dictionary.load", qos: .userInitiated)

    private init() {
        load()
    }

    // MARK: - Public API

    /// Look up a word case-insensitively. Returns nil if dictionary not loaded yet or word not found.
    func lookup(_ word: String) -> Entry? {
        let key = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return nil }
        return entries[key]
    }

    /// One sense per group, max 3 (noun, verb, other). Other = first non-noun, non-verb sense.
    func topSenses(for word: String) -> [WordSense] {
        guard let entry = lookup(word) else { return [] }
        return Self.pickTopSenses(from: entry.senses)
    }

    static func pickTopSenses(from senses: [WordSense]) -> [WordSense] {
        var noun: WordSense?
        var verb: WordSense?
        var other: WordSense?
        for s in senses {
            switch s.group {
            case .noun: if noun == nil { noun = s }
            case .verb:
                if verb == nil {
                    verb = s
                } else if let existing = verb, existing.meaning.count < s.meaning.count {
                    // prefer the longer (richer) verb sense if multiple vt/vi entries
                    verb = WordSense(pos: "v.", meaning: existing.meaning + "；" + s.meaning)
                }
            case .other: if other == nil { other = s }
            }
        }
        return [noun, verb, other].compactMap { $0 }
    }

    // MARK: - Loading

    private func load() {
        queue.async { [weak self] in
            guard let self else { return }
            guard let url = Bundle.main.url(forResource: "ecdict", withExtension: "tsv") else {
                NSLog("[Dictionary] resource ecdict.tsv not found in bundle")
                return
            }
            let started = Date()
            do {
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                let parsed = Self.parse(data: data)
                let elapsed = Date().timeIntervalSince(started)
                NSLog("[Dictionary] loaded \(parsed.count) entries in \(String(format: "%.2f", elapsed))s")
                DispatchQueue.main.async {
                    self.entries = parsed
                    self.isReady = true
                }
            } catch {
                NSLog("[Dictionary] failed to read tsv: \(error)")
            }
        }
    }

    private static func parse(data: Data) -> [String: Entry] {
        var result: [String: Entry] = [:]
        result.reserveCapacity(200_000)

        // Iterate line by line over the mapped buffer without copying everything to one big String.
        data.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
            guard let base = buf.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            let count = buf.count
            var lineStart = 0
            var i = 0
            while i < count {
                if base[i] == 0x0A { // '\n'
                    let lineLen = i - lineStart
                    if lineLen > 0 {
                        let lineData = Data(bytes: base + lineStart, count: lineLen)
                        if let line = String(data: lineData, encoding: .utf8) {
                            if let (key, entry) = parseLine(line) {
                                result[key] = entry
                            }
                        }
                    }
                    lineStart = i + 1
                }
                i += 1
            }
            // Trailing line without newline
            if lineStart < count {
                let lineData = Data(bytes: base + lineStart, count: count - lineStart)
                if let line = String(data: lineData, encoding: .utf8),
                   let (key, entry) = parseLine(line) {
                    result[key] = entry
                }
            }
        }
        return result
    }

    private static func parseLine(_ line: String) -> (String, Entry)? {
        let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        let word = String(parts[0])
        let phonetic = String(parts[1])
        let translation = String(parts[2])
        let senses = parseTranslation(translation)
        guard !senses.isEmpty else { return nil }
        return (word, Entry(phonetic: phonetic, senses: senses))
    }

    /// Splits ECDICT translation field on literal `\n` (backslash-n, two chars) and detects POS prefix.
    static func parseTranslation(_ raw: String) -> [WordSense] {
        // Replace literal "\n" sequences with a real delimiter, then split.
        // We avoid using the actual newline character because the source file already collapsed those.
        let delim = "\u{1F}" // unit separator unlikely to appear naturally
        let normalized = raw.replacingOccurrences(of: "\\n", with: delim)
        var senses: [WordSense] = []
        for chunk in normalized.split(separator: Character(delim)) {
            let trimmed = chunk.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if let s = extractSense(from: trimmed) {
                senses.append(s)
            }
        }
        return senses
    }

    /// Detect POS token like "n.", "vt.", "[网络]" at start of line; the rest is the meaning text.
    private static func extractSense(from line: String) -> WordSense? {
        // Skip bracket-tagged domain entries like "[网络] xxx" / "[经] xxx"
        if line.hasPrefix("[") { return nil }
        // Try to read short POS prefix: lowercase letters then a period, length 1-5 chars
        let scalars = Array(line)
        var i = 0
        while i < scalars.count && i < 6 {
            let c = scalars[i]
            if c == "." {
                let pos = String(scalars[0...i]).lowercased()
                let rest = String(scalars[(i + 1)...]).trimmingCharacters(in: .whitespaces)
                if rest.isEmpty { return nil }
                if knownPOS.contains(pos) {
                    return WordSense(pos: pos, meaning: rest)
                }
                // Unknown short token like "abbr." — keep as-is if it ends in '.' and is alphabetic
                if pos.allSatisfy({ $0.isLetter || $0 == "." }) {
                    return WordSense(pos: pos, meaning: rest)
                }
                break
            }
            if !c.isLetter { break }
            i += 1
        }
        // No POS prefix detected — treat whole line as "other"
        return WordSense(pos: "—", meaning: line)
    }

    private static let knownPOS: Set<String> = [
        "n.", "v.", "vt.", "vi.", "adj.", "a.", "adv.", "ad.",
        "prep.", "conj.", "pron.", "art.", "num.", "interj.", "int.",
        "aux.", "abbr.", "pl."
    ]
}
