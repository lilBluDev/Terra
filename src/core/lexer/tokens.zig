const std = @import("std");

/// Compares two slices and returns whether they are equal.
pub fn eql(comptime T: type, a: T, b: T) bool {
    if (a.len != b.len) return false;
    if (a.ptr == b.ptr) return true;
    for (a, b) |a_elem, b_elem| {
        if (a_elem != b_elem) return false;
    }
    return true;
}

pub const TokenType = enum {
    EOF,
    Unknown,
    Comment,

    //Literals
    Identifier,
    StringLit,
    NumberLit,
    FloatLit,

    // Enclosing
    LeftParen, // (
    RightParen, // )
    LeftBrace, // {
    RightBrace, // }
    LeftBracket, // [
    RightBracket, // ]

    // Operators
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Caret,
    Ampersand,
    Pipe,
    Tilde,
    Exclamation,
    Equals,
    Dot,
    Comma,
    At,
    Semicolon,
    Colon,

    // Double Operators
    PlusEquals,
    MinusEquals,
    StarEquals,
    SlashEquals,
    PercentEquals,
    CaretEquals,
    GraterThan,
    GraterThanEquals,
    LessThan,
    LessThanEquals,
    EqualsEquals,
    ExclamationEquals,
    PlusPlus,
    MinusMinus,
    PipePipe,
    AmpAmp,
    Walrus,
    Arrow,

    //Reserved Keywords
    Var,
    Const,
    Fn,
    Struct,
    Enum,
    If,
    Elif,
    Else,
    For,
    While,
    In,
    Is,
    Or,
    And,
    Not,
    Loop,
    Iter,
    Import,
    Pub,
    Return,

    //Reserved Type Keywords
    TrueKeyword,
    FalseKeyword,
    NullKeyword,
};

pub const str_to_roken_type_lu = std.StaticStringMap(TokenType).initComptime(.{
    .{ "(", TokenType.LeftParen },
    .{ ")", TokenType.RightParen },
    .{ "{", TokenType.LeftBrace },
    .{ "}", TokenType.RightBrace },
    .{ "[", TokenType.LeftBracket },
    .{ "]", TokenType.RightBracket },
    .{ "+", TokenType.Plus },
    .{ "-", TokenType.Minus },
    .{ "*", TokenType.Star },
    .{ "/", TokenType.Slash },
    .{ "%", TokenType.Percent },
    .{ "^", TokenType.Caret },
    .{ "&", TokenType.Ampersand },
    .{ "|", TokenType.Pipe },
    .{ "~", TokenType.Tilde },
    .{ "!", TokenType.Exclamation },
    .{ "=", TokenType.Equals },
    .{ ".", TokenType.Dot },
    .{ ",", TokenType.Comma },
    .{ "@", TokenType.At },
    .{ ";", TokenType.Semicolon },
    .{ ":", TokenType.Colon },
    .{ "//", TokenType.Comment },
    .{ "+=", TokenType.PlusEquals },
    .{ "-=", TokenType.MinusEquals },
    .{ "*=", TokenType.StarEquals },
    .{ "/=", TokenType.SlashEquals },
    .{ "%=", TokenType.PercentEquals },
    .{ "^=", TokenType.CaretEquals },
    .{ ">", TokenType.GraterThan },
    .{ ">=", TokenType.GraterThanEquals },
    .{ "<", TokenType.LessThan },
    .{ "<=", TokenType.LessThanEquals },
    .{ "==", TokenType.EqualsEquals },
    .{ "||", TokenType.PipePipe },
    .{ "&&", TokenType.AmpAmp },
    .{ "!=", TokenType.ExclamationEquals },
    .{ "++", TokenType.PlusPlus },
    .{ "--", TokenType.MinusMinus },
    .{ "->", TokenType.Arrow },
    .{ ":=", TokenType.Walrus },
    .{ "var", TokenType.Var },
    .{ "const", TokenType.Const },
    .{ "fn", TokenType.Fn },
    .{ "struct", TokenType.Struct },
    .{ "enum", TokenType.Enum },
    .{ "if", TokenType.If },
    .{ "elif", TokenType.Elif },
    .{ "else", TokenType.Else },
    .{ "for", TokenType.For },
    .{ "while", TokenType.While },
    .{ "in", TokenType.In },
    .{ "is", TokenType.Is },
    .{ "or", TokenType.OR },
    .{ "and", TokenType.And },
    .{ "not", TokenType.Not },
    .{ "loop", TokenType.Loop },
    .{ "iter", TokenType.Iter },
    .{ "import", TokenType.Import },
    .{ "pub", TokenType.Pub },
    .{ "return", TokenType.Return },
    .{ "true", TokenType.TrueKeyword },
    .{ "false", TokenType.FalseKeyword },
    .{ "null", TokenType.NullKeyword },
});

