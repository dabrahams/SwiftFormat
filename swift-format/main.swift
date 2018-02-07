//
//  main.swift
//  swift-format
//
//  Created by Dave Abrahams on 2/1/18.
//  Copyright © 2018 Dave Abrahams. All rights reserved.
//

import Foundation
import SwiftSyntax

struct X {
    func fubar() -> X { return self }
    var myself: X { return self }
}

func genericFunc<T : Collection, U: Collection>(x: T, y: U) -> (T.Element?, U.Element?)
where T.Index == U.Index, U.Iterator == IndexingIterator<[Int]> {
    _ = 3 * 4 + (5 * 6)
    _ = x.map { y->Int in 3 }
    _ = x.map { $0 }
    _ = X().fubar().fubar().fubar() // trailing comment
    _ = X().myself.myself
    _ = X().myself.fubar().myself.fubar()
    _ = X().fubar().myself.fubar().myself

    return (x.first, y.first)
}

func ascii16(_ x: UnicodeScalar) -> UTF16.CodeUnit {
    assert(x.isASCII)
    return UTF16.CodeUnit(x.value)
}

struct SourceLoc {
    var line = 0
    var column = 0

    mutating func traverse(_ text: String) {
        for c in text.utf16 {
            switch c {
            case 0xb, 0xc: line += 1// vertical linefeed, formfeed
            case ascii16("\n"): line += 1; column = 0
            case ascii16("\r"): column = 0
            default: column += 1
            }
        }
    }

    mutating func traverse(_ nonToken: TriviaPiece) {
        switch nonToken {
        case .spaces(let n), .tabs(let n), .backticks(let n):
            column += n

        case .verticalTabs(let n), .formfeeds(let n):
            line += n

        case .newlines(let n), .carriageReturnLineFeeds(let n):
            line += n
            column = 0

        case .carriageReturns(_):
            column = 0

        case .lineComment(let s),
            .blockComment(let s),
            .docLineComment(let s),
            .docBlockComment(let s),
            .garbageText(let s):

            traverse(s)
        }
    }

    mutating func traverseNonTrivia(_ token: TokenSyntax) {
        // DWA FIXME: this could be sped up by knowing the length of more tokens
        switch token.tokenKind {
        case .atSign,
            .colon,
            .semicolon,
            .comma,
            .period,
            .equal,
            .prefixPeriod,
            .leftParen,
            .rightParen,
            .leftBrace,
            .rightBrace,
            .leftSquareBracket,
            .rightSquareBracket,
            .leftAngle,
            .rightAngle,
            .prefixAmpersand,
            .postfixQuestionMark,
            .infixQuestionMark,
            .exclamationMark,
            .backslash,
            .stringQuote:
            column += 1
        case .arrow:
            column += 2
        default: traverse(token.text)
        }
    }
}

extension SourceLoc : CustomStringConvertible {
    var description: String {
        return ":\(line + 1):\(column + 1)"
    }
}

extension SourceLoc : CustomDebugStringConvertible {
    var debugDescription: String {
        return "SourceLoc(line: \(line): column: \(column))"
    }
}

struct Node {
    init<T : Syntax & Hashable>(_ x: T) {
        syntax = x
        id = x.id
    }

    var kind: Syntax.Type {
        return type(of: syntax)
    }

    let syntax: Syntax
    let id: Int
}

extension Node : Equatable {
    static func == (x: Node, y: Node) -> Bool {
        return x.id == y.id
    }
}

extension BidirectionalCollection where Element : Equatable {
    func ends<S : BidirectionalCollection>(with s: S) -> Bool
    where S.Element == Self.Element
    {
        return self.reversed().starts(with: s.reversed())
    }

    func droppingSuffix<S : BidirectionalCollection>(_ s: S) -> SubSequence
    where S.Element == Self.Element
    {
        return self.ends(with: s) ? self.dropLast(s.count) : self[...]
    }
}

extension Node : CustomStringConvertible {
    var description: String {
        let syntaxCodeUnits = "Syntax".utf16
        let typeName = "\(kind)".utf16.split(separator: ".".utf16.first!).last!
        return String(typeName.droppingSuffix(syntaxCodeUnits))!
    }
}

extension TokenSyntax {
    /// True iff `self` might be mis-tokenized if placed next to an 'a' with no
    /// intervening whitespace.
    var isIdentifierLike: Bool {
        // DWA FIXME: This might be optimized by knowing more token kinds...
        if case .identifier(_) = tokenKind { return true }

        // ...but we should retain this fallback for resilience as the language
        // evolves.

        func isKnownIdentifierCodeUnit(_ c: UTF16.CodeUnit) -> Bool {
            switch c {
            case ascii16("_"),
                ascii16("a")...ascii16("z"),
                ascii16("A")...ascii16("Z"),
                ascii16("0")...ascii16("9"): return true
            default: return false
            }
        }

        let codeUnits = text.utf16

        if let first = codeUnits.first {
            if isKnownIdentifierCodeUnit(first) { return true }
        }
        if let last = codeUnits.last {
            if isKnownIdentifierCodeUnit(last) { return true }
        }
        return false
    }
}

