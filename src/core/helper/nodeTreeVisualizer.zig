const std = @import("std");
const ast = @import("../parser/AST.zig");

pub fn VisualizeNode(n: *ast.Node, aloc: std.mem.Allocator, tier: usize) !void {
    printTier(tier);

    switch (n.*) {
        .Program => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
                // std.debug.print("\n", .{});
            }
        },
        .ProjectTree => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
                // std.debug.print("\n", .{});
            }
        },
        .Param => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.value, aloc, tier + 1);
        },
        .Block => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
                // std.debug.print("\n", .{});
            }
        },

        // Statements
        .VarDecl => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(@as(*ast.Node, p.type), aloc, tier + 1);
            try VisualizeNode(@as(*ast.Node, p.value), aloc, tier + 1);
        },
        .FuncDecl => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            printTier(tier + 1);
            std.debug.print("< Params >\n", .{});
            for (p.params.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 2);
            }
            try VisualizeNode(p.outType, aloc, tier + 1);
            try VisualizeNode(p.body, aloc, tier + 1);
        },

        // Expressions
        .Null => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .AssignmentExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.lhs, aloc, tier + 1);
            try VisualizeNode(p.rhs, aloc, tier + 1);
        },
        .Identifier => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .Literal => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .BinaryExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.left, aloc, tier + 1);
            try VisualizeNode(p.right, aloc, tier + 1);
        },
        .PrefixExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.right, aloc, tier + 1);
        },
        .PostfixExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.left, aloc, tier + 1);
        },

        // Types
        .Symbol => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .MultiSymbol => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.syms.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
            }
        },
        .ArraySymbol => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.sym, aloc, tier + 1);
        },
    }
}

fn printTier(tier: usize) void {
    if (tier == 0) {
        std.debug.print("-> ", .{});
    } else {
        for (0..tier) |i| {
            _ = i;
            std.debug.print(" |", .{});
        }
        std.debug.print("-> ", .{});
    }
}
