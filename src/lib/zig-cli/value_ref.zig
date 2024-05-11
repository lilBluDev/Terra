const std = @import("std");
const command = @import("./command.zig");
const vp = @import("./value_parser.zig");
const Allocator = std.mem.Allocator;

pub const ValueRef = struct {
    dest: *anyopaque,
    value_data: vp.ValueData,
    value_type: ValueType,
    element_count: usize = 0,

    const Self = @This();

    pub fn put(self: *Self, value: []const u8, alloc: Allocator) anyerror!void {
        self.element_count += 1;
        switch (self.value_type) {
            .single => {
                return self.value_data.value_parser(self.dest, value);
            },
            .multi => |*list| {
                if (list.list_ptr == null) {
                    list.list_ptr = try list.vtable.createList(alloc);
                }
                const value_ptr = try list.vtable.addOne(list.list_ptr.?, alloc);
                try self.value_data.value_parser(value_ptr, value);
            },
        }
    }

    pub fn finalize(self: *Self, alloc: Allocator) anyerror!void {
        switch (self.value_type) {
            .single => {},
            .multi => |*list| {
                if (list.list_ptr == null) {
                    list.list_ptr = try list.vtable.createList(alloc);
                }
                try list.vtable.finalize(list.list_ptr.?, self.dest, alloc);
            },
        }
    }
};

pub const ValueType = union(enum) {
    single,
    multi: ValueList,
};

const AllocError = Allocator.Error;
pub const Error = AllocError; // | error{NotImplemented};

pub fn mkRef(dest: anytype) ValueRef {
    const ti = @typeInfo(@TypeOf(dest));
    const t = ti.Pointer.child;

    switch (@typeInfo(t)) {
        .Pointer => |pinfo| {
            switch (pinfo.size) {
                .Slice => {
                    if (pinfo.child == u8) {
                        return ValueRef{
                            .dest = @ptrCast(dest),
                            .value_data = vp.getValueData(t),
                            .value_type = .single,
                        };
                    } else {
                        return ValueRef{
                            .dest = @ptrCast(dest),
                            .value_data = vp.getValueData(pinfo.child),
                            .value_type = ValueType{ .multi = ValueList.init(pinfo.child) },
                        };
                    }
                },
                else => @compileError("unsupported value type: only slices are supported"),
            }
        },
        else => {
            return ValueRef{
                .dest = dest,
                .value_data = vp.getValueData(t),
                .value_type = .single,
            };
        },
    }
}

const ValueList = struct {
    list_ptr: ?*anyopaque = null,
    vtable: VTable,

    const VTable = struct {
        createList: *const fn (Allocator) anyerror!*anyopaque,
        addOne: *const fn (list_ptr: *anyopaque, alloc: Allocator) anyerror!*anyopaque,
        finalize: *const fn (list_ptr: *anyopaque, dest: *anyopaque, alloc: Allocator) anyerror!void,
    };

    fn init(comptime T: type) ValueList {
        const List = std.ArrayListUnmanaged(T);
        const gen = struct {
            fn createList(alloc: Allocator) anyerror!*anyopaque {
                const list = try alloc.create(List);
                list.* = List{};
                return list;
            }
            fn addOne(list_ptr: *anyopaque, alloc: Allocator) anyerror!*anyopaque {
                const list: *List = @alignCast(@ptrCast(list_ptr));
                return @ptrCast(try list.addOne(alloc));
            }
            fn finalize(list_ptr: *anyopaque, dest: *anyopaque, alloc: Allocator) anyerror!void {
                const list: *List = @alignCast(@ptrCast(list_ptr));
                const destSlice: *[]T = @alignCast(@ptrCast(dest));
                destSlice.* = try list.toOwnedSlice(alloc);
                alloc.destroy(list);
            }
        };
        return ValueList{ .vtable = VTable{
            .createList = gen.createList,
            .addOne = gen.addOne,
            .finalize = gen.finalize,
        } };
    }
};
