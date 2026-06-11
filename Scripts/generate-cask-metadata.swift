#!/usr/bin/env swift

import Foundation

struct Cask: Decodable {
    let token: String
    let name: [String]
    let desc: String?
    let homepage: String
    let url: String
}

struct Metadata: Codable {
    let summary: String
    let homepage: String
    let downloadURL: String
}

func normalized(_ value: String) -> String {
    value
        .folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "en_US_POSIX")
        )
        .lowercased()
        .filter { $0.isLetter || $0.isNumber }
}

func displayName(_ fileName: String) -> String {
    let stem = (fileName as NSString).deletingPathExtension
    let patterns = [
        #"(?i)[\s_-]+v?\d+\.\d+(?:\.\d+){0,2}.*$"#,
        #"(?i)[\s_-]+\d{4}(?:[\s_-].*)?$"#,
        #"(?i)[\s_-]+(?:macos|mac|installer|universal|arm64|x64).*$"#
    ]
    let stripped = patterns.reduce(stem) { result, pattern in
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }
        return regex.stringByReplacingMatches(
            in: result,
            range: NSRange(result.startIndex..., in: result),
            withTemplate: ""
        )
    }
    return stripped
        .replacingOccurrences(of: "_", with: " ")
        .replacingOccurrences(of: "-", with: " ")
        .split(whereSeparator: \.isWhitespace)
        .map(String.init)
        .joined(separator: " ")
}

guard CommandLine.arguments.count == 4 else {
    fputs(
        "Usage: generate-cask-metadata.swift CASK_JSON TSV OUTPUT_JSON\n",
        stderr
    )
    exit(2)
}

let caskURL = URL(fileURLWithPath: CommandLine.arguments[1])
let tsvURL = URL(fileURLWithPath: CommandLine.arguments[2])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])

let casks = try JSONDecoder().decode(
    [Cask].self,
    from: Data(contentsOf: caskURL)
)
let tsv = try String(contentsOf: tsvURL, encoding: .utf8)
let appNames = Set(
    tsv.split(whereSeparator: \.isNewline)
        .dropFirst()
        .compactMap { line -> String? in
            guard let fileName = line.split(
                separator: "\t",
                omittingEmptySubsequences: false
            ).first else {
                return nil
            }
            return displayName(String(fileName))
        }
)

var index: [String: [Cask]] = [:]
for cask in casks {
    let aliases = Set(cask.name.map(normalized) + [normalized(cask.token)])
    for alias in aliases where !alias.isEmpty {
        index[alias, default: []].append(cask)
    }
}

var result: [String: Metadata] = [:]
for appName in appNames {
    let key = normalized(appName)
    guard let matches = index[key], matches.count == 1,
          let cask = matches.first,
          let description = cask.desc?.trimmingCharacters(
            in: .whitespacesAndNewlines
          ),
          !description.isEmpty
    else {
        continue
    }
    result[key] = Metadata(
        summary: description,
        homepage: cask.homepage,
        downloadURL: cask.url
    )
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
var data = try encoder.encode(result)
data.append(0x0A)
try data.write(to: outputURL, options: .atomic)
print("Generated \(result.count) unambiguous metadata records.")
