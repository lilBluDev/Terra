const std = @import("std");
const tk = @import("tokens.zig");

const isDigit = std.ascii.isDigit;
const isAlpha = std.ascii.isAlphabetic;
const isAlphaNum = std.ascii.isAlphanumeric;

pub const tokensList = std.ArrayListAligned(tk.Token, null);
pub const ParseHead = struct {
    aloc: std.mem.Allocator,

    source: []const u8,
    start: []const u8,
    original: []const u8,
    line: usize,
    column: usize,

    pub fn isEnd(self: *ParseHead) bool {
        return self.source.len <= 0;
    }

    pub fn consume(self: *ParseHead) u8 {
        if (self.isEnd()) return 225;
        const res = self.source[0];
        self.source = self.source[1..];
        if (res == '\n') {
            self.line += 1;
            self.column = 0;
        } else self.column += 1;
        return res;
    }

    pub fn peek(self: *ParseHead) u8 {
        if (self.isEnd()) return 0;
        return self.source[0];
    }

    pub fn getSliceUntil(self: *ParseHead, delimiter: u8) []const u8 {
        while (!self.isEnd() and self.peek() != delimiter) {
            _ = self.consume();
            if (self.peek() == delimiter) {
                _ = self.consume();
                break;
            }
        }

        return self.start[0 .. self.start.len - self.source.len];
    }

    pub fn getLocWhole(self: *ParseHead) struct { line: usize, column: usize } {
        return .{ .line = self.line, .column = self.column };
    }

    pub fn parseStr(self: *ParseHead) tk.Token {
        const start = self.getLocWhole();
        const delimiter = self.consume();
        const str = self.getSliceUntil(delimiter);
        return tk.Token{
            .token_type = tk.TokenType.StringLit,
            .value = str[1 .. str.len - 1],
            .loc = .{
                .line = start.line,
                .column = start.column,
                .end_col = self.column - 1,
                .end_line = self.line,
            },
        };
    }

    pub fn parseNum(self: *ParseHead) tk.Token {
        const start = self.getLocWhole();
        while (!self.isEnd() and isDigit(self.peek())) {
            _ = self.consume();
        }
        if (self.peek() == '.') {
            _ = self.consume();
            while (!self.isEnd() and isDigit(self.peek())) {
                _ = self.consume();
            }
        }
        const num = self.start[0 .. self.start.len - self.source.len];
        return tk.Token{
            .token_type = tk.TokenType.StringLit,
            .value = num,
            .loc = .{
                .line = start.line,
                .column = start.column,
                .end_col = self.column - 1,
                .end_line = self.line,
            },
        };
    }

    pub fn parseIdent(self: *ParseHead) tk.Token {
        const start = self.getLocWhole();
        _ = self.consume();
        while (!self.isEnd() and isAlphaNum(self.peek())) {
            _ = self.consume();
        }
        const ident = self.start[0 .. self.start.len - self.source.len];
        if (tk.reserved_lu.get(ident)) |tt| {
            return tk.Token{
                .token_type = tt,
                .value = ident,
                .loc = .{
                    .line = start.line,
                    .column = start.column,
                    .end_col = self.column - 1,
                    .end_line = self.line,
                },
            };
        }
        return tk.Token{
            .token_type = tk.TokenType.Identifier,
            .value = ident,
            .loc = .{
                .line = start.line,
                .column = start.column,
                .end_col = self.column - 1,
                .end_line = self.line,
            },
        };
    }

    // pub fn parseWhitespace(self: *ParseHead, c: u8) void {
    //     switch (c) {
    //         '\n', '\t', ' ', '\u{13}' => _ = self.consume(),
    //         else => {},
    //     }
    // }

    pub fn parseTkn(self: *ParseHead) tk.Token {
        self.start = self.source;
        const start = self.getLocWhole();
        const c = self.peek();
        while (self.peek() == '\n' or
            self.peek() == '\t' or
            self.peek() == '\r' or
            self.peek() == ' ' or
            self.peek() == '\u{13}' or
            self.peek() == '\u{32}')
        {
            _ = self.consume();
        }

        if (c == '"') {
            return self.parseStr();
        } else if (isDigit(c)) {
            return self.parseNum();
        } else if (isAlpha(c)) {
            return self.parseIdent();
        }

        const dTemp = self.source[0..1];

        if (tk.double_opreator_lu.get(dTemp)) |tt| {
            _ = self.consume();
            _ = self.consume();
            return tk.Token{ .token_type = tt, .value = dTemp, .loc = .{
                .line = start.line,
                .column = start.column,
                .end_col = start.column,
                .end_line = start.line,
            } };
        }

        if (tk.single_operator_lu.get(&[_]u8{c})) |tt| {
            _ = self.consume();
            return tk.Token{ .token_type = tt, .value = &[_]u8{c}, .loc = .{
                .line = start.line,
                .column = start.column,
                .end_col = start.column,
                .end_line = start.line,
            } };
        }
        std.debug.print("{}\n", .{self.peek()});

        _ = self.consume();
        return tk.Token{ .token_type = tk.TokenType.Unknown, .value = &[_]u8{c}, .loc = .{
            .line = start.line,
            .column = start.column,
            .end_col = start.column,
            .end_line = start.line,
        } };
    }

    pub fn parseWhole(self: *ParseHead) !tokensList {
        var tokens = std.ArrayListAligned(tk.Token, null).init(self.aloc);
        while (!self.isEnd()) {
            const tkn = self.parseTkn();
            try tokens.append(tkn);
            if (self.isEnd()) break;
        }

        try tokens.append(tk.Token{
            .token_type = tk.TokenType.EOF,
            .value = "EOF",
            .loc = .{
                .line = self.line,
                .column = self.column,
                .end_col = self.column,
                .end_line = self.line,
            },
        });

        return tokens;
    }

    pub fn getline(self: ParseHead, line: usize) []const u8 {
        const split = std.mem.split(u8, self.original, "\n");
        var i: usize = 0;
        while (split.next()) |str| {
            i += 1;
            if (i == line) {
                return str;
            }
        }
    }

    pub fn init(aloc: std.mem.Allocator, source: []const u8) ParseHead {
        return ParseHead{
            .aloc = aloc,

            .source = source,
            .start = source,
            .original = source,
            .line = 1,
            .column = 1,
        };
    }
};
