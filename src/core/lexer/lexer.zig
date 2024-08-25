const std = @import("std");
const errs = @import("../helper/errors.zig");

const page_allocator = std.heap.page_allocator;
const Allocator = std.mem.Allocator;

const tk = @import("tokens.zig");

const isDigit = std.ascii.isDigit;
const isAlpha = std.ascii.isAlphabetic;
const isAlphaNum = std.ascii.isAlphanumeric;

pub const ParseHead = struct {
    tag: []const u8,
    source: []const u8,
    start: []const u8,
    original: []const u8,
    loc: struct {
        line: usize,
        column: usize,
    },
};

pub var parseHead: ParseHead = undefined;

fn consume() ?u8 {
    if (isEnd()) return null;
    const res = parseHead.source[0];
    parseHead.loc.column += 1;
    parseHead.source = parseHead.source[1..];
    // parseHead.pos += 1;
    return res;
}

fn peek() ?u8 {
    if (0 >= parseHead.source.len) return null;
    return parseHead.source[0];
}

fn peek_next() ?u8 {
    if (1 >= parseHead.source.len) return null;
    return parseHead.source[1];
}

fn isEnd() bool {
    return parseHead.source.len <= 0;
}

fn isWhitespace() bool {
    return switch (peek() orelse 0) {
        ' ', '\t', '\r', '\n' => true,
        else => false,
    };
}

pub fn Init(tag: []const u8, source: []const u8) void {
    parseHead = ParseHead{
        .tag = tag,
        .source = source,
        .start = source,
        .original = source,
        .loc = .{
            .line = 1,
            .column = 1,
        },
    };
}

fn handleIdent() tk.Token {
    const start_loc = parseHead.loc;

    while (isAlphaNum(peek() orelse 0) or (peek() orelse 0) == '_') {
        // if (peek() == ' ') break;
        _ = consume();
    }

    const ident: []const u8 = parseHead.start[0 .. parseHead.start.len - parseHead.source.len];

    if (tk.reserved_lu.has(ident)) {
        return tk.Token{
            .token_type = tk.reserved_lu.get(ident) orelse tk.TokenType.Unknown,
            .value = ident,
            .loc = .{
                .line = start_loc.line,
                .column = start_loc.column,
                .end_col = parseHead.loc.column,
                .end_line = parseHead.loc.line,
            },
        };
    } else {
        return tk.Token{
            .token_type = tk.TokenType.Identifier,
            .value = ident,
            .loc = .{
                .line = start_loc.line,
                .column = start_loc.column,
                .end_col = parseHead.loc.column,
                .end_line = parseHead.loc.line,
            },
        };
    }
}

fn handleNum() tk.Token {
    const start_loc = parseHead.loc;

    while (isDigit(peek() orelse 0))
        _ = consume();

    if (peek() == '.') {
        _ = consume();

        while (isDigit(peek() orelse 0))
            _ = consume();

        return tk.Token{
            .token_type = tk.TokenType.FloatLit,
            .value = parseHead.start[0 .. parseHead.start.len - parseHead.source.len],
            .loc = .{
                .line = start_loc.line,
                .column = start_loc.column,
                .end_col = parseHead.loc.column,
                .end_line = parseHead.loc.line,
            },
        };
    } else {
        const num: []const u8 = parseHead.start[0 .. parseHead.start.len - parseHead.source.len];
        return tk.Token{
            .token_type = tk.TokenType.NumberLit,
            .value = num,
            .loc = .{
                .line = start_loc.line,
                .column = start_loc.column,
                .end_col = parseHead.loc.column,
                .end_line = parseHead.loc.line,
            },
        };
    }
}

