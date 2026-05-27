//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

pub fn main() !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    const allocator = std.heap.page_allocator;

    while (true) {
        const time = get_time();
        var hour = time.hour;
        if (hour < 5) {
            hour = hour + 19;
        } else {
            hour = hour - 5;
        }
        try stdout.print("{d:0>2}:{d:0>2}:{d:0>2} | ", .{hour, time.min, time.sec});
        try stdout.print("{d}%", .{try get_brightness(allocator)});
        try stdout.print(" | ", .{});
        const battery_charge = try get_battery_charge(allocator);
        const battery_status = try get_battery_status(allocator);
        defer allocator.free(battery_status);

        try stdout.print("{d}% {s}", .{battery_charge, battery_status});
        try stdout.print(" | ", .{});
        try stdout.print("{d}", .{try get_memory_usage()});
        try stdout.print("\n", .{});
        try stdout.flush();
        std.Thread.sleep(1 * std.time.ns_per_s);
    }
}

pub fn get_brightness(allocator: std.mem.Allocator) !u16 {
    const max_brightness = 400;
    const file = try std.fs.cwd().openFile("/sys/class/backlight/intel_backlight/brightness", .{});
    defer file.close();

    const buf = try file.readToEndAlloc(allocator, 4);
    defer allocator.free(buf);
    const brightness = try std.fmt.parseInt(u16, buf[0..buf.len - 1], 10);

    const rel_brightness = (brightness * 100) / max_brightness;

    return rel_brightness;
}

pub fn get_battery_charge(allocator: std.mem.Allocator) !u8 {
    const file = try std.fs.cwd().openFile("/sys/class/power_supply/BAT0/capacity", .{});
    defer file.close();

    const buf = try file.readToEndAlloc(allocator, 4);
    defer allocator.free(buf);
    const charge = try std.fmt.parseInt(u8, buf[0..buf.len - 1], 10);
    return charge;
}

pub fn get_battery_status(allocator: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile("/sys/class/power_supply/BAT0/status", .{});
    defer file.close();
    const battery_status = try file.readToEndAlloc(allocator, 20);
    return battery_status[0..battery_status.len-1];
}

pub fn get_memory_usage() !usize {
    var file = try std.fs.openFileAbsolute("/proc/meminfo", .{});
    defer file.close();

    const file_size = 4096; // large enough for /proc/meminfo
    var buffer: [file_size]u8 = undefined;
    const read_len = try file.readAll(&buffer);
    const content = buffer[0..read_len];

    var total: usize = 0;
    var free: usize = 0;
    var available: usize = 0;
    var buffers: usize = 0;
    var cached: usize = 0;

    var lines = std.mem.splitAny(u8, content, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "MemTotal:")) {
            total = try parse_kb_value(line);
        } else if (std.mem.startsWith(u8, line, "MemFree:")) {
            free = try parse_kb_value(line);
        } else if (std.mem.startsWith(u8, line, "Buffers:")) {
            buffers = try parse_kb_value(line);
        } else if (std.mem.startsWith(u8, line, "Cached:")) {
            cached = try parse_kb_value(line);
        } else if (std.mem.startsWith(u8, line, "MemAvailable:")) {
            available = try parse_kb_value(line);
        }
    }

    // const used: usize = total - free - buffers - cached;
    const used: usize = total - available;
    return used / 1000;
}

fn parse_kb_value(line: []const u8) !usize {
    var parts = std.mem.tokenizeScalar(u8, line, ' ');
    _ = parts.next(); // skip key

    const value_str = parts.next() orelse return error.InvalidFormat;
    return std.fmt.parseInt(usize, value_str, 10);
}

fn get_time() zul.Time {
    const time = zul.DateTime.now().time();

    return time;
}

const std = @import("std");
const zul = @import("zul");
