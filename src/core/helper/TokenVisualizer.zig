const std = @import("std");
const tok = @import("../lexer/tokens.zig");

pub fn VisualizeToken(tks: std.ArrayListAligned(tok.Token, null)) !void {
    std.debug.print("TOKENS LIST : \n", .{});

    for (tks.items) |t| {
        std.debug.print("- {s}\n", .{@tagName(t.token_type)});
    }
}
