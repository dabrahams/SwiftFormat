//
//  main.swift
//  swift-format
//
//  Created by Dave Abrahams on 2/1/18.
//  Copyright © 2018 Dave Abrahams. All rights reserved.
//

import Foundation
import SwiftSyntax

class Rewriter: SyntaxRewriter {
  var tokens: [(String, line: Int, column: Int)] = []
  var line = 0
  var column = 0

  func updateSourceLocation(for text: String) {
    for c in text.utf16 {
      switch c {
      case 0xb, 0xc: line += 1// vertical linefeed, formfeed
      case "\n".utf16.first: line += 1; column = 0
      case "\r".utf16.first: column = 0
      default: column += 1
      }
    }
  }
  
  func updateSourceLocation(for nonToken: TriviaPiece) {
    
    switch nonToken {
    /// A space ' ' character.
    case .spaces(let n): column += n

    /// A tab '\t' character.
    case .tabs(let n): column += n

    /// A vertical tab '\v' character.
    case .verticalTabs(let n): line += n

    /// A form-feed '\f' character.
    case .formfeeds(let n): line += n

    /// A newline '\n' character.
    case .newlines(let n): line += n; column = 0

    /// A carriage-return '\r' character.
    case .carriageReturns(_): column = 0

    /// A newline two bytes sequence consists of '\r' and '\n' characters.
    case .carriageReturnLineFeeds(let n): line += n; column = 0

    /// A backtick '`' character, used to escape identifiers.
    case .backticks(let n): column += n

    /// A developer line comment, starting with '//'
    case .lineComment(let s): updateSourceLocation(for: s)

    /// A developer block comment, starting with '/*' and ending with '*/'.
    case .blockComment(let s): updateSourceLocation(for: s)

    /// A documentation line comment, starting with '///'.
    case .docLineComment(let s): updateSourceLocation(for: s)

    /// A documentation block comment, starting with '/**' and ending with '*/.
    case .docBlockComment(let s): updateSourceLocation(for: s)

    /// Any skipped text.
    case .garbageText(For: let s):
      updateSourceLocation(for: s)
    }
  }
    
  override func visit(_ token: TokenSyntax) -> Syntax {
    for t in token.leadingTrivia { updateSourceLocation(for: t) }    
    tokens.append((token.text, line: line, column: column))
    updateSourceLocation(for: token.text)
    for t in token.trailingTrivia { updateSourceLocation(for: t) }
    
    return super.visit(token)
  }
}

// Parse a .swift file
let currentFile = URL(fileURLWithPath: #file)
let currentFileContents = try String(contentsOf: currentFile)
let parsed = try SourceFileSyntax.parse(currentFile)
let r = Rewriter()
_ = r.visit(parsed)
print(r.tokens)
