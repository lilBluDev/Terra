const std = @import("std");
const ast = @import("../parser/AST.zig");

pub fn VisualizeNode(n: *ast.Node, aloc: std.mem.Allocator, tier: usize) !void {
    printTier(tier);

    switch (n.*) {
        .Program => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
            }
        },
        .ProjectTree => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.body.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
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
        .IfStmt => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.condition, aloc, tier + 1);
            try VisualizeNode(p.body, aloc, tier + 1);
            try VisualizeNode(p.alter, aloc, tier + 1);
        },
        .PublicDecl => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.decl, aloc, tier + 1);
        },
        .StructDecl => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.fields.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
            }
        },
        .EnumDecl => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            for (p.fields.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
            }
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
        .MemberExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.member, aloc, tier + 1);
            printTier(tier + 1);
            std.debug.print("< {s} >\n", .{p.property});
        },
        .ComputedExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.member, aloc, tier + 1);
            try VisualizeNode(p.property, aloc, tier + 1);
        },
        .CallExpr => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.callee, aloc, tier + 1);
            for (p.args.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
            }
        },
        .ObjInit => |p| {
            std.debug.print("{s}\n", .{try n.fmt(aloc)});
            try VisualizeNode(p.name, aloc, tier + 1);
            for (p.contents.items.items) |s| {
                try VisualizeNode(s, aloc, tier + 1);
            }
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
    printTier(tier + 1);
    n.PrintLoc();
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
