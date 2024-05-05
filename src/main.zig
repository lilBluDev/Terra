const std = @import("std");
const comp = @import("compiler.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const aloc = gpa.allocator();

    const args = try std.process.argsAlloc(aloc);
    defer std.process.argsFree(aloc, args);

    std.debug.print("{s}\n", .{args});

    const terraC = comp.TerraC.init(aloc);
    // defer terraC.deinit();
    try terraC.parseSingle("const pi := 3.141;\nvar celcius: float = 10;");
}
