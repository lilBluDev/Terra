const std = @import("std");

pub fn getFileContents(allocator: std.mem.Allocator, file: std.fs.File) ![]const u8 {
    var buffer: usize = 1024;
    var result = file.readToEndAlloc(allocator, buffer);

    if (result == error.FileTooBig) {
        buffer *= 2;
        result = try file.readToEndAlloc(allocator, buffer);
    }

    return result;
}
