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
    var tokens: [(String, location: SourceLoc, indentation: Int, ancestors: [Node])] = []
    var inputLocation = SourceLoc()
    var indentation = 0
    var ancestors: [Node] = []

    func withSyntacticContext<T : Syntax, R>(
        _ node: T, indent: Bool = true, _ body: ()->R
    ) -> R {
        ancestors.append(Node(node))
        indentation += indent ? 1 : 0
        let r = body()
        indentation -= indent ? 1 : 0
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.UnknownDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }

    }

    override func visit(_ node: SwiftSyntax.UnknownExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnknownPatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.InOutExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundColumnExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TryExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentsSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IdentifierExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SuperRefExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.NilLiteralExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DiscardAssignmentExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AssignmentExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SequenceExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundLineExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundFileExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundFunctionExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PoundDsohandleExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SymbolicReferenceExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PrefixOperatorExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.BinaryOperatorExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FloatLiteralExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImplicitMemberExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionCallArgumentSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IntegerLiteralExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StringLiteralExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.BooleanLiteralExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TernaryExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MemberAccessExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DotSelfExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IsExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AsExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureItemSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureSignatureSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureParamSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureSignatureSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClosureExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.UnresolvedPatternExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionCallExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SubscriptExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalChainingExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ForcedValueExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PostfixUnaryExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StringSegmentSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExpressionSegmentSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StringInterpolationExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.KeyPathExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjcNamePieceSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjcKeyPathExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.EditorPlaceholderExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ObjectLiteralExprSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeInitializerClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypealiasDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ParameterClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ReturnClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionSignatureSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseifDirectiveClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IfConfigDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclModifierSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.InheritedTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeInheritanceClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ClassDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.StructDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ProtocolDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExtensionDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MemberDeclBlockSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SourceFileSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TopLevelCodeDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.InitializerClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionParameterSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseDirectiveClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessLevelModifierSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessPathComponentSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImportDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorParameterSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AccessorBlockSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.PatternBindingSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.VariableDeclSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AttributeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ContinueStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.WhileStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeferStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExpressionStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.RepeatWhileStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GuardStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.WhereClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ForInStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DoStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ReturnStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FallthroughStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.BreakStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CodeBlockSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ConditionElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AvailabilityConditionSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MatchingPatternConditionSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalBindingConditionSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DeclarationStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ThrowStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IfStmtSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseIfContinuationSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ElseBlockSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchDefaultLabelSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CaseItemSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseLabelSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CatchClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericWhereClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SameTypeRequirementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericParameterSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericParameterClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ConformanceRequirementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.SimpleTypeIdentifierSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MemberTypeIdentifierSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ArrayTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.DictionaryTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.MetatypeTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ImplicitlyUnwrappedOptionalTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleTypeElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TupleTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.FunctionTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AttributedTypeSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentClauseSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TypeAnnotationSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.EnumCasePatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IsTypePatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.OptionalPatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.IdentifierPatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.AsTypePatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TuplePatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.WildcardPatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.TuplePatternElementSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ExpressionPatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ node: SwiftSyntax.ValueBindingPatternSyntax) {
        withSyntacticContext(node) { super.visit(node) }
    }

    override func visit(_ token: TokenSyntax) {
        for t in token.leadingTrivia {
            inputLocation.traverse(t)
        }

        tokens.append(
            (
                token.text,
                indentation: indentation,
                location: inputLocation,
                ancestors: ancestors
            ))

        inputLocation.traverseNonTrivia(token)
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
for (text, loc, indentation, ancestors) in f.tokens {
    print("\(#file)\(loc):, \(String(repeating: "  ", count: indentation)) '\(text)' \t -> \(ancestors)")
}
