

import Foundation
import NaturalLanguage

struct TaggedToken: Identifiable, Hashable {
    let id = UUID()
    let surface: String
    let lemma: String
    let pos: NLTag?
    let isNamedEntity: Bool
    let sentenceIndex: Int?
}

class NLTaggerService {
    // MARK: - 단어 원형 추출 및 품사 태깅
    static func tagAndExtract(from text: String) -> [TaggedToken] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let sentenceTokenizer = NLTokenizer(unit: .sentence)
        sentenceTokenizer.string = text
        var sentenceRanges: [Range<String.Index>] = []
        sentenceTokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            sentenceRanges.append(range)
            return true
        }

        let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass, .nameType])
        tagger.string = text
        tagger.setLanguage(.english, range: text.startIndex..<text.endIndex)

        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .omitOther, .joinContractions]
        var results: [TaggedToken] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .lexicalClass,
                             options: options) { pos, range in
            let surface = String(text[range])
            let (lemmaTag, _) = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma)
            let lemma = lemmaTag?.rawValue.lowercased() ?? surface.lowercased()
            let (nameTag, _) = tagger.tag(at: range.lowerBound, unit: .word, scheme: .nameType)
            let isNamed = (nameTag == .personalName || nameTag == .placeName || nameTag == .organizationName)
            let sIndex: Int? = sentenceRanges.firstIndex { $0.contains(range.lowerBound) }

            results.append(TaggedToken(
                surface: surface,
                lemma: lemma,
                pos: pos,
                isNamedEntity: isNamed,
                sentenceIndex: sIndex
            ))
            return true
        }
        return results
    }
    
    // MARK: - 한국어로 품사 매핑
    static func koreanPOS(from tag: NLTag?) -> String {
        guard let tag = tag else { return "기타" }
        switch tag {
        case .noun: return "명"
        case .verb: return "동"
        case .adjective: return "형"
        case .adverb: return "부"
        case .pronoun: return "대명"
        case .determiner: return "한정"
        case .preposition: return "전"
        case .conjunction: return "접"
        default: return tag.rawValue
        }
    }
    
    // MARK: - 외부 시스템용 라벨
    static func afmPOS(from tag: NLTag?) -> String {
        guard let tag = tag else { return "other" }
        switch tag {
        case .noun: return "noun"
        case .verb: return "verb"
        case .adjective: return "adjective"
        case .adverb: return "adverb"
        case .preposition: return "preposition"
        case .conjunction: return "conjunction"
        case .determiner: return "determiner"
        case .pronoun: return "pronoun"
        default: return "other"
        }
    }
}
