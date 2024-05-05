const std = @import("std");
const lexer = @import("./core/lexer/lexer.zig");
const parser = @import("./core/parser/parser.zig");
const LUs = @import("./core/parser/lookUps.zig");

pub const TerraC = struct {
    aloc: std.mem.Allocator,

    pub fn init(aloc: std.mem.Allocator) TerraC {
        LUs.loadLUs();
        return TerraC{
            .aloc = aloc,
        };
    }

    pub fn parseSingle(self: *const TerraC, source: []const u8) !void {
        // _ = self;
        lexer.Init(source);
        const token = try lexer.startLexer();
        var parserInst = parser.Parser.init(self.aloc, token);
        const prgm = try parserInst.parse();
        defer prgm.deinit(self.aloc);

        // std.debug.print("Token: {any}\n", .{token.items});
        std.debug.print("{any}\n", .{prgm.Program.body.items.items[0]});
    }
};
