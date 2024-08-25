const std = @import("std");
const lexer = @import("./core/lexer/lexer.zig");
const TKVisualizer = @import("./core/helper/TokenVisualizer.zig").VisualizeToken;
const parser = @import("./core/parser/parser.zig");
const checker = @import("./core/validator/typechecker.zig");
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

    pub fn parseSingle(self: *const TerraC, source: []const u8, tag: []const u8, DBToken: bool) !*ast.Node {
        lexer.Init(tag, source);
        const tokens = try lexer.startLexer();
        if (DBToken)
            try TKVisualizer(tokens);
        var parserInst = parser.Parser.init(self.aloc, tokens);
        const prgm = try parserInst.parse(tag);
        checker.checkProgram(prgm, self.aloc);
        return prgm;
    }
};
