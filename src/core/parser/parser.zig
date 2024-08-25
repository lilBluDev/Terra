const std = @import("std");
const lx = @import("../lexer/lexer.zig");
const tk = @import("../lexer/tokens.zig");
const ast = @import("./AST.zig");
const errs = @import("../helper/errors.zig");

pub const expr = @import("./expr.zig");
pub const stmt = @import("./stmt.zig");

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

    pub fn mkNull(self: *Parser) *ast.Node {
        const n = self.aloc.create(ast.Node) catch unreachable;
        n.* = ast.Node{ .Null = .{} };
        return n;
    }

    pub fn advance(self: *Parser) tk.Token {
        const tkn = self.tks.items[self.pos];
        self.pos += 1;
        return tkn;
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

    pub fn expectAndAdvance(self: *Parser, t: tk.TokenType) tk.Token {
        self.expectError(t);
        return self.advance();
    }

    pub fn expectError(self: *Parser, t: tk.TokenType) void {
        const curr = self.currentToken();
        if (curr.token_type != t) {
            const str = std.fmt.allocPrint(std.heap.page_allocator, "Expected '{s}' but got '{s}'", .{ tk.TokenType2String(t), tk.TokenType2String(self.currentTokenType()) }) catch |err| {
                if (err == std.fmt.AllocPrintError.OutOfMemory) {
                    std.debug.print("Failed to print!\n", .{});
                    return;
                } else {
                    std.debug.print("Failed to print!\n", .{});
                    return;
                }
            };

            errs.printErr(errs.ErrMsg{
                .line = curr.loc.line,
                .col = curr.loc.column,
                .tag = self.lx.tag,
                .msg = str,
                .ErrType = "UnexpectedToken",
                .ErrKind = .Error,
                .previewLookBack = null,
            });

            std.process.exit(0);
        }
    }

    pub fn parse(self: *Parser, tag: []const u8) !*ast.Node {
        const prgm = self.mkNode(ast.Node{
            .Program = .{
                .tag = tag,
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

    pub fn parseBlock(self: *Parser) !*ast.Node {
        const start = self.expectAndAdvance(.LeftBrace);
        var body = std.ArrayListAligned(*ast.Node, null).init(self.aloc);
        while (!self.currentToken().is(.RightBrace) and !self.currentToken().is(.EOF)) {
            const n = try stmt.parseStmt(self);
            try body.append(n);
        }
        _ = self.expectAndAdvance(.RightBrace);

        return self.mkNode(ast.Node{ .Block = .{
            .body = ast.Node.NodesBlock{ .items = body },
            .loc = self.combineLoc(start.loc, self.prev().loc),
        } });
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
