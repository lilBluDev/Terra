const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("./AST.zig");
const Parser = @import("./parser.zig");
const lus = @import("./lookUps.zig");
const errs = @import("../helper/errors.zig");

pub fn parseExpr(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    if (lus.infix_lu.get(p.currentTokenType())) |infHandler| {
        var left = try infHandler(p, bp);

        while (lus.binding_lu.get(p.currentTokenType()) != null and
            @intFromEnum(lus.binding_lu.get(p.currentTokenType()).?) > @intFromEnum(bp))
        {
            if (lus.atomic_lu.get(p.currentTokenType())) |atomicHandler| {
                left = try atomicHandler(p, left, bp);
            } else {
                // std.debug.print("No Atomic handler for {}\n", .{p.currentTokenType()});
                const str = std.fmt.allocPrint(std.heap.page_allocator, "No Atomic handler for {}", .{p.currentTokenType()}) catch |err| {
                    if (err == std.fmt.AllocPrintError.OutOfMemory) {
                        std.debug.print("Failed to print!\n", .{});
                        std.process.exit(0);
                    } else {
                        std.debug.print("Failed to print!\n", .{});
                        std.process.exit(0);
                    }
                };
                errs.printErr(errs.ErrMsg{
                    .line = p.currentToken().loc.line,
                    .col = p.currentToken().loc.column,
                    .tag = p.lx.tag,
                    .msg = str,
                });
                std.process.exit(0);
            }
        }

        return left;
    } else {
        const str = std.fmt.allocPrint(std.heap.page_allocator, "No infix handler for {}", .{p.currentTokenType()}) catch |err| {
            if (err == std.fmt.AllocPrintError.OutOfMemory) {
                std.debug.print("Failed to print!\n", .{});
                std.process.exit(0);
            } else {
                std.debug.print("Failed to print!\n", .{});
                std.process.exit(0);
            }
        };
        errs.printErr(errs.ErrMsg{
            .line = p.currentToken().loc.line,
            .col = p.currentToken().loc.column,
            .tag = p.lx.tag,
            .msg = str,
        });
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
        .loc = p.combineLoc(left.getLoc(), right.getLoc()),
    } });
}

pub fn assignmentExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    _ = p.advance();
    const rhs = try parseExpr(p, .assignment);

    return p.mkNode(ast.Node{ .AssignmentExpr = .{
        .lhs = left,
        .rhs = rhs,
        .loc = p.combineLoc(left.getLoc(), p.prev().loc),
    } });
}

pub fn parsePostfixExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    _ = bp;
    const op = p.advance();

    return p.mkNode(ast.Node{ .PostfixExpr = .{
        .op = op.token_type,
        .left = left,
        .loc = p.combineLoc(left.getLoc(), op.loc),
    } });
}

pub fn parsePrefixExpr(p: *Parser.Parser, bp: lus.binding_power) !*ast.Node {
    const op = p.advance();
    const right = try parseExpr(p, bp);

    return p.mkNode(ast.Node{ .PrefixExpr = .{
        .op = op.token_type,
        .right = right,
        .loc = p.combineLoc(op.loc, right.getLoc()),
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
        .NullKeyword => {
            return p.mkNode(ast.Node{ .Literal = .{
                .value = val,
                .type = .Null,
                .loc = t.loc,
            } });
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

pub fn parseMemberExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    const computed = p.advance().is(.LeftBracket);

    if (computed) {
        const rhs = try parseExpr(p, bp);
        _ = p.expectAndAdvance(.RightBracket);
        return p.mkNode(ast.Node{ .ComputedExpr = .{
            .member = left,
            .property = rhs,
            .loc = p.combineLoc(left.getLoc(), rhs.getLoc()),
        } });
    }

    return p.mkNode(ast.Node{ .MemberExpr = .{
        .member = left,
        .property = p.expectAndAdvance(.Identifier).value,
        .loc = p.combineLoc(left.getLoc(), p.prev().loc),
    } });
}

pub fn parseCallExpr(p: *Parser.Parser, left: *ast.Node, bp: lus.binding_power) !*ast.Node {
    _ = p.advance();
    _ = bp;
    var args = std.ArrayListAligned(*ast.Node, null).init(p.aloc);
    while (!p.currentToken().is(.RightParen) and !p.currentToken().is(.EOF)) {
        const arg = try parseExpr(p, .assignment);
        try args.append(arg);
        if (!p.currentToken().is(.RightParen) and !p.currentToken().is(.EOF)) _ = p.expectAndAdvance(.Comma);
    }
    _ = p.expectAndAdvance(.RightParen);

    return p.mkNode(ast.Node{ .CallExpr = .{
        .callee = left,
        .args = ast.Node.NodesBlock{ .items = args },
        .loc = p.combineLoc(left.getLoc(), p.prev().loc),
    } });
}
