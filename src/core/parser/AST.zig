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
        op: []const u8,
        left: *Node,
        right: *Node,
        loc: tk.loc,
    },
    PrefixExpr: struct {
        op: []const u8,
        right: *Node,
        loc: tk.loc,
    },
    InfixExpr: struct {
        op: []const u8,
        left: *Node,
        loc: tk.loc,
    },

    // Types
    Symbol: struct {
        name: []const u8,
        loc: tk.loc,
    },
    MultiSymbol: struct {
        name: [][]const u8,
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
            .InfixExpr => |p| {
                p.left.deinit(aloc);
            },

            else => {},
        }
        aloc.destroy(self);
    }
};
