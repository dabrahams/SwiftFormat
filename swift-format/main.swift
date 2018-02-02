//
//  main.swift
//  swift-format
//
//  Created by Dave Abrahams on 2/1/18.
//  Copyright © 2018 Dave Abrahams. All rights reserved.
//

import Foundation
import SwiftSyntax

func genericFunc<T : Collection, U: Collection>(x: T, y: U) -> (T.Element?, U.Element?)
where T.Index == U.Index, U.Iterator == IndexingIterator<[Int]> {
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

    mutating func traverse(_ token: TokenSyntax) {
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
    init(_ kind: Syntax.Type) {
        self.kind = kind
    }

    init<T : Syntax>(_ node: T) {
        self.init(T.self)
    }

    let kind: Syntax.Type
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

final class Formatter : SyntaxVisitor {
    var tokens: [(String, location: SourceLoc, ancestors: [Node])] = []
    var inputLocation = SourceLoc()
    var indentation = 0
    var ancestors: [Node] = []

    override func visit(_ node: SwiftSyntax.UnknownDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.UnknownExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.UnknownStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.UnknownTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.UnknownPatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.InOutExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PoundColumnExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TryExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentsSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IdentifierExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SuperRefExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.NilLiteralExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DiscardAssignmentExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AssignmentExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SequenceExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PoundLineExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PoundFileExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PoundFunctionExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PoundDsohandleExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SymbolicReferenceExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PrefixOperatorExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.BinaryOperatorExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FloatLiteralExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TupleExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ArrayExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DictionaryExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ImplicitMemberExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FunctionCallArgumentSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TupleElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ArrayElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DictionaryElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IntegerLiteralExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.StringLiteralExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.BooleanLiteralExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TernaryExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.MemberAccessExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DotSelfExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IsExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AsExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TypeExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureItemSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureSignatureSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ClosureParamSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ClosureSignatureSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ClosureExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.UnresolvedPatternExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FunctionCallExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SubscriptExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.OptionalChainingExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ForcedValueExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PostfixUnaryExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.StringSegmentSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ExpressionSegmentSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.StringInterpolationExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.KeyPathExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ObjcNamePieceSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ObjcKeyPathExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.EditorPlaceholderExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ObjectLiteralExprSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TypeInitializerClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TypealiasDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ParameterClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ReturnClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FunctionSignatureSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ElseifDirectiveClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IfConfigDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DeclModifierSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.InheritedTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TypeInheritanceClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ClassDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.StructDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ProtocolDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ExtensionDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.MemberDeclBlockSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SourceFileSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TopLevelCodeDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.InitializerClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FunctionParameterSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FunctionDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ElseDirectiveClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AccessLevelModifierSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AccessPathComponentSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ImportDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AccessorParameterSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AccessorDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AccessorBlockSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.PatternBindingSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.VariableDeclSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AttributeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ContinueStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.WhileStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DeferStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ExpressionStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.RepeatWhileStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.GuardStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.WhereClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ForInStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SwitchStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DoStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ReturnStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FallthroughStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.BreakStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.CodeBlockSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ConditionElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AvailabilityConditionSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.MatchingPatternConditionSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.OptionalBindingConditionSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DeclarationStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ThrowStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IfStmtSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ElseIfContinuationSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ElseBlockSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SwitchDefaultLabelSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.CaseItemSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseLabelSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.CatchClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.GenericWhereClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SameTypeRequirementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.GenericParameterSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.GenericParameterClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ConformanceRequirementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.SimpleTypeIdentifierSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.MemberTypeIdentifierSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ArrayTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.DictionaryTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.MetatypeTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.OptionalTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ImplicitlyUnwrappedOptionalTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TupleTypeElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TupleTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.FunctionTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AttributedTypeSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentClauseSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TypeAnnotationSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.EnumCasePatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IsTypePatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.OptionalPatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.IdentifierPatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.AsTypePatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TuplePatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.WildcardPatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.TuplePatternElementSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ExpressionPatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ node: SwiftSyntax.ValueBindingPatternSyntax) {
        ancestors.append(Node(node))
        super.visit(node)
        ancestors.removeLast()
    }

    override func visit(_ token: TokenSyntax) {
        for t in token.leadingTrivia {
            inputLocation.traverse(t)
        }

        tokens.append(
            (
                token.text,
                location: inputLocation,
                ancestors: ancestors
            ))

        inputLocation.traverse(token)
        for t in token.trailingTrivia {
            inputLocation.traverse(t)
        }

        return super.visit(token)
    }
}

// Parse a .swift file
let currentFile = URL(fileURLWithPath: #file)
let currentFileContents = try String(contentsOf: currentFile)
let parsed = try SourceFileSyntax.parse(currentFile)
let f = Formatter()
f.visit(parsed)
for (text, loc, ancestors) in f.tokens {
    print("\(#file)\(loc):, '\(text)' -> \(ancestors)")
}
