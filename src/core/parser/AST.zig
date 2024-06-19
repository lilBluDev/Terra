const std = @import("std");
const tk = @import("../lexer/tokens.zig");

pub const BasicValueTypes = enum {
    Int,
    Float,
    Bool,
    String,
    Null,
};

pub const NodeVisibility = enum {
    Hidden,
    Public,
    Private,
};

pub const Node = union(enum) {
    // Misc
    ProjectTree: struct {
        body: NodesBlock,
        libs: NodesBlock,
    },
    Program: struct {
        tag: []const u8,
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
        loc: tk.loc,
    },

    // Statements
    VarDecl: struct {
        name: []const u8,
        isConst: bool,
        type: *Node,
        value: *Node,
        visibility: NodeVisibility,
        loc: tk.loc,
    },
    FuncDecl: struct {
        name: []const u8,
        params: NodesBlock,
        outType: *Node,
        body: *Node,
        visibility: NodeVisibility,
        loc: tk.loc,
    },
    IfStmt: struct {
        condition: *Node,
        body: *Node,
        alter: *Node,
        loc: tk.loc,
    },
    PublicDecl: struct {
        decl: *Node,
        loc: tk.loc,
    },
    StructDecl: struct {
        name: []const u8,
        fields: NodesBlock,
        visibility: NodeVisibility,
        loc: tk.loc,
    },
    EnumDecl: struct {
        name: []const u8,
        fields: NodesBlock,
        visibility: NodeVisibility,
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
    MemberExpr: struct {
        member: *Node,
        property: []const u8,
        loc: tk.loc,
    },
    ComputedExpr: struct {
        member: *Node,
        property: *Node,
        loc: tk.loc,
    },
    CallExpr: struct {
        callee: *Node,
        args: NodesBlock,
        loc: tk.loc,
    },
    ObjInit: struct {
        name: *Node,
        contents: NodesBlock,
        loc: tk.loc,
    },
    ArrayInit: struct {
        contents: NodesBlock,
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

    pub fn PrintLoc(self: *const Node) void {
        const loc = self.getLoc();
        std.debug.print("{}:{} - {}:{}\n", .{ loc.line, loc.column, loc.end_line, loc.end_col });
    }

    pub fn getLoc(self: *const Node) tk.loc {
        switch (self.*) {
            .Program => |p| return p.loc,
            .Block => |b| return b.loc,
            .VarDecl => |p| return p.loc,
            .FuncDecl => |p| return p.loc,
            .IfStmt => |p| return p.loc,
            .PublicDecl => |p| return p.loc,
            .StructDecl => |p| return p.loc,
            .EnumDecl => |p| return p.loc,
            .Identifier => |p| return p.loc,
            .Literal => |p| return p.loc,
            .AssignmentExpr => |p| return p.loc,
            .BinaryExpr => |p| return p.loc,
            .PrefixExpr => |p| return p.loc,
            .PostfixExpr => |p| return p.loc,
            .MemberExpr => |p| return p.loc,
            .ComputedExpr => |p| return p.loc,
            .CallExpr => |p| return p.loc,
            .ObjInit => |p| return p.loc,
            .ArrayInit => |p| return p.loc,
            .Symbol => |p| return p.loc,
            .MultiSymbol => |p| return p.loc,
            .ArraySymbol => |p| return p.loc,
            else => return tk.loc{
                .line = 0,
                .column = 0,
                .end_line = 0,
                .end_col = 0,
            },
        }
    }

    pub fn fmt(self: *const Node, aloc: std.mem.Allocator) ![]u8 {
        switch (self.*) {
            .Program => |p| return try std.fmt.allocPrint(aloc, "Program ({s})", .{p.tag}),

            .Param => |p| return try std.fmt.allocPrint(aloc, "Param: {s}", .{p.key}),

            // Statements
            .VarDecl => |p| return try std.fmt.allocPrint(aloc, "VarDecl: {s} ({})", .{ p.name, p.isConst }),
            .FuncDecl => |p| return try std.fmt.allocPrint(aloc, "FuncDecl: {s}", .{p.name}),
            .StructDecl => |p| return try std.fmt.allocPrint(aloc, "StructDecl: {s}", .{p.name}),
            .EnumDecl => |p| return try std.fmt.allocPrint(aloc, "EnumDecl: {s}", .{p.name}),

            // Expressions
            .Identifier => |p| return try std.fmt.allocPrint(aloc, "Identifier: {s}", .{p.name}),
            .Literal => |p| return try std.fmt.allocPrint(aloc, "Literal: {s} ({s})", .{ p.value, @tagName(p.type) }),
            .BinaryExpr => |p| return try std.fmt.allocPrint(aloc, "BinarayExpr: {s}", .{@tagName(p.op)}),
            .PrefixExpr => |p| return try std.fmt.allocPrint(aloc, "PrefixExpr: {s}", .{@tagName(p.op)}),
            .PostfixExpr => |p| return try std.fmt.allocPrint(aloc, "PostfixExpr: {s}", .{@tagName(p.op)}),

            // Types
            .Symbol => |p| return try std.fmt.allocPrint(aloc, "Symbol: {s}", .{p.name}),
            .ArraySymbol => |p| return try std.fmt.allocPrint(aloc, "ArraySymbol ({})", .{p.size}),

            else => |p| return try std.fmt.allocPrint(aloc, "{s}", .{@tagName(p)}),
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
            .IfStmt => |p| {
                p.condition.deinit(aloc);
                p.body.deinit(aloc);
                p.alter.deinit(aloc);
            },
            .PublicDecl => |p| {
                p.decl.deinit(aloc);
            },
            .StructDecl => |p| {
                p.fields.deinit(aloc);
            },
            .EnumDecl => |p| {
                p.fields.deinit(aloc);
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
            .MemberExpr => |p| {
                p.member.deinit(aloc);
            },
            .ComputedExpr => |p| {
                p.member.deinit(aloc);
                p.property.deinit(aloc);
            },
            .CallExpr => |p| {
                p.callee.deinit(aloc);
                p.args.deinit(aloc);
            },
            .ObjInit => |p| {
                p.name.deinit(aloc);
                p.contents.deinit(aloc);
            },
            .ArrayInit => |p| {
                p.contents.deinit(aloc);
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
