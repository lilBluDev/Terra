const std = @import("std");

pub const TypeVal = union(enum) {
    //SECTION - Primitives
    Int: i64,
    Float: f64,
    Bool: bool,
    Str: []const u8,
    Null: void,

    Symbol: struct {
        name: []const u8,
        type: *TypeVal,
        mutable: bool,
    },
    Struct: struct {
        items: std.StringArrayHashMap(*TypeVal),
    },
    Enum: struct {
        items: std.StringArrayHashMap(*TypeVal),
    },

    pub const internal = std.ArrayList(*TypeVal);

    pub fn is(self: *TypeVal, T: *TypeVal) bool {
        switch (self.*) {
            else => |a| {
                switch (T.*) {
                    else => |b| {
                        return @tagName(a) == @tagName(b);
                    },
                }
            },
        }
    }

    pub fn deinit(self: *TypeVal, aloc: std.mem.Allocator) void {
        switch (self.*) {
            .Symbol => |sym| {
                sym.type.deinit(aloc);
            },
            .Struct => |struct_| {
                for (struct_.items.values()) |item| item.deinit(aloc);
                struct_.items.deinit(aloc);
            },
            .Enum => |enum_| {
                for (enum_.items.items) |item| item.deinit(aloc);
                enum_.items.deinit(aloc);
            },
            else => {},
        }

        aloc.destroy(self);
    }
};

pub fn mkTypeVal(aloc: std.mem.Allocator, val: TypeVal) *TypeVal {
    const res = aloc.create(TypeVal) catch unreachable;
    res.* = val;
    return res;
}
