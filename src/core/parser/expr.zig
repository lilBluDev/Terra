const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("./AST.zig");
const Parser = @import("./parser.zig");
const lus = @import("./lookUps.zig");

pub fn parseExpr(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    if (lus.infix_lu.get(p.currentTokenType())) |infHandler| {
        var left = try infHandler(p, bp);

        while (lus.binding_lu.get(p.currentTokenType()) != null and
            @intFromEnum(lus.binding_lu.get(p.currentTokenType()).?) > @intFromEnum(bp))
        {
            if (lus.atomic_lu.get(p.currentTokenType())) |atomicHandler| {
                left = try atomicHandler(p, left, bp);
            } else {
                std.debug.print("No Atomic handler for {}\n", .{p.currentTokenType()});
                std.process.exit(0);
            }
        }

        return left;
    } else {
        std.debug.print("No Infix handler for {}\n", .{p.currentTokenType()});
        std.process.exit(0);
    }
}

pub fn parseBinaryExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    const op = p.advance().token_type;
    const right = try parseExpr(p, bp);

    return p.mkNode(ast.Node{ .BinaryExpr = .{
        .left = left,
        .op = op,
        .right = right,
        .loc = p.combineLoc(p.getLoc(left), p.getLoc(right)),
    } });
}

pub fn assignmentExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    _ = p.advance();
    const rhs = try parseExpr(p, .assignment);

    return p.mkNode(ast.Node{ .AssignmentExpr = .{
        .lhs = left,
        .rhs = rhs,
        .loc = p.combineLoc(p.getLoc(left), p.prev().loc),
    } });
}

pub fn parsePostfixExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    const op = p.advance();

    return p.mkNode(ast.Node{ .PostfixExpr = .{
        .op = op.token_type,
        .left = left,
        .loc = p.combineLoc(p.getLoc(left), op.loc),
    } });
}

pub fn parsePrefixExpr(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    const op = p.advance();
    const right = try parseExpr(p, bp);

    return p.mkNode(ast.Node{ .PrefixExpr = .{
        .op = op.token_type,
        .right = right,
        .loc = p.combineLoc(op.loc, p.getLoc(right)),
    } });
}

pub fn parsePrimary(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    const t = p.advance();
    const val = t.value;

    switch (t.token_type) {
        .Identifier => {
            return p.mkNode(ast.Node{
                .Identifier = .{
                    .name = val,
                    .loc = t.loc,
                },
            });
        },
        .NumberLit => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = val,
                    .type = .Int,
                    .loc = t.loc,
                },
            });
        },
        .FloatLit => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = val,
                    .type = .Float,
                    .loc = t.loc,
                },
            });
        },
        .TrueKeyword, .FalseKeyword => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = val,
                    .type = .Bool,
                    .loc = t.loc,
                },
            });
        },
        .StringLit => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = val,
                    .type = .String,
                    .loc = t.loc,
                },
            });
        },
        else => {
            // return p.mkNode(ast.Node{
            //     .Literal = .{
            //         .value = val,
            //         .type = .String,
            //         .loc = t.loc,
            //     },
            // });
            std.debug.print("No handler for {}\n", .{t.token_type});
            std.process.exit(0);
        },
    }
}

pub fn parseGroupings(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    _ = p.expectAndAdvance(.LeftParen);
    const expr = try parseExpr(p, .default);
    _ = p.expectAndAdvance(.RightParen);
    return expr;
}
