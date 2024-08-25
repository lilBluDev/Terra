const std = @import("std");
const String = @import("string").String;

pub const Types = union(enum) {
    //SECTION - Primitives
    Int: []const u8,
    Float: []const u8,
    Bool: []const u8,
    Str: []const u8,
    Null: i2,
    Void: i2,

    Function: struct {
        params: std.ArrayList(*Types),
        outType: *Types,
    },
    NameVal: struct {
        name: []const u8,
        value: *Types,
    },
    Symbol: struct {
        name: []const u8,
        type: *Types,
        mutable: bool,
    },
    MultiSymbol: struct {
        symbols: std.ArrayList(*Types),
    },
    ArraySymbol: struct {
        size: usize,
        symbol: *Types,
    },

    pub fn getName(self: *Types) []const u8 {
        switch (self.*) {
            .Int => return "int",
            .Float => return "float",
            .Bool => return "bool",
            .Str => return "str",
            .Null => return "null",
            .Void => return "void",
            .MultiSymbol => |n| {
                var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
                // defer arena.deinit();
                var Str = String.init(arena.allocator());
                Str.setStr("Multi<") catch unreachable;
                for (n.symbols.items, 0..) |s, i| {
                    Str.concat(s.getName()) catch unreachable;
                    if (i != n.symbols.items.len - 1) Str.concat(",") catch unreachable;
                }
                Str.concat(">") catch unreachable;
                return Str.str();
            },
            else => return "O",
        }
    }

    pub fn isPrimitive(self: *Types) bool {
        switch (self.*) {
            .Int, .Float, .Bool, .Str, .Null, .Void => return true,
            else => return false,
        }
    }

    pub fn isMulti(self: *Types) bool {
        switch (self.*) {
            .MultiSymbol => return true,
            else => return false,
        }
    }

    pub fn isNameVal(self: *Types) bool {
        switch (self.*) {
            .NameVal => return true,
            else => return false,
        }
    }

    pub fn deinit(self: *Types, alloc: std.mem.Allocator) void {
        switch (self.*) {
            .Function => |function| {
                for (function.params.items) |param| param.deinit(alloc);
            },
            .NameVal => |variable| {
                variable.value.deinit(alloc);
            },
            .Symbol => |sym| {
                sym.type.deinit(alloc);
            },
            .MultiSymbol => |multiSymbol| {
                for (multiSymbol.symbols.items) |item| item.deinit(alloc);
                multiSymbol.symbols.deinit();
            },
            .ArraySymbol => |arraySymbol| {
                arraySymbol.symbol.deinit(alloc);
            },
        }
    }
};