fn handleString() !tk.Token {
    const start_loc = parseHead.loc;
    const quote = consume() orelse 0;

    while (peek() != quote and !isEnd()) {
        if (peek() == '\n') {
            parseHead.loc.line += 1;
            parseHead.loc.column = 1;
        }
        _ = consume();
        if (isEnd()) {
            errs.printErr(errs.ErrMsg{
                .line = start_loc.line,
                .col = start_loc.column,
                .tag = parseHead.tag,
                .msg = "Unterminated string found",
                .ErrType = "UnterminatedString",
                .ErrKind = .Error,
                .previewLookBack = null,
            });
            std.process.exit(0);
        }
    }

    if (peek() != quote) {
        errs.printErr(errs.ErrMsg{
            .line = start_loc.line,
            .col = start_loc.column,
            .tag = parseHead.tag,
            .msg = "Unterminated string found",
            .ErrType = "UnterminatedString",
            .ErrKind = .Error,
            .previewLookBack = null,
        });
        std.process.exit(0);
    } else {
        _ = consume();

        return tk.Token{
            .token_type = tk.TokenType.StringLit,
            .value = parseHead.start[1 .. parseHead.start.len - parseHead.source.len - 1],
            .loc = .{
                .line = start_loc.line,
                .column = start_loc.column,
                .end_col = parseHead.loc.column,
                .end_line = parseHead.loc.line,
            },
        };
    }
}

fn handleDoublesOperator() ?tk.Token {
    if (peek()) |c| {
        if (peek_next()) |c2| {
            if (c2 == 0) return null;
            const start_loc = parseHead.loc;

            const dChar = [2]u8{ c, c2 };
            if (tk.double_opreator_lu.get(&dChar)) |it| {
                _ = consume();
                _ = consume();
                return tk.Token{
                    .token_type = it,
                    .value = &dChar,
                    .loc = .{
                        .line = start_loc.line,
                        .column = start_loc.column,
                        .end_col = parseHead.loc.column,
                        .end_line = parseHead.loc.line,
                    },
                };
            } else return null;
        } else return null;
    } else return null;
}

pub const tokensList = std.ArrayListAligned(tk.Token, null);

pub fn startLexer() !std.ArrayListAligned(tk.Token, null) {
    var tokens = std.ArrayList(tk.Token).init(page_allocator);
    // defer tokens.deinit();

    while (peek()) |c| {
        parseHead.start = parseHead.source;
        if (isEnd()) break;
        // handleWhiteSpace();
        if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
            while (peek()) |ct| {
                switch (ct) {
                    '\n' => {
                        _ = consume();
                        parseHead.loc.line += 1;
                        parseHead.loc.column = 1;

                        break;
                    },

                    ' ', '\r', '\t' => {
                        _ = consume();

                        break;
                    },
                    else => break,
                }
                break;
            }
            continue;
        }

        if (isAlpha(c)) {
            const token = handleIdent();
            try tokens.append(token);
            continue;
        } else if (isDigit(c)) {
            const token = handleNum();
            try tokens.append(token);
            continue;
        } else if (c == '"') {
            const token = try handleString();
            try tokens.append(token);
            continue;
        }

        if (handleDoublesOperator()) |token| {
            if (token.token_type == tk.TokenType.Comment) {
                while (peek() != null and peek() != '\n' and !isEnd()) {
                    _ = consume();
                }
                continue;
            }
            try tokens.append(token);
            continue;
        }

        if (tk.single_operator_lu.has(&[_]u8{c})) {
            const token = tk.Token{
                .token_type = tk.single_operator_lu.get(&[_]u8{c}) orelse tk.TokenType.Unknown,
                .value = &[_]u8{c},
                .loc = .{
                    .line = parseHead.loc.line,
                    .column = parseHead.loc.column,
                    .end_col = parseHead.loc.column,
                    .end_line = parseHead.loc.line,
                },
            };
            _ = consume();

            try tokens.append(token);
            continue;
        }

        const v = consume() orelse 0;

        try tokens.append(tk.Token{
            .token_type = tk.TokenType.Unknown,
            .value = &[1]u8{v},
            .loc = .{
                .line = parseHead.loc.line,
                .column = parseHead.loc.column,
                .end_col = parseHead.loc.column,
                .end_line = parseHead.loc.line,
            },
        });
    }

    try tokens.append(tk.Token{
        .token_type = tk.TokenType.EOF,
        .value = "EOF",
        .loc = .{
            .line = parseHead.loc.line,
            .column = parseHead.loc.column,
            .end_col = parseHead.loc.column,
            .end_line = parseHead.loc.line,
        },
    });

    return tokens;
}
