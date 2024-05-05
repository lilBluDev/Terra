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

    return p.mkNode(ast.Node{ .BinarayExpr = .{
        .left = left,
        .op = op,
        .right = right,
        .loc = p.combineLoc(p.getLoc(left), p.getLoc(right)),
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
