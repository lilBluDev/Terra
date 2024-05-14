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
        env.* = hty.tyEnv{
            .builtIn = bi,
        };
        defer env.*.deinit(self.aloc);

        for (prgm.Program.body.items.items) |n| {
            switch (n.*) {
                .Symbol, .MultiSymbol, .Literal, .ArraySymbol, .VarDecl => {
                    const ty = try self.checkNode(n, env.*);
                    ty.deinit(self.aloc);
                },

                else => {},
            }
        }
    }

    pub fn checkNode(self: *TypeChecker, n: *ast.Node, env: hty.tyEnv) !*hty.ty {
        switch (n.*) {
            .Literal => |s| {
                switch (s.type) {
                    .Int => return self.mkTy(hty.ty{ .int = .{} }),
                    .Float => return self.mkTy(hty.ty{ .float = .{} }),
                    .Bool => return self.mkTy(hty.ty{ .bool = .{} }),
                    .String => return self.mkTy(hty.ty{ .str = .{} }),
                    .Null => return self.mkTy(hty.ty{ .int = .{} }),
                }
            },
            .Symbol => |s| {
                for (env.builtIn.items) |item| {
                    const str = item.*.toStr();
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
            .VarDecl => |s| {
                const expect = try self.checkNode(s.type, env);
                const val = try self.checkNode(s.value, env);
                if (!std.mem.eql(u8, expect.toStr(), val.toStr())) {
                    try typeError(s.value, self.tag, self.aloc, "miss matched types! trying to assign {s} with {s}", .{ expect.toStr(), val.toStr() });
                }
                return expect;
            },

            else => {
                try typeError(n, self.tag, self.aloc, "unknown node while type checking!", .{});
                return self.mkTy(hty.ty{ .int = .{} });
            },
        }

        return self.mkTy(hty.ty{ .int = .{} });
    }
};
