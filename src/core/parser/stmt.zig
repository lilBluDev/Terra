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

pub fn parsePubStmt(p: *Parser.Parser) !*ast.Node {
    const op = p.advance();
    var decl = try parseStmt(p);

    switch (decl.*) {
        .VarDecl => {
            decl.*.VarDecl.visibility = .Public;
            return decl;
        },
        .FuncDecl => {
            decl.*.FuncDecl.visibility = .Public;
            return decl;
        },
        else => {
            return p.mkNode(ast.Node{ .PublicDecl = .{
                .decl = decl,
                .loc = p.combineLoc(op.loc, decl.getLoc()),
            } });
        },
    }
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
    } else if (ty.isNull() and p.currentToken().is(.Equals)) {
        std.debug.print("a normal assignment should need to specify the type!", .{});
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
        .visibility = .Private,
        .loc = p.combineLoc(op.loc, p.prev().loc),
    } });
}

pub fn parseFuncDeclStmt(p: *Parser.Parser) !*ast.Node {
    const start = p.advance();
    const name = p.expectAndAdvance(.Identifier);
    var params = std.ArrayListAligned(*ast.Node, null).init(p.aloc);
    _ = p.expectAndAdvance(.LeftParen);
    while (!p.currentToken().is(.RightParen) and !p.currentToken().is(.EOF)) {
        const key = p.expectAndAdvance(.Identifier);
        _ = p.expectAndAdvance(.Colon);
        const ty = try tlus.parseType(p, .default);
        try params.append(p.mkNode(ast.Node{
            .Param = .{ .key = key.value, .value = ty, .loc = p.combineLoc(key.loc, ty.*.getLoc()) },
        }));
        if (!p.currentToken().is(.RightParen) and !p.currentToken().is(.EOF)) {
            _ = p.expectAndAdvance(.Comma);
        }
    }
    _ = p.expectAndAdvance(.RightParen);

    var outType = p.mkNull();
    if (!p.currentToken().is(.LeftBrace)) {
        outType = try tlus.parseType(p, .default);
    }

    const block = try p.parseBlock();

    return p.mkNode(ast.Node{ .FuncDecl = .{
        .name = name.value,
        .params = ast.Node.NodesBlock{ .items = params },
        .outType = outType,
        .body = block,
        .visibility = .Private,
        .loc = p.combineLoc(start.loc, p.prev().loc),
    } });
}

pub fn parseIfStmt(p: *Parser.Parser) !*ast.Node {
    const start = p.advance();
    _ = p.expectAndAdvance(.LeftParen);
    const condition = try exprs.parseExpr(p, .assignment);
    _ = p.expectAndAdvance(.RightParen);

    // TODO: ADD SCOPE CAPTURING

    const body = try p.parseBlock();
    var alter = p.mkNull();

    if (p.currentToken().is(.Elif)) {
        alter = try parseIfStmt(p);
    } else if (p.currentToken().is(.Else)) {
        _ = p.advance();
        alter = try p.parseBlock();
    }

    return p.mkNode(ast.Node{ .IfStmt = .{
        .condition = condition,
        .body = body,
        .alter = alter,
        .loc = p.combineLoc(start.loc, p.prev().loc),
    } });
}
