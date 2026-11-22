import Foundation
import AppKit

public final class SmartDetector {
    private static let emailRegex = try? NSRegularExpression(
        pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    )

    private static let phoneRegexes: [NSRegularExpression] = [
        "\\+\\d{1,3}[-.\\s]?\\(?\\d{1,4}\\)?[-.\\s]?\\d{2,4}[-.\\s]?\\d{2,5}(?:[-.\\s]?\\d{2,4})?",
        "\\(\\d{3}\\)\\s?\\d{3}[-.\\s]?\\d{4}",
        "\\b\\d{3}[-.\\s]\\d{3}[-.\\s]\\d{4}\\b"
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    private static let addressRegex = try? NSRegularExpression(
        pattern: "\\b\\d{1,6}\\s+[A-Za-z0-9\\s.,'-]+?\\s+(?:Street|St\\.?|Avenue|Ave\\.?|Road|Rd\\.?|Boulevard|Blvd\\.?|Lane|Ln\\.?|Drive|Dr\\.?|Court|Ct\\.?|Circle|Cir\\.?|Way|Place|Pl\\.?)\\b",
        options: .caseInsensitive
    )

    private static let hexColorRegex = try? NSRegularExpression(
        pattern: "#(?:[0-9A-Fa-f]{8}|[0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})\\b"
    )

    private static let linkDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    /// Validates whether a string is a standalone URL (supports modern TLDs like .io, .dev, .ai, .ma, localhost).
    public static func isValidURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              !trimmed.contains("@") || trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else {
            return false
        }

        let lower = trimmed.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            guard let components = URLComponents(string: trimmed),
                  let host = components.host,
                  !host.isEmpty else {
                return false
            }
            return host == "localhost" || host.contains(".")
        }

        guard let detector = linkDetector else { return false }
        let nsRange = NSRange(trimmed.startIndex..., in: trimmed)
        let matches = detector.matches(in: trimmed, options: [], range: nsRange)
        guard let match = matches.first,
              match.range.location == 0,
              match.range.length == nsRange.length,
              let url = match.url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host,
              host.contains(".") else {
            return false
        }

        return true
    }

    /// Parses exact hex strings `#RGB`, `#RRGGBB`, or `#RRGGBBAA`.
    public static func parseHexColor(_ string: String) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#") else { return nil }
        let hex = String(trimmed.dropFirst())
        guard hex.allSatisfy({ $0.isHexDigit }) else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }

        switch hex.count {
        case 3:
            let r = CGFloat((value & 0xF00) >> 8) / 15.0
            let g = CGFloat((value & 0x0F0) >> 4) / 15.0
            let b = CGFloat(value & 0x00F) / 15.0
            return (r, g, b, 1.0)
        case 6:
            let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(value & 0x0000FF) / 255.0
            return (r, g, b, 1.0)
        case 8:
            let r = CGFloat((value & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(value & 0x000000FF) / 255.0
            return (r, g, b, a)
        default:
            return nil
        }
    }

    public static func detectEntities(in text: String) -> [DetectedEntity] {
        guard !text.isEmpty, text.count <= 20_000 else { return [] }

        var entities: [DetectedEntity] = []
        var occupiedRanges: [NSRange] = []
        let fullRange = NSRange(text.startIndex..., in: text)

        // 1. Emails
        if let regex = emailRegex {
            var seenEmails = Set<String>()
            for match in regex.matches(in: text, range: fullRange) {
                guard let range = Range(match.range, in: text) else { continue }
                let email = String(text[range])
                if seenEmails.insert(email.lowercased()).inserted {
                    entities.append(DetectedEntity(type: .email, value: email, range: "\(match.range.location)-\(match.range.length)"))
                    occupiedRanges.append(match.range)
                }
            }
        }

        // 2. Phones (deduplicated across patterns & overlapping ranges)
        var seenPhoneDigits = Set<String>()
        for regex in phoneRegexes {
            for match in regex.matches(in: text, range: fullRange) {
                if occupiedRanges.contains(where: { NSIntersectionRange($0, match.range).length > 0 }) {
                    continue
                }
                guard let range = Range(match.range, in: text) else { continue }
                let phone = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                let digits = phone.filter { $0.isNumber }
                guard (10...15).contains(digits.count), seenPhoneDigits.insert(digits).inserted else { continue }
                entities.append(DetectedEntity(type: .phone, value: phone, range: "\(match.range.location)-\(match.range.length)"))
                occupiedRanges.append(match.range)
            }
        }

        // 3. Street Addresses
        if let regex = addressRegex {
            var seenAddresses = Set<String>()
            for match in regex.matches(in: text, range: fullRange) {
                guard let range = Range(match.range, in: text) else { continue }
                let address = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if seenAddresses.insert(address.lowercased()).inserted {
                    entities.append(DetectedEntity(type: .address, value: address, range: "\(match.range.location)-\(match.range.length)"))
                }
            }
        }

        // 4. Hex Colors
        if let regex = hexColorRegex {
            var seenColors = Set<String>()
            for match in regex.matches(in: text, range: fullRange) {
                guard let range = Range(match.range, in: text) else { continue }
                let hex = String(text[range])
                if seenColors.insert(hex.uppercased()).inserted {
                    entities.append(DetectedEntity(type: .color, value: hex, range: "\(match.range.location)-\(match.range.length)"))
                }
            }
        }

        return entities
    }

    public static func performAction(for entity: DetectedEntity) {
        switch entity.type {
        case .email:
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = entity.value
            if let url = components.url {
                NSWorkspace.shared.open(url)
            }
        case .phone:
            let cleanPhone = entity.value.filter { $0.isNumber || $0 == "+" }
            if let url = URL(string: "tel:\(cleanPhone)") {
                NSWorkspace.shared.open(url)
            }
        case .address:
            var components = URLComponents(string: "https://maps.apple.com/")
            components?.queryItems = [URLQueryItem(name: "q", value: entity.value)]
            if let url = components?.url {
                NSWorkspace.shared.open(url)
            }
        case .color:
            ClipboardManager.shared.copyPlainTextToClipboard(entity.value)
        case .none:
            break
        }
    }
}
