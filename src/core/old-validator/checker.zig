const std = @import("std");
const ast = @import("../parser/AST.zig");
const TysVal = @import("./TypeVals.zig");

const Context = @import("context.zig").Context;
const TyChecker = @import("typeValidator.zig").TypeChecker;

pub fn check(aloc: std.mem.Allocator, n: *ast.Node) void {
    // global context
    var context = Context{
        // .parent = null,
        .symbols = Context.strHasMap.init(aloc),
    };

    // define Global symbols
    context.preDefine("int", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Int = 0 }));
    context.preDefine("float", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Float = 0.0 }));
    context.preDefine("bool", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Bool = false }));
    context.preDefine("str", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Str = "" }));
    context.preDefine("null", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Null = {} }));
    context.preDefine("void", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Void = {} }));

    // search the main scope block and resolve all symbols
    context.search(n.*.Program.body) catch unreachable;
    defer context.symbols.deinit();

    var checker = TyChecker.init(aloc, null);
    checker.addContext(context);
    defer checker.deinit();

    var final = checker.check(n);

    std.debug.print("Result: \n", .{});
    for (checker.symbols.keys(), checker.symbols.values()) |key, item| {
        std.debug.print("\n{s} -> {any}", .{ key, item });
    }
    // std.debug.print("\n", .{});

    final.deinit(aloc);
}
