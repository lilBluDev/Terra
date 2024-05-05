const std = @import("std");
const comp = @import("compiler.zig");

pub fn main() !void {
    std.debug.print("Hello, World!\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const aloc = gpa.allocator();

    const terraC = comp.TerraC.init(aloc);
    // defer terraC.deinit();
    try terraC.parseSingle("10 + 10 * 5;");
}
