//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("zircon_lib");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("Zircon - Ruby Parser with Prism\n", .{});

    // stdout is for the actual output of your application
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Example Ruby code to parse
    const ruby_examples = [_][]const u8{
        "1 + 2",
        "puts 'Hello, World!'",
        "class Person\n  def initialize(name)\n    @name = name\n  end\nend",
        "[1, 2, 3].map { |x| x * 2 }",
    };

    try stdout.print("=== Prism Ruby Parser Examples ===\n\n", .{});

    for (ruby_examples, 0..) |example, i| {
        try stdout.print("Example {}: {s}\n", .{ i + 1, example });
        try stdout.print("AST (pretty printed):\n", .{});

        // Print the pretty-printed AST
        lib.PrismParser.parseAndPrint(example);

        // Parse and get serialized AST
        const serialized = lib.PrismParser.parse(allocator, example) catch |err| {
            try stdout.print("Error parsing: {}\n", .{err});
            continue;
        };
        defer allocator.free(serialized);

        try stdout.print("Serialized AST size: {} bytes\n", .{serialized.len});
        try stdout.print("---\n\n", .{});
    }

    try stdout.print("Run `zig build test` to run the tests.\n", .{});
    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