pub const single_operator_lu = std.StaticStringMap(TokenType).initComptime(.{
    .{ "+", TokenType.Plus },
    .{ "-", TokenType.Minus },
    .{ "*", TokenType.Star },
    .{ "/", TokenType.Slash },
    .{ "%", TokenType.Percent },
    .{ "^", TokenType.Caret },
    .{ "&", TokenType.Ampersand },
    .{ "|", TokenType.Pipe },
    .{ "~", TokenType.Tilde },
    .{ "!", TokenType.Exclamation },
    .{ "=", TokenType.Equals },
    .{ ".", TokenType.Dot },
    .{ ",", TokenType.Comma },
    .{ "@", TokenType.At },
    .{ ";", TokenType.Semicolon },
    .{ ":", TokenType.Colon },
    .{ "(", TokenType.LeftParen },
    .{ ")", TokenType.RightParen },
    .{ "{", TokenType.LeftBrace },
    .{ "}", TokenType.RightBrace },
    .{ "[", TokenType.LeftBracket },
    .{ "]", TokenType.RightBracket },
});

pub const double_opreator_lu = std.StaticStringMap(TokenType).initComptime(.{
    .{ "//", TokenType.Comment },
    .{ "+=", TokenType.PlusEquals },
    .{ "-=", TokenType.MinusEquals },
    .{ "*=", TokenType.StarEquals },
    .{ "/=", TokenType.SlashEquals },
    .{ "%=", TokenType.PercentEquals },
    .{ "^=", TokenType.CaretEquals },
    .{ ">", TokenType.GraterThan },
    .{ ">=", TokenType.GraterThanEquals },
    .{ "||", TokenType.PipePipe },
    .{ "&&", TokenType.AmpAmp },
    .{ "<", TokenType.LessThan },
    .{ "<=", TokenType.LessThanEquals },
    .{ "==", TokenType.EqualsEquals },
    .{ "!=", TokenType.ExclamationEquals },
    .{ "++", TokenType.PlusPlus },
    .{ "--", TokenType.MinusMinus },
    .{ ":=", TokenType.Walrus },
    .{ "->", TokenType.Arrow },
});

pub const reserved_lu = std.StaticStringMap(TokenType).initComptime(.{
    .{ "var", TokenType.Var },
    .{ "const", TokenType.Const },
    .{ "fn", TokenType.Fn },
    .{ "struct", TokenType.Struct },
    .{ "enum", TokenType.Enum },
    .{ "if", TokenType.If },
    .{ "elif", TokenType.Elif },
    .{ "else", TokenType.Else },
    .{ "for", TokenType.For },
    .{ "while", TokenType.While },
    .{ "in", TokenType.In },
    .{ "is", TokenType.Is },
    .{ "and", TokenType.Or },
    .{ "and", TokenType.And },
    .{ "not", TokenType.Not },
    .{ "loop", TokenType.Loop },
    .{ "iter", TokenType.Iter },
    .{ "import", TokenType.Import },
    .{ "pub", TokenType.Pub },
    .{ "return", TokenType.Return },
    .{ "true", TokenType.TrueKeyword },
    .{ "false", TokenType.FalseKeyword },
    .{ "null", TokenType.NullKeyword },
});

pub fn TokenType2String(tkt: TokenType) []const u8 {
    switch (tkt) {
        .NumberLit, .FloatLit => return "Number",
        .LeftParen => return "(",
        .RightParen => return ")",
        .LeftBrace => return "{",
        .RightBrace => return "}",
        .LeftBracket => return "[",
        .RightBracket => return "]",
        .Plus => return "+",
        .Minus => return "-",
        .Star => return "*",
        .Slash => return "/",
        .Percent => return "%",
        .Caret => return "^",
        .Ampersand => return "&",
        .Pipe => return "|",
        .Tilde => return "~",
        .Exclamation => return "!",
        .Equals => return "=",
        .Dot => return ".",
        .Comma => return ",",
        .At => return "@",
        .Semicolon => return ";",
        .Colon => return ":",
        .PlusEquals => return "+=",
        .MinusEquals => return "-",
        .StarEquals => return "*",
        .SlashEquals => return "/=",
        .PercentEquals => return "%=",
        .CaretEquals => return "^=",
        .GraterThan => return "<",
        .GraterThanEquals => return "<=",
        .LessThan => return ">",
        .LessThanEquals => return ">=",
        .EqualsEquals => return "==",
        .ExclamationEquals => return "!=",
        .PlusPlus => return "++",
        .MinusMinus => return "--",
        .Arrow => return "->",
        .Walrus => return ":=",
        .EOF => return "End Of File",

        else => |t| return @tagName(t),
    }
}

pub const Token = struct {
    token_type: TokenType,
    value: []const u8,
    loc: loc,

    pub fn is(self: Token, t: TokenType) bool {
        return self.token_type == t;
    }
};

pub const loc = struct {
    line: usize,
    column: usize,
    end_line: usize,
    end_col: usize,
};
