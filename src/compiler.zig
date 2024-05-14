const std = @import("std");
const lexer = @import("./core/lexer/lexer.zig");
// const new_lexer = @import("./core/lexer/nLexer.zig").ParseHead;
const parser = @import("./core/parser/parser.zig");
const typeChecker = @import("./core/validator/typechecker.zig");
const LUs = @import("./core/parser/lookUps.zig");
const TLUs = @import("./core/parser/typesLus.zig");
const ntv = @import("./core/helper/nodeTreeVisualizer.zig");
const ast = @import("./core/parser/AST.zig");

pub const TerraC = struct {
    aloc: std.mem.Allocator,

    pub fn init(aloc: std.mem.Allocator) TerraC {
        LUs.loadLUs();
        TLUs.loadLUs();
        return TerraC{
            .aloc = aloc,
        };
    }

    pub fn parseSingle(self: *const TerraC, source: []const u8, tag: []const u8) !*ast.Node {
        lexer.Init(tag, source);
        const tokens = try lexer.startLexer();
        var parserInst = parser.Parser.init(self.aloc, tokens);
        const prgm = try parserInst.parse(tag);
        var tc = typeChecker.TypeChecker.init(self.aloc, tag);
        try tc.validatePrgm(prgm);
        return prgm;
    }
};
