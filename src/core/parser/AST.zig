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
        body: NodesBlock,
        libs: NodesBlock,
    },
    Program: struct {
        body: NodesBlock,
        loc: tk.loc,
    },
    Block: struct {
        body: NodesBlock,
        loc: tk.loc,
    },
    Param: struct {
        key: []const u8,
        value: *Node,
    },

    // Statements
    VarDecl: struct {
        name: []const u8,
        isConst: bool,
        type: *Node,
        value: *Node,
        loc: tk.loc,
    },
    FuncDecl: struct {
        name: []const u8,
        params: NodesBlock,
        outType: *Node,
        body: *Node,
        loc: tk.loc,
    },

    // Expressions
    Null: struct {},
    Identifier: struct {
        name: []const u8,
        loc: tk.loc,
    },
    Literal: struct {
        value: []const u8,
        type: BasicValueTypes,
        loc: tk.loc,
    },
    AssignmentExpr: struct {
        lhs: *Node,
        rhs: *Node,
        loc: tk.loc,
    },
    BinaryExpr: struct {
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
            .Param => |p| return try std.fmt.allocPrint(aloc, "< Param: {s}>", .{p.key}),

            // Statements
            .VarDecl => |p| return try std.fmt.allocPrint(aloc, "< VarDecl: {s}> ({})", .{ p.name, p.isConst }),
            .FuncDecl => |p| return try std.fmt.allocPrint(aloc, "< FuncDecl: {s}>", .{p.name}),

            // Expressions
            .Identifier => |p| return try std.fmt.allocPrint(aloc, "< Identifier: {s} >", .{p.name}),
            .Literal => |p| return try std.fmt.allocPrint(aloc, "< Literal: {s} > ({s})", .{ p.value, @tagName(p.type) }),
            .BinaryExpr => |p| return try std.fmt.allocPrint(aloc, "< BinarayExpr: {s} >", .{@tagName(p.op)}),
            .PrefixExpr => |p| return try std.fmt.allocPrint(aloc, "< PrefixExpr: {s} >", .{@tagName(p.op)}),
            .PostfixExpr => |p| return try std.fmt.allocPrint(aloc, "< PostfixExpr: {s} >", .{@tagName(p.op)}),

            // Types
            .Symbol => |p| return try std.fmt.allocPrint(aloc, "< Symbol: {s} >", .{p.name}),
            .ArraySymbol => |p| return try std.fmt.allocPrint(aloc, "< ArraySymbol ({}) >", .{p.size}),

            else => |p| return try std.fmt.allocPrint(aloc, "< {s} >", .{@tagName(p)}),
        }
    }

    pub fn isNull(self: *const Node) bool {
        switch (self.*) {
            .Null => return true,
            else => return false,
        }
    }

    pub fn deinit(self: *const Node, aloc: std.mem.Allocator) void {
        switch (self.*) {
            // Misc
            .ProjectTree => |p| {
                p.body.deinit(aloc);
                p.libs.deinit(aloc);
            },
            .Block => |p| {
                p.body.deinit(aloc);
            },
            .Program => |p| {
                p.body.deinit(aloc);
            },
            .Param => |p| {
                p.value.deinit(aloc);
            },

            // Statements
            .VarDecl => |p| {
                p.type.deinit(aloc);
                p.value.deinit(aloc);
            },
            .FuncDecl => |p| {
                p.body.deinit(aloc);
                p.params.deinit(aloc);
                p.outType.deinit(aloc);
            },

            // Expressions
            .AssignmentExpr => |p| {
                p.lhs.deinit(aloc);
                p.rhs.deinit(aloc);
            },
            .BinaryExpr => |p| {
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
