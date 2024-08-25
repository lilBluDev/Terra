const std = @import("std");
const tokens = @import("../lexer/tokens.zig");

const loc = tokens.loc;

pub const Report = struct {
    kind: enum {
        Inline,
        Error,
        Panic,
        Warning,
        Info,
    },
};

pub const Reporter = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    reports: std.ArrayList(Report),

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .reports = std.ArrayList(Report).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.reports.deinit();
    }
};
