const std = @import("std");
const tk = @import("../lexer/tokens.zig");

pub const BasicValueTypes = enum {
    Int,
    Float,
    Bool,
    String,
};

pub const Node = union(enum) {
    // Misc
    ProjectTree: struct {
        tag: []const u8,
        body: NodesBlock,
        libs: NodesBlock,
    },

    Program: struct {
        body: NodesBlock,
        loc: tk.loc,
    },

    // Statements

    // Expressions
    Identifier: struct {
        name: []const u8,
        loc: tk.loc,
    },
    Literal: struct {
        value: []const u8,
        type: BasicValueTypes,
        loc: tk.loc,
    },
    BinarayExpr: struct {
        op: tk.TokenType,
        left: *Node,
        right: *Node,
        loc: tk.loc,
    },
    PrefixExpr: struct {
        op: tk.TokenType,
        right: *Node,
        loc: tk.loc,
    },
    PostfixExpr: struct {
        op: tk.TokenType,
        left: *Node,
        loc: tk.loc,
    },

    // Types
    Symbol: struct {
        name: []const u8,
        loc: tk.loc,
    },
    MultiSymbol: struct {
        syms: NodesBlock,
        loc: tk.loc,
    },
    ArraySymbol: struct {
        sym: *Node,
        size: usize,
        loc: tk.loc,
    },

    // tools
    pub const NodesBlock = struct {
        items: std.ArrayListAligned(*Node, null),
        pub fn deinit(self: NodesBlock, alloc: std.mem.Allocator) void {
            for (self.items.items) |s| s.deinit(alloc);
        }
    };

    pub fn fmt(self: *const Node, aloc: std.mem.Allocator) ![]u8 {
        switch (self.*) {
            .Program => return try std.fmt.allocPrint(aloc, "< Program >", .{}),
            .ProjectTree => return try std.fmt.allocPrint(aloc, "< ProjectTree >", .{}),

            // Statements

            // Expressions
            .Identifier => |p| return try std.fmt.allocPrint(aloc, "< Identifier: {s} >", .{p.name}),
            .Literal => |p| return try std.fmt.allocPrint(aloc, "< Literal: {s} > ({s})", .{ p.value, @tagName(p.type) }),
            .BinarayExpr => |p| return try std.fmt.allocPrint(aloc, "< BinarayExpr: {s} >", .{@tagName(p.op)}),
            .PrefixExpr => |p| return try std.fmt.allocPrint(aloc, "< PrefixExpr: {s} >", .{@tagName(p.op)}),
            .PostfixExpr => |p| return try std.fmt.allocPrint(aloc, "< PostfixExpr: {s} >", .{@tagName(p.op)}),

            // Types
            .Symbol => |p| return try std.fmt.allocPrint(aloc, "< Symbol: {s} >", .{p.name}),
            .MultiSymbol => return try std.fmt.allocPrint(aloc, "< MultiSymbol >", .{}),
            .ArraySymbol => |p| return try std.fmt.allocPrint(aloc, "< ArraySymbol ({}) >", .{p.size}),

            // else => return try std.fmt.allocPrint(aloc, "< N/A >", .{}),
        }
    }

    pub fn deinit(self: *const Node, aloc: std.mem.Allocator) void {
        switch (self.*) {
            // Misc
            .ProjectTree => |p| {
                p.body.deinit(aloc);
                p.libs.deinit(aloc);
            },
            .Program => |p| {
                p.body.deinit(aloc);
            },

            // Statements

            // Expressions
            .BinarayExpr => |p| {
                p.left.deinit(aloc);
                p.right.deinit(aloc);
            },
            .PrefixExpr => |p| {
                p.right.deinit(aloc);
            },
            .PostfixExpr => |p| {
                p.left.deinit(aloc);
            },

            // Types
            .MultiSymbol => |p| {
                p.syms.deinit(aloc);
            },

            else => {},
        }
        aloc.destroy(self);
    }
};
