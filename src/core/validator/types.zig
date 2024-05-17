const std = @import("std");

pub const tyEnv = struct {
    builtIn: std.ArrayList(*ty),

    pub fn deinit(self: *tyEnv, aloc: std.mem.Allocator) void {
        self.builtIn.deinit();
        aloc.destroy(self);
    }
};

pub const ty = union(enum) {
    str: struct {},
    int: struct {},
    bool: struct {},
    float: struct {},
    null: struct {},
    multi: struct {
        contents: std.ArrayList(*ty),
    },
    arr: struct {
        size: usize,
        ty: *ty,
    },

    pub fn isNull(self: *ty) bool {
        switch (self.*) {
            .null => return true,
            else => return false,
        }
    }

    pub fn toStr(self: *ty, alloc: std.mem.Allocator) ![]const u8 {
        switch (self.*) {
            .multi => |s| {
                var c = std.ArrayList([]const u8).init(alloc);
                defer c.deinit();

                for (s.contents.items) |t| {
                    try c.append(try t.toStr(alloc));
                }

                const arr = try c.toOwnedSlice();
                return try std.fmt.allocPrint(alloc, "({s})", .{try std.mem.join(alloc, "|", arr)});
            },
            .arr => |s| {
                return try std.fmt.allocPrint(alloc, "[{}]{s}", .{ s.size, try s.ty.toStr(alloc) });
            },
            else => |p| {
                return @tagName(p);
            },
        }
    }

    pub fn deinit(self: *ty, aloc: std.mem.Allocator) void {
        switch (self.*) {
            .multi => |s| {
                for (s.contents.items) |t| {
                    t.deinit(aloc);
                }
            },
            .arr => |s| {
                s.ty.deinit(aloc);
            },
            else => {},
        }
        aloc.destroy(self);
    }
};
