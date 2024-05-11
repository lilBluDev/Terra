const std = @import("std");
const comp = @import("compiler.zig");
const fsH = @import("./core/helper/fsHelper.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const aloc = gpa.allocator();

    const args = try std.process.argsAlloc(aloc);
    defer std.process.argsFree(aloc, args);

    std.debug.print("\x1B[2J\x1B[H", .{});

    const terraC = comp.TerraC.init(aloc);

    std.debug.print("\u{250C} \n", .{});

    const contents = try fsH.getFileContents(aloc, try std.fs.cwd().openFile("main.tr", .{}));

    // defer terraC.deinit();
    // try terraC.parseSingle("const pi := 3.141;\nvar celcius: float = 10;");
    try terraC.parseSingle(contents);
}
