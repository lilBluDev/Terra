const std = @import("std");
const tk = @import("../lexer/tokens.zig");
const Parser = @import("./parser.zig");
const ast = @import("./AST.zig");
const expr = @import("./expr.zig");
const maps = @import("./lookUps.zig");
const errs = @import("../helper/errors.zig");

const infix_handler = *const fn (p: *Parser.Parser, bp: maps.binding_power) anyerror!*ast.Node; //expr
const atomic_handler = *const fn (p: *Parser.Parser, left: *ast.Node, bp: maps.binding_power) anyerror!*ast.Node;

pub var infix_lu = std.enums.EnumMap(tk.TokenType, infix_handler){};
pub var atomic_lu = std.enums.EnumMap(tk.TokenType, atomic_handler){};
pub var binding_lu = std.enums.EnumMap(tk.TokenType, maps.binding_power){};

fn atomic(kind: tk.TokenType, bp: maps.binding_power, handler: atomic_handler) void {
    binding_lu.put(kind, bp);
    atomic_lu.put(kind, handler);
}

fn infix(kind: tk.TokenType, handler: infix_handler) void {
    binding_lu.put(kind, .primary);
    infix_lu.put(kind, handler);
}

pub fn loadLUs() void {
    infix(.Identifier, parseSymbol);
    infix(.LeftBracket, parseArraySymbol);
    infix(.LeftParen, parseMultiSymbol);

    atomic(.Dot, .member, expr.parseMemberExpr);
    atomic(.LeftBracket, .member, expr.parseMemberExpr);
}

pub fn parseType(p: *Parser.Parser, bp: maps.binding_power) !*ast.Node {
    if (infix_lu.get(p.currentTokenType())) |infHandler| {
        var left = try infHandler(p, bp);

        while (binding_lu.get(p.currentTokenType()) != null and
            @intFromEnum(binding_lu.get(p.currentTokenType()).?) > @intFromEnum(bp))
        {
            if (atomic_lu.get(p.currentTokenType())) |atomicHandler| {
                left = try atomicHandler(p, left, bp);
            } else {
                const str = std.fmt.allocPrint(std.heap.page_allocator, "No Atomic handler for symbol {}", .{p.currentTokenType()}) catch |err| {
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
                    .ErrType = "UnknownNode",
                    .ErrKind = .Error,
                    .previewLookBack = null,
                });
                std.process.exit(0);
            }
        }

        return left;
    } else {
        const str = std.fmt.allocPrint(std.heap.page_allocator, "No infix handler for symbol {}", .{p.currentTokenType()}) catch |err| {
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
            .ErrType = "UnknownNode",
            .ErrKind = .Error,
            .previewLookBack = null,
        });
        std.process.exit(0);
    }
}

fn parseSymbol(p: *Parser.Parser, bp: maps.binding_power) !*ast.Node {
    _ = bp;
    const sym = p.advance();
    return p.mkNode(ast.Node{ .Symbol = .{
        .name = sym.value,
        .loc = sym.loc,
    } });
}

fn parseMultiSymbol(p: *Parser.Parser, bp: maps.binding_power) !*ast.Node {
    const prev = p.expectAndAdvance(.LeftParen);
    var arr = std.ArrayListAligned(*ast.Node, null).init(p.aloc);

    while (p.currentTokenType() != .RightParen and p.currentTokenType() != .EOF) {
        const sym = try parseType(p, bp);
        try arr.append(sym);
        if (p.currentTokenType() != .RightParen and p.currentTokenType() != .EOF) {
            _ = p.expectAndAdvance(.Comma);
        }
    }
    _ = p.expectAndAdvance(.RightParen);

    return p.mkNode(ast.Node{ .MultiSymbol = .{
        .syms = ast.Node.NodesBlock{ .items = arr },
        .loc = p.combineLoc(prev.loc, arr.items[arr.items.len - 1].getLoc()),
    } });
}

fn parseArraySymbol(p: *Parser.Parser, bp: maps.binding_power) !*ast.Node {
    // TODO: Make it so it can set a size for the array between the []
    const s = p.expectAndAdvance(.LeftBracket);
    var size: usize = 0;
    if (!p.currentToken().is(.RightBracket)) {
        const num = p.advance();
        size = try std.fmt.parseInt(usize, num.value, 10);
    }
    _ = p.expectAndAdvance(.RightBracket);
    const sym = try parseType(p, bp);

    return p.mkNode(ast.Node{ .ArraySymbol = .{
        .sym = sym,
        .loc = p.combineLoc(s.loc, sym.getLoc()),
        .size = size,
    } });
}
