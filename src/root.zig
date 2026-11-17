const std = @import("std");

// marriage locate
pub fn DisjointSet(comptime T: type) type {
    return struct {
        // roots are negative, magnitude represents tree size
        // otherwise positive, magnitude represents index of parent
        parents: std.ArrayList(isize),

        const Self = @This();

        pub fn init(gpa: std.mem.Allocator, n: usize) !Self {
            // assert n < 2^63, we use sign bit to distinguish roots
            _ = std.math.cast(isize, n) orelse return error.Overflow;
            var parents: std.ArrayList(isize) = .empty;
            // n singleton sets
            try parents.appendNTimes(gpa, -1, n);
            return .{
                .parents = parents,
            };
        }

        pub fn deinit(self: *Self, gpa: std.mem.Allocator) void {
            self.parents.deinit(gpa);
        }

        pub fn find(self: *Self, a: T) usize {
            return self.findIndex(a.index());
        }

        fn findIndex(self: *Self, index: usize) usize {
            if (self.parents.items[index] < 0) {
                return index;
            } else {
                const root = self.findIndex(@intCast(self.parents.items[index]));
                self.parents.items[index] = @intCast(root);
                return root;
            }
        }

        pub const UnionOutcome = enum(u1) {
            same_root,
            now_joined,
        };

        pub fn @"union"(self: *Self, a: T, b: T) UnionOutcome {
            const a_root = self.find(a);
            const b_root = self.find(b);
            if (a_root == b_root) {
                return .same_root;
            }
            const a_size = self.parents.items[a_root];
            const b_size = self.parents.items[b_root];
            // is a bigger than b?
            if (a_size < b_size) {
                // yes, a is a bigger tree than b
                self.parents.items[b_root] = @intCast(a_root);
                self.parents.items[a_root] += b_size;
            } else {
                // no, a is smaller than b
                self.parents.items[a_root] = @intCast(b_root);
                self.parents.items[b_root] += a_size;
            }
            return .now_joined;
        }
    };
}

test {
    const Node = struct {
        i: usize,

        const Self = @This();

        fn init(i: usize) Self {
            return .{
                .i = i,
            };
        }

        fn index(self: Self) usize {
            return self.i;
        }
    };

    const gpa = std.testing.allocator;
    var ds = try DisjointSet(Node).init(gpa, 4);
    defer ds.deinit(gpa);

    try std.testing.expectEqual(@as(usize, 0), ds.find(.init(0)));
    try std.testing.expectEqual(.now_joined, ds.@"union"(.init(0), .init(1)));
    try std.testing.expectEqual(@as(usize, 1), ds.find(.init(1)));
    try std.testing.expectEqual(@as(usize, 1), ds.find(.init(0)));
    try std.testing.expectEqual(.now_joined, ds.@"union"(.init(1), .init(2)));
    try std.testing.expectEqual(.same_root, ds.@"union"(.init(0), .init(2)));
    try std.testing.expectEqual(@as(usize, 1), ds.find(.init(2)));
}
