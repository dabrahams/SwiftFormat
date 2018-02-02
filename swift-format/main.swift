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

final class Rewriter : SyntaxRewriter {
    var tokens: [(String, location: SourceLoc, ancestors: [Syntax.Type])] = []
    var inputLocation = SourceLoc()
    var indentation = 0
    var ancestors: [Syntax.Type] = []

    override func visit(_ node: SwiftSyntax.UnknownDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.UnknownExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.UnknownStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.UnknownTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.UnknownPatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.InOutExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PoundColumnExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TryExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DeclNameArgumentsSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IdentifierExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SuperRefExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.NilLiteralExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DiscardAssignmentExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AssignmentExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SequenceExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PoundLineExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PoundFileExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PoundFunctionExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PoundDsohandleExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SymbolicReferenceExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PrefixOperatorExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.BinaryOperatorExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FloatLiteralExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TupleExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ArrayExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DictionaryExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ImplicitMemberExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FunctionCallArgumentSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TupleElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ArrayElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DictionaryElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IntegerLiteralExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.StringLiteralExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.BooleanLiteralExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TernaryExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.MemberAccessExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DotSelfExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IsExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AsExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TypeExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureItemSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ClosureCaptureSignatureSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ClosureParamSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ClosureSignatureSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ClosureExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.UnresolvedPatternExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FunctionCallExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SubscriptExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.OptionalChainingExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ForcedValueExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PostfixUnaryExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.StringSegmentSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ExpressionSegmentSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.StringInterpolationExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.KeyPathExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ObjcNamePieceSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ObjcKeyPathExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.EditorPlaceholderExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ObjectLiteralExprSyntax) -> ExprSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TypeInitializerClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TypealiasDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ParameterClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ReturnClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FunctionSignatureSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ElseifDirectiveClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IfConfigDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DeclModifierSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.InheritedTypeSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TypeInheritanceClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ClassDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.StructDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ProtocolDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ExtensionDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.MemberDeclBlockSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SourceFileSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TopLevelCodeDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.InitializerClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FunctionParameterSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FunctionDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ElseDirectiveClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AccessLevelModifierSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AccessPathComponentSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ImportDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AccessorParameterSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AccessorDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AccessorBlockSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.PatternBindingSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.VariableDeclSyntax) -> DeclSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AttributeSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ContinueStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.WhileStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DeferStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ExpressionStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.RepeatWhileStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.GuardStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.WhereClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ForInStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SwitchStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DoStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ReturnStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FallthroughStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.BreakStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.CodeBlockSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ConditionElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AvailabilityConditionSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.MatchingPatternConditionSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.OptionalBindingConditionSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DeclarationStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ThrowStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IfStmtSyntax) -> StmtSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ElseIfContinuationSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ElseBlockSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SwitchDefaultLabelSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.CaseItemSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SwitchCaseLabelSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.CatchClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.GenericWhereClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SameTypeRequirementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.GenericParameterSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.GenericParameterClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ConformanceRequirementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.SimpleTypeIdentifierSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.MemberTypeIdentifierSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ArrayTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.DictionaryTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.MetatypeTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.OptionalTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ImplicitlyUnwrappedOptionalTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.CompositionTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TupleTypeElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TupleTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.FunctionTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AttributedTypeSyntax) -> TypeSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.GenericArgumentClauseSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TypeAnnotationSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.EnumCasePatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IsTypePatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.OptionalPatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.IdentifierPatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.AsTypePatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TuplePatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.WildcardPatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.TuplePatternElementSyntax) -> Syntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ExpressionPatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ node: SwiftSyntax.ValueBindingPatternSyntax) -> PatternSyntax {
        ancestors.append(type(of: node))
        let r = super.visit(node)
        ancestors.removeLast()
        return r
    }

    override func visit(_ token: TokenSyntax) -> Syntax {
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
let r = Rewriter()
_ = r.visit(parsed)
for (text, loc, ancestors) in r.tokens {
    print("\(#file)\(loc):, '\(text)' -> \(ancestors.map { String(describing: $0).split(separator: ".").last! })")
}
print(r.tokens)
