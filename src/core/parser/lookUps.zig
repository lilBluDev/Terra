const std = @import("std");
const tk = @import("../lexer/tokens.zig");
const Parser = @import("./parser.zig");
const AST = @import("./AST.zig");
const expr = @import("./expr.zig");

pub const binding_power = enum(u4) {
    default,
    comma,
    assignment,
    logical,
    relational,
    addative,
    multiplicative,
    unary,
    call,
    member,
    primary,
};

const stmt_handler = *const fn (p: *Parser.Parser) anyerror!*AST.Node; //stmt
const infix_handler = *const fn (p: *Parser.Parser, bp: binding_power) anyerror!*AST.Node; //expr
const atomic_handler = *const fn (p: *Parser.Parser, left: *AST.Node, bp: binding_power) anyerror!*AST.Node;

pub var stmt_lu = std.enums.EnumMap(tk.TokenType, stmt_handler){};
pub var infix_lu = std.enums.EnumMap(tk.TokenType, infix_handler){};
pub var atomic_lu = std.enums.EnumMap(tk.TokenType, atomic_handler){};
pub var binding_lu = std.enums.EnumMap(tk.TokenType, binding_power){};

fn atomic(kind: tk.TokenType, bp: binding_power, handler: atomic_handler) void {
    binding_lu.put(kind, bp);
    atomic_lu.put(kind, handler);
}

fn infix(kind: tk.TokenType, handler: infix_handler) void {
    binding_lu.put(kind, .primary);
    infix_lu.put(kind, handler);
}

fn stmt(kind: tk.TokenType, handler: stmt_handler) void {
    binding_lu.put(kind, .default);
    stmt_lu.put(kind, handler);
}

pub fn loadLUs() void {
    infix(.Identifier, expr.parsePrimary);
    infix(.StringLit, expr.parsePrimary);
    infix(.FloatLit, expr.parsePrimary);
    infix(.NumberLit, expr.parsePrimary);

    atomic(.Plus, .addative, expr.parseBinaryExpr);
    atomic(.Minus, .addative, expr.parseBinaryExpr);
    atomic(.Star, .multiplicative, expr.parseBinaryExpr);
    atomic(.Slash, .multiplicative, expr.parseBinaryExpr);
    atomic(.Percent, .multiplicative, expr.parseBinaryExpr);
}
