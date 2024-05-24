const std = @import("std");
const Chameleon = @import("../../lib/chameleon/chameleon.zig").Chameleon;
const tk = @import("../lexer/tokens.zig");
const ph = @import("../lexer/lexer.zig");

// Error Example:
//           (path)
// [line num]| [line preview]
//           errExplenation

pub const ErrMsg = struct { tag: []const u8, line: usize, col: usize, msg: []const u8 };

pub fn printErrHead(tag: []const u8, l: usize, c: usize) void {
    comptime var cham = Chameleon.init(.Auto);

    std.debug.print(cham.gray().fmt("({s}) [{}::{}]\n"), .{ tag, l, c });
}

pub fn printPreviewLine(line: usize) void {
    comptime var cham = Chameleon.init(.Auto);
    std.debug.print(cham.cyan().fmt("{} | "), .{line});

    var line_prev: []const u8 = undefined;

    var iter = std.mem.splitSequence(u8, ph.parseHead.original, "\n");
    while (iter.next()) |lin| {
        line_prev = lin;
    }

    std.debug.print("{s}\n", .{line_prev});
}

pub fn printErrArrow(line: usize, col: usize) void {
    comptime var cham = Chameleon.init(.Auto);

    const line_str = std.fmt.allocPrint(std.heap.page_allocator, "{} | ", .{line}) catch |err| {
        if (err == std.fmt.AllocPrintError.OutOfMemory) {
            std.debug.print("Failed to print!\n", .{});
            return;
        } else {
            std.debug.print("Failed to print!\n", .{});
            return;
        }
    };
    for (0..col + line_str.len - 1) |i| {
        _ = i;
        std.debug.print(cham.grey().fmt("~"), .{});
    }
    std.debug.print(cham.red().fmt("^\n"), .{});
}

pub fn printErr(err: ErrMsg) void {
    comptime var cham = Chameleon.init(.Auto);

    std.debug.print("\n", .{});
    for (0..40) |i| {
        _ = i;
        std.debug.print("=", .{});
    }
    std.debug.print("\n", .{});
    printErrHead(err.tag, err.line, err.col);
    printPreviewLine(err.line);
    printErrArrow(err.line, err.col);
    for (0..40) |i| {
        _ = i;
        std.debug.print("=", .{});
    }
    std.debug.print("\n\n", .{});
    std.debug.print(cham.redBright().fmt("Error"), .{});
    std.debug.print(": {s}\n", .{err.msg});
}
