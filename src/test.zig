const std = @import("std");

test "suboverflow" {
    const a: u8 = 20;
    const b: u8 = 30;
    const res = @subWithOverflow(b, a);
    try std.testing.expectEqual(res[0], 10);
    try std.testing.expect(res[1] == 0);
}
