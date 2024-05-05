const std = @import("std");
const Chameleon = @import("chameleon").Chameleon;
const tk = @import("../lexer/tokens.zig");

// Error Example:
//           -> (path) [line:col]
// [line num]| [line preview]
//           -> <errtype>: errExplenation
