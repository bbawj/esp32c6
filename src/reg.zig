pub const Field = struct { offset: u5, mask: u32 };

pub fn Reg(comptime base_addr: u32, comptime offset: u32, comptime tags: type, comptime default: [@typeInfo(tags).Enum.fields.len]Field) type {
    return struct {
        const Self = @This();
        const base: *u32 = @ptrFromInt(base_addr + offset);
        const fields = set_fields(tags, default);

        pub fn set(comptime target: tags, value: u32) void {
            const f = fields[@intFromEnum(target)];
            base.* |= (value & f.mask) << f.offset;
        }
    };
}

fn set_fields(comptime tags: type, comptime offsets: [@typeInfo(tags).Enum.fields.len]Field) [32]Field {
    var initial: [32]Field = undefined;
    var counter = 0;
    inline for (@typeInfo(tags).Enum.fields) |f| {
        // std.debug.print("{}\n", .{f.value});
        initial[f.value] = offsets[counter];
        counter += 1;
    }
    return initial;
}
