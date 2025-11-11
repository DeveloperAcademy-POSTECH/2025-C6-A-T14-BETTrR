import SwiftUI

// MARK: - WordListContentView (단어 목록 스크롤 뷰)
struct WordListContentView: View {
    @Binding var words: [Word]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                    WordRow(word: word)
                    
                    if index != words.count - 1 {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.primaryBlue50)
                    }
                    
                }
                .padding(.leading, 36)
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - WordRow (개별 단어 항목)
private struct WordRow: View {
    let word: Word
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title + POS badge
            HStack(alignment: .center, spacing: 8) {
                Text(word.lemma)
                    .font(.subbodyBold24)
                    .foregroundStyle(.normalBlack900)
                    .padding(.trailing, 4)
                // POS capsule badge (한글 축약은 상위 레이어에서 처리되어 있다고 가정)
                Text(word.pos)
                    .font(.footerRegular11)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.primaryBlue500, lineWidth: 1)
                            )
                    )
                    .foregroundStyle(.primaryBlue500)
                Spacer(minLength: 0)
            }
            
            if !word.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let parts = parseMeaning(word.meaning)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(parts, id: \.self) { item in
                        Text(item)
                            .font(.labelRegular14)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
    }
    // MARK: - 단어의 문자열을 받아서 깔끔한 배열로 만들어주는 역할
    private func parseMeaning(_ meaning: String) -> [String] {
        meaning
            .components(separatedBy: .newlines)
            .flatMap { $0.components(separatedBy: " / ") }
            .flatMap { $0.components(separatedBy: "; ") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
