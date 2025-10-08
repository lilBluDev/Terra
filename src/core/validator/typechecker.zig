const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("../parser/AST.zig");
const errs = @import("../helper/errors.zig");
const Types = @import("./types.zig").Types;

pub const TypeChecker = struct {
    alloc: std.mem.Allocator,

    parent: ?*TypeChecker,
    enviroment: std.StringArrayHashMap(*Types),
    varTypeList: std.StringArrayHashMap(*Types),
    nonMutList: std.ArrayListAligned([]const u8, null),

    pub fn init(alloc: std.mem.Allocator) TypeChecker {
        return TypeChecker{
            .alloc = alloc,
            .parent = null,
            .enviroment = std.StringArrayHashMap(*Types).init(alloc),
            .varTypeList = std.StringArrayHashMap(*Types).init(alloc),
            .nonMutList = std.ArrayListAligned([]const u8, null).init(alloc),
        };
    }

    pub fn get(self: *TypeChecker, key: []const u8) *Types {
        if (self.enviroment.get(key)) |t| {
            return t;
        } else if (self.parent) |p| {
            return p.get(key);
        } else {
            return self.mkType(Types{ .Void = 0 });
        }
    }

    pub fn registerType(self: *TypeChecker, key: []const u8, Type: Types) *Types {
        const ty = self.mkType(Type);
        self.enviroment.put(key, ty) catch unreachable;
        return ty;
    }

    pub fn registerValType(self: *TypeChecker, key: []const u8, Type: Types) *Types {
        const ty = self.mkType(Type);
        self.varTypeList.put(key, ty) catch unreachable;
        return ty;
    }

    pub fn noMkRegisterType(self: *TypeChecker, key: []const u8, Type: *Types) *Types {
        self.enviroment.put(key, Type) catch unreachable;
        return Type;
    }

    pub fn noMkRegisterValType(self: *TypeChecker, key: []const u8, Type: *Types) *Types {
        self.varTypeList.put(key, Type) catch unreachable;
        return Type;
    }

    pub fn mkType(self: *TypeChecker, Type: Types) *Types {
        const ty = self.alloc.create(Types) catch unreachable;
        ty.* = Type;
        return ty;
    }

    pub fn diter(self: *TypeChecker, n: *ast.Node) *Types {
        if (n.isLiterals()) {
            return check(n, self, self.alloc);
        }

        switch (n.*) {
            .Identifier => |s| return self.get(s.name),
            else => return check(n, self, self.alloc),
        }
    }

    pub fn match(self: *TypeChecker, a: *Types, b: *Types) bool {
        if (a.isPrimitive() and b.isPrimitive()) {
            if (a == b)
                return true;
        } else if (a.isMulti() and b.isPrimitive()) {
            return self.matchMulti(a, b);
        } else if (a.isPrimitive() and b.isMulti()) {
            return self.matchMulti(b, a);
        }
        return false;
    }

    pub fn matchErr(self: *TypeChecker, a: *ast.Node, b: *ast.Node) void {
        var a1 = self.diter(a);
        var b1 = self.diter(b);

        if (!self.match(a1, b1)) {
            const str = std.fmt.allocPrint(std.heap.page_allocator, "Mismatched typed between type \"{s}\" and type \"{s}\"", .{ a1.getName(), b1.getName() }) catch |err| {
                if (err == std.fmt.AllocPrintError.OutOfMemory) {
                    std.debug.print("Failed to print!\n", .{});
                    std.process.exit(0);
                } else {
                    std.debug.print("Failed to print!\n", .{});
                    std.process.exit(0);
                }
            };
            errs.printErr(errs.ErrMsg{
                .msg = str,
                .ErrKind = .Error,
                .ErrType = "MismatchedTypes",
                .tag = lx.parseHead.tag,
                .previewLookBack = 1,
                .col = b.getLoc().column,
                .line = a.getLoc().line,
            });
            std.process.exit(0);
        }
    }

    pub fn getVarType(self: *TypeChecker, key: []const u8) *Types {
        if (self.varTypeList.get(key)) |t| {
            return t;
        } else if (self.parent) |p| {
            return p.get(key);
        } else {
            return self.mkType(Types{ .Void = 0 });
        }
    }

    pub fn matchMulti(self: *TypeChecker, m: *Types, b: *Types) bool {
        _ = self;
        var res = false;
        for (m.MultiSymbol.symbols.items) |s| {
            if (s == b) {
                res = true;
                break;
            }
        }
        return res;
    }

    pub fn matchArray(self: *TypeChecker, a: *Types, b: ast.Node.NodesBlock) *Types {
        for (b.items.items) |t| {
            const ty = check(t, self, self.alloc);
            self.match(a, ty);
        }

        return a;
    }

    pub fn nonMutHas(self: *TypeChecker, k: []const u8) bool {
        var res = false;
        for (self.nonMutList.items) |s| {
            if (std.mem.eql(u8, s, k)) {
                res = true;
                break;
            }
        }
        return res;
    }

    pub fn deinit(self: *TypeChecker) void {
        for (self.enviroment.items) |item| {
            item.deinit();
        }
        self.alloc.destroy(self.enviroment);
    }
};

pub fn checkProgram(prgm: *ast.Node, alloc: std.mem.Allocator) void {
    var Checker = TypeChecker.init(alloc);

    _ = Checker.registerType("int", Types{ .Int = "" });
    _ = Checker.registerType("float", Types{ .Float = "" });
    _ = Checker.registerType("bool", Types{ .Bool = "" });
    _ = Checker.registerType("str", Types{ .Str = "" });
    _ = Checker.registerType("null", Types{ .Null = 0 });
    _ = Checker.registerType("any", Types{ .Null = 0 });
    _ = Checker.registerType("anyerr", Types{ .Null = 0 });
    _ = Checker.registerType("void", Types{ .Void = 0 });

    for (prgm.*.Program.body.items.items) |n| {
        _ = check(n, &Checker, alloc);
    }
}

