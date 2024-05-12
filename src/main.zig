const std = @import("std");
const comp = @import("compiler.zig");
const fsH = @import("./core/helper/fsHelper.zig");
const cli_app = @import("./cli/app.zig").CliApp;
const chameleon = @import("./lib/chameleon/chameleon.zig").Chameleon;
const ntv = @import("./core/helper/nodeTreeVisualizer.zig");

pub const name = "terra";
pub const version = "Dev-0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const aloc = gpa.allocator();

    const args = try std.process.argsAlloc(aloc);
    defer std.process.argsFree(aloc, args);

    if (args.len > 1) {
        const cli = cli_app.init(aloc);
        try cli.start();
    } else {
        comptime var cham = chameleon.init(.Auto);
        const str = "<< " ++ name ++ " " ++ version ++ ">>\n";

        std.debug.print(cham.grey().fmt(str), .{});

        while (true) {
            const stdin = std.io.getStdIn().reader();
            const stdout = std.io.getStdOut().writer();

            try stdout.print(cham.grey().fmt(">>> "), .{});

            var buffer: [1024]u8 = undefined;

            if (try stdin.readUntilDelimiterOrEof(buffer[0..], '\n')) |out| {
                const line = out[0 .. out.len - 1];
                if (std.mem.eql(u8, line, "exit")) {
                    std.debug.print("exiting...", .{});
                    break;
                } else {
                    // if (line[line.len - 1] != ';') line[line.len] = ';';
                    const TerraC = comp.TerraC.init(aloc);
                    const prgm = try TerraC.parseSingle(line, "console");
                    defer prgm.deinit(aloc);

                    try ntv.VisualizeNode(prgm, aloc, 0);
                }
            }
        }
    }
}
