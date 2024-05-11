// const commando = @import("commando.zig");
const std = @import("std");
const zigCli = @import("../lib/zig-cli/main.zig");

var input = struct {
    visualize_tree: bool = false,
}{};

pub const CliApp = struct {
    aloc: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) CliApp {
        return CliApp{
            .aloc = allocator,
        };
    }

    pub fn start(self: *const CliApp) !void {
        var runArgVsTree = zigCli.Option{
            .long_name = "vtree",
            .short_alias = 'v',
            .help = "visualize parser output into a nice looking tree.",
            .value_ref = zigCli.mkRef(&input.visualize_tree),
        };

        const runCmd = &zigCli.Command{
            .name = "run",
            .description = zigCli.Description{ .one_line = "run Terra projects/scripts" },
            .options = &.{&runArgVsTree},
            .target = zigCli.CommandTarget{
                .action = zigCli.CommandAction{
                    .exec = run_cmd,
                },
            },
        };

        const app = &zigCli.App{
            .command = zigCli.Command{
                .name = "terra",
                .description = zigCli.Description{ .one_line = "The terra cli tool to use with the Terra Programming language." },
                .options = &.{},
                .target = zigCli.CommandTarget{
                    // .action = zigCli.CommandAction{ .exec = default_cmd },
                    .subcommands = &.{runCmd},
                },
            },
            .author = "lilBluDev",
            .version = "Dev-0",
        };

        try zigCli.run(app, self.aloc);
    }
};

fn default_cmd() !void {
    // _ = cmd;
    std.debug.print("Terra Cli\n", .{});
}

fn run_cmd() !void {
    std.debug.print("run\n", .{});
}
