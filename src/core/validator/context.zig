const std = @import("std");
const ast = @import("../parser/AST.zig");
const TyVals = @import("../validator/TypeVals.zig");

pub const Context = struct {
    pub const strHasMap = std.StringArrayHashMap(*TyVals.TypeVal);

    symbols: strHasMap,

    pub fn resolve(self: *Context, symbol: []const u8) ?*TyVals.TypeVal {
        return self.symbols.get(symbol);
    }

    pub fn preDefine(self: *Context, symbol: []const u8, typeVal: *TyVals.TypeVal) void {
        self.symbols.put(symbol, typeVal) catch unreachable;
    }

    pub fn whatIs(self: *Context, n: *ast.Node) *TyVals.TypeVal {
        switch (n.*) {
            .Identifier => |ident| {
                if (self.resolve(ident.name)) |typeVal| {
                    return typeVal;
                } else {
                    std.debug.print("Symbol \"{s}\" not found", .{ident.name});
                    std.process.exit(0);
                }
            },
            .Symbol => |sym| {
                if (self.resolve(sym.name)) |typeVal| {
                    return typeVal;
                } else {
                    std.debug.print("Symbol \"{s}\" not found", .{sym.name});
                    std.process.exit(0);
                }
            },
            .MultiSymbol => |multiSym| {
                var syms = std.ArrayList(*TyVals.TypeVal).init(self.symbols.allocator);
                for (multiSym.syms.items.items) |sym| {
                    syms.append(self.whatIs(sym)) catch unreachable;
                }
                return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .MultiSymbol = .{ .symbols = syms } });
            },
            .MemberExpr => |member| {
                return self.whatIs(member.member);
            },

            .Literal => |lit| {
                switch (lit.type) {
                    .Int => {
                        return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Int = std.fmt.parseInt(i64, lit.value, 10) catch unreachable });
                    },
                    .Float => {
                        return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Float = std.fmt.parseFloat(f64, lit.value) catch unreachable });
                    },
                    .Bool => {
                        return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Bool = std.mem.eql(u8, lit.value, "true") });
                    },
                    .String => {
                        return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Str = lit.value });
                    },
                    .Null => {
                        return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Null = {} });
                    },
                }
            },

            .ArraySymbol => |arraySymbol| return TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .ArraySymbol = .{ .size = arraySymbol.size, .symbol = self.whatIs(arraySymbol.sym) } }),

            else => |p| {
                std.debug.print("Cannot define the type of \"{s}\"", .{@tagName(p)});
                std.process.exit(0);
            },
        }
    }

    pub fn search(self: *Context, block: ast.Node.NodesBlock) !void {
        for (block.items.items) |node| {
            switch (node.*) {
                .StructDecl => |decl| {
                    var items = std.StringArrayHashMap(*TyVals.TypeVal).init(self.symbols.allocator);

                    for (decl.fields.items.items) |field| {
                        switch (field.*) {
                            .Param => |param| {
                                const ty = self.whatIs(param.value);
                                items.put(param.key, ty) catch unreachable;
                            },

                            else => {},
                        }
                    }

                    self.symbols.put(decl.name, TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Symbol = .{
                        .name = decl.name,
                        .type = TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{
                            .Struct = .{ .items = items },
                        }),
                        .mutable = true,
                    } })) catch unreachable;
                },

                .EnumDecl => |decl| {
                    var items = std.StringArrayHashMap(*TyVals.TypeVal).init(self.symbols.allocator);
                    for (0.., decl.fields.items.items) |i, field| {
                        switch (field.*) {
                            .Param => |param| {
                                const ty = TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Int = i });
                                items.put(param.key, ty) catch unreachable;
                            },
                            else => {},
                        }
                    }

                    self.symbols.put(decl.name, TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{ .Symbol = .{
                        .name = decl.name,
                        .type = TyVals.mkTypeVal(self.symbols.allocator, TyVals.TypeVal{
                            .Enum = .{ .items = items },
                        }),
                        .mutable = true,
                    } })) catch unreachable;
                },

                else => {},
            }
        }
    }
};
