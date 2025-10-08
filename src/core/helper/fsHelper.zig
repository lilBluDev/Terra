const std = @import("std");

pub fn readPath(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch |er| {
        if (er == std.fs.File.OpenError.FileNotFound) {
            std.debug.print("File '{s}' Not Found!\n", .{path});
        } else {
            std.debug.print("Unable to read '{s}'!", .{path});
        }
        std.process.exit(0);
    };

    return try getFileContents(allocator, file);
}

pub fn getFileContents(allocator: std.mem.Allocator, file: std.fs.File) ![]const u8 {
    var buffer: usize = 1024;
    var result = file.readToEndAlloc(allocator, buffer);

    if (result == error.FileTooBig) {
        buffer *= 2;
        result = try file.readToEndAlloc(allocator, buffer);
    }

    return result;
}
