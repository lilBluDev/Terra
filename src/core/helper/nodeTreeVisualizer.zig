const std = @import("std");
const ast = @import("../parser/AST.zig");

pub fn VisualizeNode(n: *ast.Node, aloc: std.mem.Allocator, tier: usize) !void {
    if (tier == 0) {
        std.debug.print("-> ", .{});
    } else {
        for (0..tier) |i| {
            _ = i;
            std.debug.print(" |", .{});
        }
        std.debug.print("-> ", .{});
    }

    switch (n.*) {
        .Program => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
                std.debug.print("\n", .{});
            }
        },
        .ProjectTree => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
                std.debug.print("\n", .{});
            }
        },

        // Statements

        // Expressions
        .Identifier => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .Literal => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .BinarayExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.left, aloc, tier + 1);
            try VisualizeNode(p.right, aloc, tier + 1);
        },
        .PrefixExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.right, aloc, tier + 1);
        },
        .InfixExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.left, aloc, tier + 1);
        },

        // Types
        .Symbol => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .MultiSymbol => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
        .ArraySymbol => |p| {
            _ = p;
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
        },
    }
}
