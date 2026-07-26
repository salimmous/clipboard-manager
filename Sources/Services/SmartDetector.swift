import Foundation
import AppKit

class SmartDetector {
    static func detectEntities(in text: String) -> [DetectedEntity] {
        var entities: [DetectedEntity] = []
        
        // Email detection
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if let emailRegex = try? NSRegularExpression(pattern: emailPattern) {
            let matches = emailRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let email = String(text[range])
                    entities.append(DetectedEntity(type: .email, value: email, range: "\(match.range.location)-\(match.range.length)"))
                }
            }
        }
        
        // Phone number detection (various formats)
        let phonePatterns = [
            "\\+?\\d{1,3}[-.\\s]?\\(?\\d{1,4}\\)?[-.\\s]?\\d{1,4}[-.\\s]?\\d{1,9}", // International
            "\\(\\d{3}\\)\\s?\\d{3}-\\d{4}", // (123) 456-7890
            "\\d{3}-\\d{3}-\\d{4}", // 123-456-7890
            "\\d{10}" // 1234567890
        ]
        
        for pattern in phonePatterns {
            if let phoneRegex = try? NSRegularExpression(pattern: pattern) {
                let matches = phoneRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let phone = String(text[range])
                        let digits = phone.filter { $0.isNumber }
                        if digits.count >= 10 {
                            entities.append(DetectedEntity(type: .phone, value: phone, range: "\(match.range.location)-\(match.range.length)"))
                        }
                    }
                }
            }
        }
        
        // Address detection (simplified - looks for street patterns)
        let addressPattern = "\\d+\\s+[A-Za-z0-9\\s,]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Lane|Ln|Drive|Dr|Court|Ct|Circle|Cir|Way)"
        if let addressRegex = try? NSRegularExpression(pattern: addressPattern, options: .caseInsensitive) {
            let matches = addressRegex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    let address = String(text[range])
                    entities.append(DetectedEntity(type: .address, value: address, range: "\(match.range.location)-\(match.range.length)"))
                }
            }
        }
        
        return entities
    }
    
    static func performAction(for entity: DetectedEntity) {
        switch entity.type {
        case .email:
            if let url = URL(string: "mailto:\(entity.value)") {
                NSWorkspace.shared.open(url)
            }
        case .phone:
            let cleanPhone = entity.value.filter { $0.isNumber || $0 == "+" }
            if let url = URL(string: "tel:\(cleanPhone)") {
                NSWorkspace.shared.open(url)
            }
        case .address:
            let encodedAddress = entity.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "http://maps.apple.com/?q=\(encodedAddress)") {
                NSWorkspace.shared.open(url)
            }
        case .none:
            break
        }
    }
}