struct Token {
    let syntax: TokenSyntax
    let location: SourceLoc
    let ancestors: [Node]
}

struct Injection {
    var whitespaceRequired: Bool = false
    var newlineRequired: Bool = false
    var closeGroups: Int16 = 0
    var openGroups: Int16 = 0
}

enum OutputElement {
case openGroup
case closeGroup(matchingOpenIndex: Int)
case whitespace
case newline
case token(syntax: TokenSyntax, location: SourceLoc, ancestors: [Node])
}

typealias SyntaxID = Int

extension Syntax where Self : Hashable {
    var id: SyntaxID { return hashValue }
}

protocol _StmtSyntax : StmtSyntax {
    var semicolon: SwiftSyntax.TokenSyntax? { get }
    var id: Int { get }
}
extension BreakStmtSyntax : _StmtSyntax {}
extension ContinueStmtSyntax : _StmtSyntax {}
extension DeclarationStmtSyntax : _StmtSyntax {}
extension DeferStmtSyntax : _StmtSyntax {}
extension DoStmtSyntax : _StmtSyntax {}
extension ExpressionStmtSyntax : _StmtSyntax {}
extension FallthroughStmtSyntax : _StmtSyntax {}
extension ForInStmtSyntax : _StmtSyntax {}
extension GuardStmtSyntax : _StmtSyntax {}
extension IfStmtSyntax : _StmtSyntax {}
extension RepeatWhileStmtSyntax : _StmtSyntax {}
extension ReturnStmtSyntax : _StmtSyntax {}
extension SwitchStmtSyntax : _StmtSyntax {}
extension ThrowStmtSyntax : _StmtSyntax {}
//extension UnknownStmtSyntax : _StmtSyntax {}
extension WhileStmtSyntax : _StmtSyntax {}

struct LazyDictionary<K : Hashable, V> {
    init(default: V) {
        defaultValue = { _ in `default` }
    }
    init(default: @escaping (K)->V) {
        defaultValue = `default`
    }

    subscript(key: K) -> V {
        get {
            return impl[key] ?? defaultValue(key)
        }
        set {
            impl[key] = newValue
        }
    }

    mutating func removeValue(forKey k: K) -> V? {
        return impl.removeValue(forKey: k)
    }

    var defaultValue: (K)->V
    var impl: [K : V] = [:]
}

final class Reparser : SyntaxVisitor {
    var content: [OutputElement] = []

    /// A stack of openGroup indices that have not yet been matched by a
    /// closeGroup.
    var unmatchedOpenGroups: [Int] = []

    var inputLocation = SourceLoc()
    var ancestors: [Node] = []
    var previousToken: TokenSyntax? = nil
    typealias Injections = LazyDictionary<SyntaxID, Injection>

    var before = Injections(default: Injection())
    var after = Injections(default: Injection())

    func openGroup() {
        unmatchedOpenGroups.append(content.count)
        content.append(.openGroup)
    }

    func closeGroup() {
        content.append(
            .closeGroup(matchingOpenIndex: unmatchedOpenGroups.removeLast()))
    }

    func apply<T : Syntax & Hashable>(_ a: inout Injections, to s: T) {
        if let i = a.removeValue(forKey: s.id) {
            for _ in 0..<i.closeGroups { closeGroup() }

            if i.newlineRequired { content.append(.newline) }
            else if i.whitespaceRequired { content.append(.whitespace) }

            for _ in 0..<i.openGroups { openGroup() }
        }
    }

    func visitChildren<T : Syntax & Hashable, R>(
        _ node: T, _ body: ()->R
    ) -> R {
        apply(&before, to: node)
        ancestors.append(Node(node))
        let r = body()
        ancestors.removeLast()
        apply(&after, to: node)
        return r
    }

    func injectMandatoryNewlines(in statements: StmtListSyntax) {
        for s in statements.dropLast() {
            if (s as? _StmtSyntax)?.semicolon != nil { continue }
            after[(s as! AnyHashable).hashValue].newlineRequired = true
        }
    }

