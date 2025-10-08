// const commando = @import("commando.zig");
const std = @import("std");
const zigCli = @import("../lib/zig-cli/main.zig");
const comp = @import("../compiler.zig");
const fsH = @import("../core/helper/fsHelper.zig");
const ntv = @import("../core/helper/nodeTreeVisualizer.zig");

var input = struct {
    visualize_tree: bool = false,
    debug_token: bool = false,
    run_path: []const u8 = undefined,
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
            .long_name = "debug-ast",
            .help = "visualize parser output into a nice looking tree.",
            .value_ref = zigCli.mkRef(&input.visualize_tree),
        };

        var runArgDebugToken = zigCli.Option{
            .long_name = "debug-token",
            .help = "shows a debug list of all of the tokens",
            .value_ref = zigCli.mkRef(&input.debug_token),
        };

        var runPArgPath = zigCli.PositionalArg{
            .name = "path",
            .help = "path to run a file/project",
            .value_ref = zigCli.mkRef(&input.run_path),
        };

        const runCmd = &zigCli.Command{
            .name = "run",
            .description = zigCli.Description{ .one_line = "run Terra projects/scripts" },
            .options = &.{ &runArgVsTree, &runArgDebugToken },
            .target = zigCli.CommandTarget{
                .action = zigCli.CommandAction{
                    .exec = run_cmd,
                    .positional_args = zigCli.PositionalArgs{
                        .args = &.{&runPArgPath},
                    },
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const aloc = gpa.allocator();

    const c = &input;

    // std.debug.print("{s}", .{c.run_path[c.run_path.len - 3 .. c.run_path.len]});

    if (std.mem.eql(u8, c.run_path[c.run_path.len - 3 .. c.run_path.len], ".tr")) {
        const path = try std.fs.cwd().realpathAlloc(aloc, c.run_path);

        const TerraC = comp.TerraC.init(aloc);
        const prgm = try TerraC.parseFile(path, input.debug_token);
        defer prgm.deinit(aloc);

        if (c.visualize_tree) try ntv.VisualizeNode(prgm, aloc, 0);
    } else {
        std.debug.print("Connot yet run a whole project!\n", .{});
        std.process.exit(0);
    }
}
