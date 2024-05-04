const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("./AST.zig");
const stmt = @import("./stmt.zig");

pub const Parser = struct {
    aloc: std.mem.Allocator,
    tks: lx.tokensList,
    lx: lx.ParseHead,

    pos: usize,

    pub fn init(aloc: std.mem.Allocator, tks: lx.tokensList) Parser {
        return Parser{ .aloc = aloc, .tks = tks, .lx = lx.parseHead, .pos = 0 };
    }

    pub fn mkNode(self: *Parser, t: ast.Node) *ast.Node {
        const n = self.aloc.create(ast.Node) catch unreachable;
        n.* = t;
        return n;
    }

    pub fn advance(self: *Parser) tk.Token {
        self.pos += 1;
        return self.currentToken();
    }

    pub fn prev(self: *Parser) tk.Token {
        return self.tks.items[self.pos - 1];
    }

    pub fn next(self: *Parser) tk.Token {
        return self.tks.items[self.pos + 1];
    }

    pub fn currentToken(self: *Parser) tk.Token {
        return self.tks.items[self.pos];
    }

    pub fn currentTokenType(self: *Parser) tk.TokenType {
        return self.tks.items[self.pos].token_type;
    }

    pub fn parse(self: *Parser) !*ast.Node {
        const prgm = self.mkNode(ast.Node{
            .Program = .{
                .body = ast.Node.NodesBlock{ .items = std.ArrayListAligned(*ast.Node, null).init(self.aloc) },
                .loc = self.combineLoc(self.currentToken().loc, self.tks.items[self.tks.items.len - 1].loc),
            },
        });

        while (self.currentTokenType() != tk.TokenType.EOF) {
            const stm = try stmt.parseStmt(self);
            prgm.Program.body.items.append(stm) catch unreachable;
        }

        return prgm;
    }

    pub fn combineLoc(self: *Parser, start: tk.loc, end: tk.loc) tk.loc {
        _ = self;
        return tk.loc{
            .line = start.line,
            .column = start.column,
            .end_col = end.end_col,
            .end_line = end.end_line,
        };
    }
};
