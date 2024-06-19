const std = @import("std");
const Context = @import("context.zig").Context;
const TyVals = @import("./typeVals.zig");
const ast = @import("../parser/AST.zig");
const errs = @import("../helper/errors.zig");

pub const TypeChecker = struct {
    parent: ?*TypeChecker,
    alloc: std.mem.Allocator,

    symbols: std.StringArrayHashMap(*TyVals.TypeVal),

    pub fn init(alloc: std.mem.Allocator, parent: ?*TypeChecker) TypeChecker {
        return TypeChecker{
            .parent = parent,
            .alloc = alloc,
            .symbols = std.StringArrayHashMap(*TyVals.TypeVal).init(alloc),
        };
    }

    pub fn resolve(self: *TypeChecker, symbol: []const u8) *TyVals.TypeVal {
        if (self.symbols.get(symbol)) |typeVal| {
            return typeVal;
        } else if (self.parent) |parent| {
            return parent.resolve(symbol);
        } else {
            std.debug.print("Symbol \"{s}\" not found", .{symbol});
            std.process.exit(0);
        }
    }

    pub fn deinit(self: *TypeChecker) void {
        self.symbols.deinit();
        // self.alloc.destroy(self);
    }

    pub fn addContext(self: *TypeChecker, context: Context) void {
        for (context.symbols.keys(), context.symbols.values()) |key, item| {
            std.debug.print("\n{s} -> {any}\n", .{ key, item });
            self.symbols.put(key, @ptrCast(item)) catch unreachable;
        }
    }

    pub fn check(self: *TypeChecker, n: *ast.Node) *TyVals.TypeVal {
        switch (n.*) {
            .Program => |prog| {
                for (prog.body.items.items) |stmt| {
                    _ = self.check(stmt);
                    // res.*.deinit(self.alloc);
                }
                return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Void = {} });
            },
            .Block => |block| {
                var last: ?*TyVals.TypeVal = null;
                for (block.body.items.items) |stmt| {
                    last = self.check(stmt);
                }
                if (last) |ty| return ty else return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Void = {} });
            },
            .VarDecl => |varDecl| {
                var VarTy = self.check(varDecl.type);
                const VarVal = self.check(varDecl.value);

                if (VarTy.isNull()) {
                    VarTy = VarVal;
                }

                // TODO: check if the type of the value matches the type of the variable

                const ty = TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Symbol = .{
                    .name = varDecl.name,
                    .type = TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Variable = .{
                        .value = VarVal,
                        .type = VarTy,
                    } }),
                    .mutable = !varDecl.isConst,
                } });
                self.symbols.put(varDecl.name, ty) catch unreachable;
                return ty;
            },

            .AssignmentExpr => |assign| {
                const left = self.check(assign.lhs);
                const right = self.check(assign.rhs);
                var assignto: []const u8 = undefined;
                var assignable = false;
                switch (left.*) {
                    .Symbol => |symbol| {
                        if (symbol.mutable) {
                            assignable = true;
                            assignto = symbol.name;
                        } else assignable = false;
                    },

                    else => {
                        const loc = assign.lhs.getLoc();
                        errs.printErr(errs.ErrMsg{
                            .line = loc.line,
                            .col = loc.column,
                            .msg = "Cannot assign to this type",
                            .tag = "test",
                            .ErrKind = .Error,
                        });
                        std.process.exit(0);
                    },
                }
                if (!assignable) {
                    const loc = assign.lhs.getLoc();
                    errs.printErr(errs.ErrMsg{
                        .line = loc.line,
                        .col = loc.column,
                        .msg = "Cannot assign to a immutable variable",
                        .tag = "test",
                        .ErrKind = .Error,
                    });
                    std.process.exit(0);
                }

                // TODO check if the type of the value matches the type of the variable

                self.symbols.put(assignto, right) catch unreachable;

                return right;
            },

            .Null => return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Null = {} }),
            .Literal => |lit| {
                switch (lit.type) {
                    .Int => {
                        return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Int = std.fmt.parseInt(i64, lit.value, 10) catch unreachable });
                    },
                    .Float => {
                        return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Float = std.fmt.parseFloat(f64, lit.value) catch unreachable });
                    },
                    .String => {
                        return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Str = lit.value });
                    },
                    .Bool => {
                        return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Bool = std.mem.eql(u8, lit.value, "true") });
                    },
                    .Null => {
                        return TyVals.mkTypeVal(self.alloc, TyVals.TypeVal{ .Null = {} });
                    },
                }
            },

            .MultiSymbol => |multiSym| {
                var syms = std.ArrayList(*TyVals.TypeVal).init(self.symbols.allocator);
                for (multiSym.syms.items.items) |sym| {
                    syms.append(self.check(sym)) catch unreachable;
                }
                return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .MultiSymbol = .{ .symbols = syms } });
            },
            .Param => |param| return self.check(param.value),
            .ArraySymbol => |arraySymbol| return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .ArraySymbol = .{ .size = arraySymbol.size, .symbol = self.check(arraySymbol.sym) } }),

            // already handled by context
            .Symbol => |sym| return self.resolve(sym.name),
            .Identifier => |ident| return self.resolve(ident.name),
            .StructDecl => |structDecl| return self.resolve(structDecl.name),
            .EnumDecl => |enumDecl| return self.resolve(enumDecl.name),

            else => {
                const loc = n.getLoc();
                errs.printErr(errs.ErrMsg{
                    .line = loc.line,
                    .col = loc.column,
                    .tag = "test",
                    .msg = "Type checking not implemented yet for the given node type",
                    .ErrKind = .Error,
                });
                std.process.exit(0);
            },
        }
    }
};
