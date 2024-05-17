const std = @import("std");
const ast = @import("../parser/AST.zig");
const errs = @import("../helper/errors.zig");
const hty = @import("./types.zig");

pub fn typeError(n: *ast.Node, tag: []const u8, alloc: std.mem.Allocator, comptime msg: []const u8, args: anytype) !void {
    const loc = n.getLoc();

    errs.printErr(errs.ErrMsg{
        .line = loc.line,
        .col = loc.column,
        .msg = try std.fmt.allocPrint(alloc, msg, args),
        .tag = tag,
    });
    std.process.exit(0);
}

pub const TypeChecker = struct {
    aloc: std.mem.Allocator,
    tag: []const u8,

    pub fn init(allocator: std.mem.Allocator, tag: []const u8) TypeChecker {
        return TypeChecker{
            .aloc = allocator,
            .tag = tag,
        };
    }

    pub fn mkTy(self: *TypeChecker, ty: hty.ty) *hty.ty {
        const mem = self.aloc.create(hty.ty) catch |err| {
            if (err == std.mem.Allocator.Error.OutOfMemory) std.debug.print("Unable to create Type!", .{});
            std.process.exit(0);
        };
        mem.* = ty;
        return mem;
    }

    pub fn validatePrgm(self: *TypeChecker, prgm: *ast.Node) !void {
        const env = try self.aloc.create(hty.tyEnv);
        var bi = std.ArrayList(*hty.ty).init(self.aloc);
        try bi.append(self.mkTy(hty.ty{ .int = .{} }));
        try bi.append(self.mkTy(hty.ty{ .float = .{} }));
        try bi.append(self.mkTy(hty.ty{ .bool = .{} }));
        try bi.append(self.mkTy(hty.ty{ .str = .{} }));
        try bi.append(self.mkTy(hty.ty{ .null = .{} }));
        env.* = hty.tyEnv{
            .builtIn = bi,
        };
        defer env.*.deinit(self.aloc);

        for (prgm.Program.body.items.items) |n| {
            switch (n.*) {
                .Symbol, .MultiSymbol, .Literal, .ArraySymbol, .VarDecl, .ArrayInit => {
                    const ty = try self.checkNode(n, env.*);
                    ty.deinit(self.aloc);
                },

                else => {},
            }
        }
    }

    pub fn checkNode(self: *TypeChecker, n: *ast.Node, env: hty.tyEnv) !*hty.ty {
        switch (n.*) {
            .Null => return self.mkTy(hty.ty{ .null = .{} }),
            .Literal => |s| {
                switch (s.type) {
                    .Int => return self.mkTy(hty.ty{ .int = .{} }),
                    .Float => return self.mkTy(hty.ty{ .float = .{} }),
                    .Bool => return self.mkTy(hty.ty{ .bool = .{} }),
                    .String => return self.mkTy(hty.ty{ .str = .{} }),
                    .Null => return self.mkTy(hty.ty{ .int = .{} }),
                }
            },
            .Param => |s| {
                return try self.checkNode(s.value, env);
            },
            .Symbol => |s| {
                for (env.builtIn.items) |item| {
                    const str = try item.*.toStr(self.aloc);
                    if (std.mem.eql(u8, s.name, str)) return item;
                }
                try typeError(n, self.tag, self.aloc, "unknown symbol!", .{});
            },
            .MultiSymbol => |s| {
                const syms = s.syms.items.items;
                var contents = std.ArrayList(*hty.ty).init(self.aloc);
                for (syms) |sym| {
                    try contents.append(try self.checkNode(sym, env));
                }
                return self.mkTy(hty.ty{ .multi = .{ .contents = contents } });
            },
            .ArraySymbol => |s| {
                return self.mkTy(hty.ty{ .arr = .{ .size = s.size, .ty = try self.checkNode(s.sym, env) } });
            },
            .ArrayInit => |s| {
                var TypesInContents = std.ArrayList(*hty.ty).init(self.aloc);

                for (s.contents.items.items) |item| {
                    var hasIt = false;
                    const ty = try self.checkNode(item, env);
                    for (TypesInContents.items) |item2| {
                        if (std.mem.eql(u8, try item2.toStr(self.aloc), try ty.toStr(self.aloc))) {
                            hasIt = true;
                            break;
                        }
                    }
                    if (!hasIt) {
                        try TypesInContents.append(ty);
                    }
                }

                if (TypesInContents.items.len == 1) {
                    return self.mkTy(hty.ty{ .arr = .{ .size = s.contents.items.items.len, .ty = TypesInContents.items[0] } });
                } else {
                    return self.mkTy(hty.ty{
                        .arr = .{
                            .size = s.contents.items.items.len,
                            .ty = self.mkTy(hty.ty{ .multi = .{ .contents = TypesInContents } }),
                        },
                    });
                }
            },
            .VarDecl => |s| {
                const expect = try self.checkNode(s.type, env);
                const val = try self.checkNode(s.value, env);
                const exStr = try expect.toStr(self.aloc);
                const valStr = try val.toStr(self.aloc);
                if (!expect.isNull() and !val.isNull()) {
                    switch (expect.*) {
                        .arr => |p| {
                            // _ = p;
                            if (valStr[0] == '[') {
                                if (p.size != 0 and p.size < val.arr.size) try typeError(s.value, self.tag, self.aloc, "oversize array being assigned to an array with a maximum of '{}' size", .{p.size});
                                const ar1 = p.ty;
                                const ar2 = val.arr.ty;
                                //TODO : make it so that it is able to check multiType arrays
                                if (!std.mem.eql(u8, try ar1.toStr(self.aloc), try ar2.toStr(self.aloc))) try typeError(s.value, self.tag, self.aloc, "type of '{s}' cannot be assigned with the array type of '{s}'", .{ valStr, exStr }) else {
                                    return expect;
                                }
                            } else {
                                try typeError(s.value, self.tag, self.aloc, "type of '{s}' cannot be assigned with the array type of '{s}'", .{ valStr, exStr });
                            }
                        },

                        .multi => |p| {
                            _ = p;
                            if (!std.mem.containsAtLeast(u8, exStr, 1, valStr)) {
                                try typeError(s.value, self.tag, self.aloc, "type of '{s}' does not follow the multi type of '{s}'", .{ valStr, exStr });
                            }
                            return expect;
                        },

                        else => {},
                    }
                    if (!std.mem.eql(u8, exStr, valStr)) {
                        try typeError(s.value, self.tag, self.aloc, "miss matched types! trying to assign '{s}' with '{s}' ", .{ exStr, valStr });
                    }
                }
                return expect;
            },

            else => {
                try typeError(n, self.tag, self.aloc, "unknown node while type checking!, {s}", .{try n.fmt(self.aloc)});
                return self.mkTy(hty.ty{ .int = .{} });
            },
        }

        return self.mkTy(hty.ty{ .int = .{} });
    }
};
