const std = @import("std");
const ast = @import("../parser/AST.zig");
const TysVal = @import("./TypeVals.zig");

const Context = @import("context.zig").Context;

pub fn check(aloc: std.mem.Allocator, block: ast.Node.NodesBlock) void {
    var context = Context{
        .parent = null,
        .symbols = std.StringArrayHashMap(*TysVal.TypeVal).init(aloc),
    };

    // define Global symbols
    context.preDefine("int", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Int = 0 }));
    context.preDefine("float", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Float = 0.0 }));
    context.preDefine("bool", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Bool = false }));
    context.preDefine("str", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Str = "" }));
    context.preDefine("null", TysVal.mkTypeVal(aloc, TysVal.TypeVal{ .Null = {} }));

    // search the main scope block and resolve all symbols
    context.search(block) catch unreachable;

    // once complete, deinit the context since it is no longer needed
    context.symbols.deinit();
}
