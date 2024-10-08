const std = @import("std");
const Chameleon = @import("../../lib/chameleon/chameleon.zig").Chameleon;
const tk = @import("../lexer/tokens.zig");
const ph = @import("../lexer/lexer.zig");

// Error Example:
//           (path)
// [line num]| [line preview]
//           errExplenation

pub const ErrMsg = struct {
    tag: []const u8,
    line: usize,
    col: usize,
    msg: ?[]const u8,
    previewLookBack: ?usize,
    // recommend: ?[]const u8,
    ErrType: []const u8,
    ErrKind: enum {
        Error,
        Warning,
        Info,
        Panic,
    },
};

pub fn printErrHead(tag: []const u8, l: usize, c: usize) void {
    comptime var cham = Chameleon.init(.Auto);

    std.debug.print(cham.gray().fmt("({s}) [{}::{}]\n"), .{ tag, l, c });
}

pub fn printPreviewLine(line: usize, plb_size: usize) void {
    comptime var cham = Chameleon.init(.Auto);

    // var line_prev: []const u8 = undefined;

    var iter = std.mem.splitSequence(u8, ph.parseHead.original, "\n");
    var i: usize = 1;
    while (iter.next()) |lin| {
        if (i > (line - plb_size) and i != line) {
            std.debug.print(cham.cyan().fmt("{} | "), .{i});
            std.debug.print("{s}\n", .{lin});
        }
        if (i == line) {
            std.debug.print(cham.cyan().fmt("{} | "), .{line});
            std.debug.print("{s}\n", .{lin});
            break;
        }
        i += 1;
    }

    i = 1;

    // std.debug.print("\nlookback line start: {}", .{line - plb_size});
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

    // std.debug.print("\n", .{});
    printErrHead(err.tag, err.line, err.col);
    printPreviewLine(err.line, err.previewLookBack orelse 1);
    printErrArrow(err.line, err.col);
    switch (err.ErrKind) {
        .Error => std.debug.print(cham.red().fmt("error"), .{}),
        .Warning => std.debug.print(cham.yellow().fmt("warning"), .{}),
        .Info => std.debug.print(cham.cyan().fmt("info"), .{}),
        .Panic => std.debug.print(cham.redBright().fmt("panic"), .{}),
    }
    std.debug.print("::{s}()\n", .{err.ErrType});
    if (err.msg) |msg| {
        printPadding(3);
        std.debug.print(cham.cyan().fmt(".message"), .{});
        std.debug.print(": {s}\n", .{msg});
    }
    // if (err.recommend) |msg| {
    //     printPadding(3);
    //     std.debug.print(cham.yellow().fmt(".suggestion"), .{});
    //     std.debug.print(": {s}\n", .{msg});
    // }
}

fn printPadding(size: usize) void {
    for (0..size) |i| {
        _ = i;
        std.debug.print(" ", .{});
    }
}
