const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("./AST.zig");
const Parser = @import("./parser.zig");
const lus = @import("./lookUps.zig");
const exprs = @import("./expr.zig");

pub fn parseStmt(p: *Parser.Parser) !*ast.Node {
    if (lus.stmt_lu.get(p.currentTokenType())) |handler| {
        return try handler(p);
    }

    return parseExprStmt(p);
}

pub fn parseExprStmt(p: *Parser.Parser) !*ast.Node {
    const expr = try exprs.parseExpr(p, .default);

    if (p.currentTokenType() != tk.TokenType.Semicolon) {
        std.debug.print("Expected ';' but got {}\n", .{p.currentTokenType()});
        std.process.exit(0);
    } else _ = p.advance();

    return expr;
}