    override func visit(_ node: SwiftSyntax.UnknownDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownPatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.InOutExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundColumnExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TryExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentsSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IdentifierExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SuperRefExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.NilLiteralExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DiscardAssignmentExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AssignmentExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SequenceExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundLineExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundFileExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundFunctionExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundDsohandleExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SymbolicReferenceExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PrefixOperatorExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.BinaryOperatorExprSyntax) {
        before[node.operatorToken.id].whitespaceRequired = true
        after[node.operatorToken.id].whitespaceRequired = true
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FloatLiteralExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleExprSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayExprSyntax) {
        after[node.leftSquare.id].openGroups += 1
        before[node.rightSquare.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryExprSyntax) {
        after[node.leftSquare.id].openGroups += 1
        before[node.rightSquare.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImplicitMemberExprSyntax) {
        before[node.id].whitespaceRequired = true
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionCallArgumentSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IntegerLiteralExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StringLiteralExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.BooleanLiteralExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TernaryExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MemberAccessExprSyntax) {
        before[node.dot.id].openGroups += 1
        let top = ancestors.last!
        let closer = top.syntax is SwiftSyntax.FunctionCallExprSyntax
            ? top.id : node.id
        after[closer].closeGroups += 1

        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DotSelfExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IsExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AsExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureItemSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureSignatureSyntax) {
        after[node.leftSquare.id].openGroups += 1
        before[node.rightSquare.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureParamSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureSignatureSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureExprSyntax) {
        injectMandatoryNewlines(in: node.statements)
        after[node.signature.map { $0.id } ?? node.leftBrace.id].openGroups += 1
        before[node.rightBrace.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnresolvedPatternExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionCallExprSyntax) {
        if let l = node.leftParen, let r = node.rightParen {
            after[l.id].openGroups += 1
            before[r.id].closeGroups += 1
        }
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SubscriptExprSyntax) {
        after[node.leftBracket.id].openGroups += 1
        before[node.rightBracket.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalChainingExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ForcedValueExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PostfixUnaryExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StringSegmentSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExpressionSegmentSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StringInterpolationExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.KeyPathExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjcNamePieceSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjcKeyPathExprSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.EditorPlaceholderExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjectLiteralExprSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeInitializerClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypealiasDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ParameterClauseSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ReturnClauseSyntax) {
        after[node.arrow.id].whitespaceRequired = true
        before[node.arrow.id].whitespaceRequired = true
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionSignatureSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseifDirectiveClauseSyntax) {
        injectMandatoryNewlines(in: node.body)
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IfConfigDeclSyntax) {
        injectMandatoryNewlines(in: node.body)
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclModifierSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.InheritedTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeInheritanceClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClassDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StructDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ProtocolDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExtensionDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MemberDeclBlockSyntax) {
        after[node.leftBrace.id].openGroups += 1
        before[node.rightBrace.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SourceFileSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TopLevelCodeDeclSyntax) {
        injectMandatoryNewlines(in: node.body)
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.InitializerClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionParameterSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseDirectiveClauseSyntax) {
        injectMandatoryNewlines(in: node.body)
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessLevelModifierSyntax) {
        if let l = node.openParen, let r = node.closeParen {
            after[l.id].openGroups += 1
            before[r.id].closeGroups += 1
        }
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessPathComponentSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImportDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorParameterSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorBlockSyntax) {
        after[node.leftBrace.id].openGroups += 1
        before[node.rightBrace.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PatternBindingSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.VariableDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AttributeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ContinueStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.WhileStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeferStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExpressionStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.RepeatWhileStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GuardStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.WhereClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ForInStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DoStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ReturnStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FallthroughStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.BreakStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CodeBlockSyntax) {
        injectMandatoryNewlines(in: node.statements)
        after[node.openBrace.id].openGroups += 1
        before[node.closeBrace.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ConditionElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AvailabilityConditionSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MatchingPatternConditionSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalBindingConditionSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclarationStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ThrowStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IfStmtSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseIfContinuationSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseBlockSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseSyntax) {
        injectMandatoryNewlines(in: node.body)
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchDefaultLabelSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CaseItemSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseLabelSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CatchClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericWhereClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SameTypeRequirementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericParameterSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericParameterClauseSyntax) {
        after[node.leftAngleBracket.id].openGroups += 1
        before[node.rightAngleBracket.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ConformanceRequirementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SimpleTypeIdentifierSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MemberTypeIdentifierSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayTypeSyntax) {
        after[node.leftSquareBracket.id].openGroups += 1
        before[node.rightSquareBracket.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryTypeSyntax) {
        after[node.leftSquareBracket.id].openGroups += 1
        before[node.rightSquareBracket.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MetatypeTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImplicitlyUnwrappedOptionalTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleTypeElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleTypeSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionTypeSyntax) {
        after[node.leftParen.id].openGroups += 1
        before[node.rightParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AttributedTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentClauseSyntax) {
        after[node.leftAngleBracket.id].openGroups += 1
        before[node.rightAngleBracket.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeAnnotationSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.EnumCasePatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IsTypePatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalPatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IdentifierPatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AsTypePatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TuplePatternSyntax) {
        after[node.openParen.id].openGroups += 1
        before[node.closeParen.id].closeGroups += 1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.WildcardPatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TuplePatternElementSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExpressionPatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ValueBindingPatternSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ tok: TokenSyntax) {
        apply(&before, to: tok)

        switch tok.tokenKind {
        case .rightParen, .rightBrace, .rightSquareBracket, .rightAngle:
            if ancestors.last!.syntax is UnknownStmtSyntax { closeGroup() }

        default: break
        }

        // Inject mandatory whitespace where we would otherwise create long
        // identifiers by jamming together things that should be separate.
        if let p = previousToken, p.isIdentifierLike, tok.isIdentifierLike {
            content.append(.whitespace)
        }

        for t in tok.leadingTrivia {
            inputLocation.traverse(t)
        }

        content.append(
            .token(
                syntax: tok,
                location: inputLocation,
                ancestors: ancestors
            )
        )

        inputLocation.traverseNonTrivia(tok)

        for t in tok.trailingTrivia {
            inputLocation.traverse(t)
        }

        switch tok.tokenKind {
        case .leftParen, .leftBrace, .leftSquareBracket, .leftAngle:
            if ancestors.last!.syntax is UnknownStmtSyntax { openGroup() }
        case .comma:
            content.append(.whitespace)
        default: break
        }

        apply(&after, to: tok)
        previousToken = tok
    }
}

let p = Reparser()

// Parse a .swift file
let currentFile = URL(fileURLWithPath: #file)
do {
    // let currentFileContents = try String(contentsOf: currentFile)
    let parsed = try SourceFileSyntax.parse(currentFile)
    p.visit(parsed)
} catch ParserError.swiftcFailed(let n, let message) {
    print(message)
    exit(n == 0 ? 1 : Int32(n))
}
catch {
    print(error)
    exit(1)
}

let indentSpaces = 4
let columnLimit = 70

/// For each currently-open group, the indentation level of the line on which it
/// starts.
var groupIndentLevels = [0]
var lineBuffer = [OutputElement]()
var lineWidth = 0
/// The indentation at the beginning of this line
var bolIndentation = 0
/// The group nesting level at beginning of this line
var bolGrouping = groupIndentLevels.count
var whitespaceRequired = false
var lineUnmatchedIndices: [Int] = []

func flushLineBuffer() {
    print("% lineBuffer:", lineBuffer)
    print("% lineUnmatchedIndices:", lineUnmatchedIndices)

    var b = String(repeating: " ", count: bolIndentation * indentSpaces)
    var grouping = bolGrouping

    // flush through the first unmatched open grouping delimiter
    let flushCount = lineUnmatchedIndices.first.map { $0 + 1 } ?? lineBuffer.count
    for x in lineBuffer[..<flushCount] {
        switch x {
        case .openGroup:
            groupIndentLevels.append(bolIndentation)
            grouping += 1
            // b += "〈"
        case .closeGroup:
            bolIndentation = groupIndentLevels.removeLast()
            grouping -= 1
            // b += "〉"
        case .whitespace:
            b += " "
        case .newline:
            break
        case .token(let t, _, _):
            b += t.text
        }
    }
    lineBuffer.removeFirst(flushCount)
    if !lineUnmatchedIndices.isEmpty {
        for i in 1..<lineUnmatchedIndices.count {
            lineUnmatchedIndices[i - 1] = lineUnmatchedIndices[i] - flushCount
        }
        lineUnmatchedIndices.removeLast()
    }

    print(b)
    if grouping > bolGrouping { bolIndentation += 1 }
    bolGrouping = grouping
    whitespaceRequired = false
    lineWidth = bolIndentation * indentSpaces
}

for x in p.content {
    switch x {
    case .openGroup:
        lineUnmatchedIndices.append(lineBuffer.count)
        lineBuffer.append(x)
    case .closeGroup:
        lineBuffer.append(x)
        if !lineUnmatchedIndices.isEmpty {
            lineUnmatchedIndices.removeLast()
        }
    case .whitespace:
        if !lineBuffer.isEmpty {
            whitespaceRequired = true
        }
    case .newline:
        flushLineBuffer()
    case .token(let t, _, _):
        let w = t.text.count + (whitespaceRequired ? 1 : 0)
        if lineWidth + w > columnLimit {
            flushLineBuffer()
        }
        else if whitespaceRequired {
            lineBuffer.append(.whitespace)
        }
        lineWidth += w
        lineBuffer.append(x)
        whitespaceRequired = false
   }
    // print("\(#file)\(loc):,\t\(String(repeating: "    ", count: indentation)) '\(token)' \t\t -> \(ancestors)")
    // print(String(repeating: "    ", count: indentation), token)
}
flushLineBuffer()
