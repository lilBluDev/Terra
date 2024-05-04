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

pub fn parsePrimary(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    const t = p.advance();

    switch (t.token_type) {
        .Identifier => {
            return p.mkNode(ast.Node{
                .Identifier = .{
                    .name = t.value,
                    .loc = t.loc,
                },
            });
        },
        .NumberLit => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = t.value,
                    .type = .Int,
                    .loc = t.loc,
                },
            });
        },
        .FloatLit => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = t.value,
                    .type = .Float,
                    .loc = t.loc,
                },
            });
        },
        .StringLit => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = t.value,
                    .type = .String,
                    .loc = t.loc,
                },
            });
        },
        else => {
            return p.mkNode(ast.Node{
                .Literal = .{
                    .value = t.value,
                    .type = .String,
                    .loc = t.loc,
                },
            });
        },
    }
}
