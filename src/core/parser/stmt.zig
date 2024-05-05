const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("./AST.zig");
const Parser = @import("./parser.zig");
const lus = @import("./lookUps.zig");
const tlus = @import("./typesLus.zig");
const exprs = @import("./expr.zig");

pub fn parseStmt(p: *Parser.Parser) !*ast.Node {
    if (lus.stmt_lu.get(p.currentTokenType())) |handler| {
        return try handler(p);
    }
    return parseExprStmt(p);
}

pub fn parseExprStmt(p: *Parser.Parser) !*ast.Node {
    const expr = try exprs.parseExpr(p, .default);
    _ = p.expectAndAdvance(tk.TokenType.Semicolon);
    return expr;
}

pub fn parseVarDeclStmt(p: *Parser.Parser) !*ast.Node {
    const op = p.advance();
    const isConst = op.is(.Const);
    const name = p.expectAndAdvance(.Identifier);

    var ty: *ast.Node = p.mkNull();
    if (p.currentToken().is(.Colon)) {
        _ = p.advance();
        ty = try tlus.parseType(p, .default);
    }

    if (!ty.isNull() and p.currentToken().is(.Walrus)) {
        std.debug.print("a walrus assignment should not need to specify the type!", .{});
        std.process.exit(0);
    }

    var value: *ast.Node = p.mkNull();
    if (p.currentToken().is(.Equals) or p.currentToken().is(.Walrus)) {
        _ = p.advance();
        value = try exprs.parseExpr(p, .default);
    }

    if (isConst and value.isNull()) {
        std.debug.print("a constant variable must have a specified value!", .{});
        std.process.exit(0);
    }

    _ = p.expectAndAdvance(.Semicolon);

    return p.mkNode(ast.Node{ .VarDecl = .{
        .name = name.value,
        .isConst = isConst,
        .type = ty,
        .value = value,
        .loc = p.combineLoc(op.loc, p.prev().loc),
    } });
}
