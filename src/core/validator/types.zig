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
    multi: struct { contents: std.ArrayList(*ty) },
    arr: struct {
        size: usize,
        ty: *ty,
    },

    pub fn toStr(self: *ty) []const u8 {
        switch (self.*) {
            .str => return "str",
            .int => return "int",
            .float => return "float",
            .bool => return "bool",
            else => return "*",
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
