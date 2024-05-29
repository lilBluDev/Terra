const std = @import("std");

pub const TypeVal = union(enum) {
    //SECTION - Primitives
    Int: i64,
    Float: f64,
    Bool: bool,
    Str: []const u8,
    Null: void,
    Void: void,

    VarSymbol: struct {
        name: []const u8,
        value: *TypeVal,
        type: *TypeVal,
        mutable: bool,
    },
    Symbol: struct {
        name: []const u8,
        type: *TypeVal,
        mutable: bool,
    },
    MultiSymbol: struct {
        symbols: std.ArrayList(*TypeVal),
    },
    ArraySymbol: struct {
        size: usize,
        symbol: *TypeVal,
    },
    Struct: struct {
        items: std.StringArrayHashMap(*TypeVal),
    },
    Enum: struct {
        items: std.StringArrayHashMap(*TypeVal),
    },

    pub const internal = std.ArrayList(*TypeVal);

    pub fn is(self: *TypeVal, T: *TypeVal) bool {
        return std.mem.eql(u8, self.str(), T.str());
    }

    pub fn isNull(self: *TypeVal) bool {
        switch (self.*) {
            .Null => return true,
            else => return false,
        }
    }

    pub fn str(self: *TypeVal) []const u8 {
        switch (self.*) {
            else => |n| return @tagName(n),
        }
    }

    pub fn deinit(self: *TypeVal, aloc: std.mem.Allocator) void {
        switch (self.*) {
            .VarSymbol => |varSymbol| {
                varSymbol.type.deinit(aloc);
                varSymbol.value.deinit(aloc);
            },
            .Symbol => |sym| {
                sym.type.deinit(aloc);
            },
            .MultiSymbol => |multiSymbol| {
                for (multiSymbol.symbols.items) |item| item.deinit(aloc);
                multiSymbol.symbols.deinit();
            },
            .ArraySymbol => |arraySymbol| {
                arraySymbol.symbol.deinit(aloc);
            },

            .Struct => |struct_| {
                for (struct_.items.values()) |item| item.deinit(aloc);
                // struct_.items.deinit();
            },
            .Enum => |enum_| {
                for (enum_.items.values()) |item| item.deinit(aloc);
                // enum_.items.deinit();
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
