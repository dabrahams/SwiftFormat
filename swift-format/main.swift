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

struct SourceLoc {
    var line = 0
    var column = 0

    mutating func traverse(_ text: String) {
        for c in text.utf16 {
            switch c {
            case 0xb, 0xc: line += 1// vertical linefeed, formfeed
            case "\n".utf16.first: line += 1; column = 0
            case "\r".utf16.first: column = 0
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

struct Token {
    let syntax: TokenSyntax
    let location: SourceLoc
    let ancestors: [Node]
}

enum Structure {
case indent
case dedent
case token(syntax: TokenSyntax, location: SourceLoc, ancestors: [Node])
}

typealias SyntaxID = Int

extension Syntax where Self : Hashable {
    var id: SyntaxID { return hashValue }
}

final class Reparser : SyntaxVisitor {
    var content: [Structure] = []
    var inputLocation = SourceLoc()
    var ancestors: [Node] = []
    typealias Actions = [SyntaxID : Int8]
    var before = Actions()
    var after = Actions()

    func takeActions<T : Syntax & Hashable>(_ a: inout Actions, for s: T) {
        if var delta = a.removeValue(forKey: s.id) {
            while delta > 0 {
                content.append(.indent)
                delta -= 1
            }
            while delta < 0 {
                delta += 1
                content.append(.dedent)
            }
        }
    }

    func visitChildren<T : Syntax & Hashable, R>(
        _ node: T, _ body: ()->R
    ) -> R {
        takeActions(&before, for: node)
        ancestors.append(Node(node))
        let r = body()
        ancestors.removeLast()
        takeActions(&after, for: node)
        return r
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
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
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
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FloatLiteralExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleExprSyntax) {
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayExprSyntax) {
        after[node.leftSquare.id] = 1
        before[node.rightSquare.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryExprSyntax) {
        after[node.leftSquare.id] = 1
        before[node.rightSquare.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImplicitMemberExprSyntax) {
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
        before[node.dot.id] = 1
        let top = ancestors.last!
        let closer = top.syntax is SwiftSyntax.FunctionCallExprSyntax
            ? top.id : node.id
        after[closer] = -1

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
        after[node.leftSquare.id] = 1
        before[node.rightSquare.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureParamSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureSignatureSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureExprSyntax) {
        after[node.signature.map { $0.id } ?? node.leftBrace.id] = 1
        before[node.rightBrace.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnresolvedPatternExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionCallExprSyntax) {
        if let l = node.leftParen, let r = node.rightParen {
            after[l.id] = 1
            before[r.id] = -1
        }
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SubscriptExprSyntax) {
        after[node.leftBracket.id] = 1
        before[node.rightBracket.id] = -1
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
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
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
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.EditorPlaceholderExprSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjectLiteralExprSyntax) {
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeInitializerClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypealiasDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ParameterClauseSyntax) {
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ReturnClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionSignatureSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseifDirectiveClauseSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IfConfigDeclSyntax) {
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
        after[node.leftBrace.id] = 1
        before[node.rightBrace.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SourceFileSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TopLevelCodeDeclSyntax) {
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
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessLevelModifierSyntax) {
        if let l = node.openParen, let r = node.closeParen {
            after[l.id] = 1
            before[r.id] = -1
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
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorDeclSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorBlockSyntax) {
        after[node.leftBrace.id] = 1
        before[node.rightBrace.id] = -1
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
        after[node.openBrace.id] = 1
        before[node.closeBrace.id] = -1
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
        after[node.leftAngleBracket.id] = 1
        before[node.rightAngleBracket.id] = -1
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
        after[node.leftSquareBracket.id] = 1
        before[node.rightSquareBracket.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryTypeSyntax) {
        after[node.leftSquareBracket.id] = 1
        before[node.rightSquareBracket.id] = -1
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
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionTypeSyntax) {
        after[node.leftParen.id] = 1
        before[node.rightParen.id] = -1
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AttributedTypeSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentSyntax) {
        visitChildren(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentClauseSyntax) {
        after[node.leftAngleBracket.id] = 1
        before[node.rightAngleBracket.id] = -1
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
        after[node.openParen.id] = 1
        before[node.closeParen.id] = -1
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
        takeActions(&before, for: tok)

        switch tok.tokenKind {
        case .rightParen, .rightBrace, .rightSquareBracket, .rightAngle:
            if ancestors.last!.syntax is UnknownStmtSyntax {
                content.append(.dedent)
            }
        default: break
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
            if ancestors.last!.syntax is UnknownStmtSyntax {
                content.append(.indent)
            }
        default: break
        }

        takeActions(&after, for: tok)
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

var indentation = 0
for x in p.content {
    switch x {
    case .indent: indentation += 1
    case .dedent: indentation -= 1
    case .token(let t, _, let ancestors):
        _ = ancestors
        print(String(repeating: "    ", count: indentation), t.text/*, "\t\t", ancestors*/)
    }
    // print("\(#file)\(loc):,\t\(String(repeating: "    ", count: indentation)) '\(token)' \t\t -> \(ancestors)")
    // print(String(repeating: "    ", count: indentation), token)
}
