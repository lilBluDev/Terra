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
    Program: struct {
        body: NodesBlock,
        loc: tk.loc,
    },

    // Statements
    ExprStmts: struct {
        expr: *Node,
        loc: tk.loc,
    },

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
            .Program => |p| {
                p.body.deinit(aloc);
            },
            else => {},
        }
        aloc.destroy(self);
    }
};