pub fn check(node: *ast.Node, checker: *TypeChecker, alloc: std.mem.Allocator) *Types {
    switch (node.*) {
        .Null => return checker.get("null"),
        // .ImportStmt => |n| {
        //     for (n.imports.items.items) |i| {
        //         // i.Literal
        //         _ = i;
        //     }
        // },
        .VarDecl => |n| {
            checker.matchErr(n.type, n.value);

            const val = check(n.value, checker, alloc);
            const infered = check(n.type, checker, alloc);

            if (n.isConst) checker.nonMutList.append(n.name) catch unreachable;
            _ = checker.noMkRegisterValType(n.name, infered);
            return checker.noMkRegisterType(n.name, val);
        },
        // .FuncDecl => |n| {
        //     _ = n;
        // },
        .AssignmentExpr => |n| {
            const assignee = checker.diter(n.lhs);
            const val = check(n.rhs, checker, alloc);

            switch (n.lhs.*) {
                .Identifier => |s| {
                    if (checker.nonMutHas(s.name)) {
                        const str = std.fmt.allocPrint(std.heap.page_allocator, "Variable \"{s}\" is immutable and cannot be changed", .{assignee.getName()}) catch |err| {
                            if (err == std.fmt.AllocPrintError.OutOfMemory) {
                                std.debug.print("Failed to print!\n", .{});
                                std.process.exit(0);
                            } else {
                                std.debug.print("Failed to print!\n", .{});
                                std.process.exit(0);
                            }
                        };
                        errs.printErr(errs.ErrMsg{
                            .msg = str,
                            .ErrKind = .Error,
                            .ErrType = "InvalidAssignment",
                            .tag = lx.parseHead.tag,
                            .previewLookBack = 1,
                            .col = n.lhs.getLoc().column,
                            .line = n.loc.line,
                        });
                        std.process.exit(0);
                    }

                    const reg = checker.getVarType(s.name);

                    if (!checker.match(reg, val)) {
                        const str = std.fmt.allocPrint(std.heap.page_allocator, "Mismatched type between type \"{s}\" and type \"{s}\"", .{ assignee.getName(), val.getName() }) catch |err| {
                            if (err == std.fmt.AllocPrintError.OutOfMemory) {
                                std.debug.print("Failed to print!\n", .{});
                                std.process.exit(0);
                            } else {
                                std.debug.print("Failed to print!\n", .{});
                                std.process.exit(0);
                            }
                        };
                        errs.printErr(errs.ErrMsg{
                            .msg = str,
                            .ErrKind = .Error,
                            .ErrType = "MismatchedTypes",
                            .tag = lx.parseHead.tag,
                            .previewLookBack = 1,
                            .col = n.rhs.getLoc().column,
                            .line = n.loc.line,
                        });
                        std.process.exit(0);
                    }

                    _ = checker.noMkRegisterType(s.name, val);
                },
                else => {
                    checker.matchErr(n.lhs, n.rhs);
                },
            }

            return val;
        },
        .BinaryExpr => |n| {
            checker.matchErr(n.left, n.right);
            var lhs = check(n.left, checker, alloc);
            var rhs = check(n.right, checker, alloc);

            _ = rhs.getName();
            return checker.get(lhs.getName());
        },
        .Literal => |n| {
            switch (n.type) {
                .Int => return checker.get("int"),
                .Float => return checker.get("float"),
                .Bool => return checker.get("bool"),
                .String => return checker.get("str"),
                .Null => return checker.get("null"),
            }
        },
        .Symbol => |n| {
            if (!checker.enviroment.contains(n.name)) {
                const str = std.fmt.allocPrint(std.heap.page_allocator, "Unknown value \"{s}\" found!", .{n.name}) catch |err| {
                    if (err == std.fmt.AllocPrintError.OutOfMemory) {
                        std.debug.print("Failed to print!\n", .{});
                        std.process.exit(0);
                    } else {
                        std.debug.print("Failed to print!\n", .{});
                        std.process.exit(0);
                    }
                };
                errs.printErr(errs.ErrMsg{ .msg = str, .ErrKind = .Error, .ErrType = "UnknownValue", .tag = lx.parseHead.tag, .previewLookBack = 1, .col = n.loc.column, .line = n.loc.line });
                std.process.exit(0);
            }

            return checker.get(n.name);
        },
        .Identifier => |n| {
            if (!checker.enviroment.contains(n.name)) {
                const str = std.fmt.allocPrint(std.heap.page_allocator, "Unknown value \"{s}\" found!", .{n.name}) catch |err| {
                    if (err == std.fmt.AllocPrintError.OutOfMemory) {
                        std.debug.print("Failed to print!\n", .{});
                        std.process.exit(0);
                    } else {
                        std.debug.print("Failed to print!\n", .{});
                        std.process.exit(0);
                    }
                };
                errs.printErr(errs.ErrMsg{ .msg = str, .ErrKind = .Error, .ErrType = "UnknownValue", .tag = lx.parseHead.tag, .previewLookBack = 1, .col = n.loc.column, .line = n.loc.line });
                std.process.exit(0);
            }

            return checker.get(n.name);
        },
        .MultiSymbol => |n| {
            var arr = std.ArrayList(*Types).init(alloc);
            for (n.syms.items.items) |s| {
                arr.append(check(s, checker, alloc)) catch unreachable;
            }
            return checker.mkType(Types{ .MultiSymbol = .{ .symbols = arr.clone() catch unreachable } });
        },
        else => {
            return checker.get("null");
        },
    }
}
