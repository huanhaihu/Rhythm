import Foundation

struct WordSense: Codable, Equatable, Hashable {
    var pos: String      // normalized: "n." / "v." / "adj." / "adv." / "prep." / "conj." / ...
    var meaning: String  // Chinese meaning text

    enum Group: String {
        case noun, verb, other
    }

    var group: Group {
        switch pos {
        case "n.", "pron.": return .noun
        case "v.", "vt.", "vi.", "aux.": return .verb
        default: return .other
        }
    }

    var displayPOS: String {
        // Collapse vt./vi. into v. for display brevity
        switch pos {
        case "vt.", "vi.": return "v."
        default: return pos
        }
    }
}
