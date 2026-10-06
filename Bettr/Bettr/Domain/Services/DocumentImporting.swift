import Foundation
import UIKit

@MainActor
protocol TextRecognizing {
    func recognizeText(from image: UIImage, completion: @escaping (String) -> Void)
}

@MainActor
protocol PDFTextExtracting {
    func extractText(from url: URL) -> String?
}
