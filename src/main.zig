const clk = @import("clock.zig");
const uart = @import("uart.zig");
const Reg = @import("reg.zig");

const MAX_U32 = 4294967295;

// The @setCold builtin tells the optimizer that a function is rarely called.
fn abort() noreturn {
    @setCold(true);
    while (true) {}
}

const ASSIST_DEBUG_BASE_ADDR = 0x600C_2000;
const CORE0_RCD_EN_REG = Reg.Reg(
    ASSIST_DEBUG_BASE_ADDR,
    0x44,
    enum { RECORD_EN, DEBUG_EN },
    [_]Reg.Field{
        Reg.Field{ .offset = 0, .mask = 1 },
        Reg.Field{ .offset = 1, .mask = 1 },
    },
);

const TIMG0_BASE_ADDR = 0x6000_8000;
const TIMG_WDTCONFIG0_REG = Reg.Reg(
    TIMG0_BASE_ADDR,
    0x48,
    enum { EN, STG0, STG1, STG2, STG3, FLASHBOOT_MOD_EN },
    [_]Reg.Field{
        Reg.Field{ .offset = 31, .mask = 1 },
        Reg.Field{ .offset = 28, .mask = 7 },
        Reg.Field{ .offset = 25, .mask = 7 },
        Reg.Field{ .offset = 22, .mask = 7 },
        Reg.Field{ .offset = 19, .mask = 7 },
        Reg.Field{ .offset = 14, .mask = 1 },
    },
);
const TIMG_WDTWPROTECT_REG = Reg.Reg(
    TIMG0_BASE_ADDR,
    0x64,
    enum { WKEY },
    [_]Reg.Field{Reg.Field{ .offset = 0, .mask = 0xFFFFFFFF }},
);
const TIMG_INT_ENA_REG = Reg.Reg(
    TIMG0_BASE_ADDR,
    0x70,
    enum { WDT },
    [_]Reg.Field{Reg.Field{ .offset = 1, .mask = 1 }},
);
const TIMG_INT_CLR_REG = Reg.Reg(
    TIMG0_BASE_ADDR,
    0x7C,
    enum { WDT },
    [_]Reg.Field{Reg.Field{ .offset = 1, .mask = 1 }},
);

const TIMG1_BASE_ADDR = 0x6000_9000;

const LP_WDT_BASE_ADDR = 0x600B_1C00;
const LP_WDT_RWDT_CONFIG0_REG = Reg.Reg(
    LP_WDT_BASE_ADDR,
    0,
    enum { EN, STG0, STG1, STG2, STG3, FLASHBOOT_MOD_EN, CPU_RESET },
    [_]Reg.Field{
        Reg.Field{ .offset = 31, .mask = 1 },
        Reg.Field{ .offset = 28, .mask = 7 },
        Reg.Field{ .offset = 25, .mask = 7 },
        Reg.Field{ .offset = 22, .mask = 7 },
        Reg.Field{ .offset = 19, .mask = 7 },
        Reg.Field{ .offset = 12, .mask = 1 },
        Reg.Field{ .offset = 11, .mask = 1 },
    },
);
const LP_WDT_RWDT_WPROTECT_REG = Reg.Reg(
    LP_WDT_BASE_ADDR,
    0x18,
    enum { WKEY },
    [_]Reg.Field{Reg.Field{ .offset = 0, .mask = MAX_U32 }},
);
const LP_WDT_SWD_CONFIG_REG = Reg.Reg(
    LP_WDT_BASE_ADDR,
    0x1c,
    enum { AUTO_FEED_EN },
    [_]Reg.Field{Reg.Field{ .offset = 18, .mask = 1 }},
);
const LP_WDT_SWD_WDTWPROTECT_REG = Reg.Reg(
    LP_WDT_BASE_ADDR,
    0x20,
    enum { WKEY },
    [_]Reg.Field{Reg.Field{ .offset = 0, .mask = MAX_U32 }},
);
const LP_WDT_INT_ENA_REG = Reg.Reg(
    LP_WDT_BASE_ADDR,
    0x2C,
    enum { SWD, RWDT },
    [_]Reg.Field{
        Reg.Field{ .offset = 30, .mask = 1 },
        Reg.Field{ .offset = 31, .mask = 1 },
    },
);
const LP_WDT_INT_CLR_REG = Reg.Reg(
    LP_WDT_BASE_ADDR,
    0x30,
    enum { SWD, RWDT },
    [_]Reg.Field{
        Reg.Field{ .offset = 30, .mask = 1 },
        Reg.Field{ .offset = 31, .mask = 1 },
    },
);

const PCR_BASE_ADDR = 0x6009_6000;
const PCR: [*]u32 = @ptrFromInt(PCR_BASE_ADDR);
const MSPI_CLK_CONF = 0x001C;

inline fn clk_ll_mspi_fast_set_hs_divider(div: u8) void {
    const d = switch (div) {
        6 => 5,
        else => abort(),
    };
    PCR[MSPI_CLK_CONF] = d << 8;
}

const WPD_MASK = 0x80;
const WPU_MASK = 0x100;
const MCU_MASK = 0x3000;

const dogfood = 0x50D8_3AA1;

extern fn esp_rom_spiflash_config_clk(u8, u8) u8;
extern fn spi_dummy_len_fix(u8, u8) void;

// The first stage bootloader sets up a stack for us
export fn _start() linksection(".text") callconv(.C) noreturn {
    uart.uart_tx("hello world\n");
    clk_ll_mspi_fast_set_hs_divider(6);
    _ = esp_rom_spiflash_config_clk(1, 0);
    _ = esp_rom_spiflash_config_clk(1, 1);
    spi_dummy_len_fix(0, 1);
    spi_dummy_len_fix(1, 1);

    LP_WDT_RWDT_WPROTECT_REG.set(.WKEY, dogfood);
    LP_WDT_INT_ENA_REG.set(.SWD, 0);
    LP_WDT_INT_ENA_REG.set(.RWDT, 0);
    LP_WDT_INT_CLR_REG.set(.SWD, 1);
    LP_WDT_INT_CLR_REG.set(.RWDT, 1);

    LP_WDT_RWDT_CONFIG0_REG.set(.EN, 0);
    LP_WDT_RWDT_CONFIG0_REG.set(.STG0, 0);
    LP_WDT_RWDT_CONFIG0_REG.set(.STG1, 0);
    LP_WDT_RWDT_CONFIG0_REG.set(.STG2, 0);
    LP_WDT_RWDT_CONFIG0_REG.set(.STG3, 0);
    LP_WDT_RWDT_CONFIG0_REG.set(.CPU_RESET, 0);
    // Autofeed superwatchdog
    LP_WDT_SWD_WDTWPROTECT_REG.set(.WKEY, dogfood);
    LP_WDT_SWD_CONFIG_REG.set(.AUTO_FEED_EN, 1);

    clk.clock_configure();

    LP_WDT_RWDT_WPROTECT_REG.set(.WKEY, dogfood);
    LP_WDT_RWDT_CONFIG0_REG.set(.FLASHBOOT_MOD_EN, 0);

    TIMG_WDTWPROTECT_REG.set(.WKEY, dogfood);
    TIMG_INT_ENA_REG.set(.WDT, 0);
    TIMG_INT_CLR_REG.set(.WDT, 1);
    TIMG_WDTCONFIG0_REG.set(.EN, 0);
    TIMG_WDTCONFIG0_REG.set(.STG0, 0);
    TIMG_WDTCONFIG0_REG.set(.STG1, 0);
    TIMG_WDTCONFIG0_REG.set(.STG2, 0);
    TIMG_WDTCONFIG0_REG.set(.STG3, 0);
    TIMG_WDTCONFIG0_REG.set(.FLASHBOOT_MOD_EN, 0);

    CORE0_RCD_EN_REG.set(.RECORD_EN, 1);
    CORE0_RCD_EN_REG.set(.DEBUG_EN, 1);

    uart.uart_tx("hello world\n");

    const S_MODE = 1 << 11;
    asm volatile ("csrw mstatus, %[S_MODE]"
        :
        : [S_MODE] "r" (S_MODE),
    );
    const addr: u32 = @intFromPtr(&main);
    asm volatile ("csrw mepc, %[addr]"
        :
        : [addr] "r" (addr),
    );
    asm volatile ("mret");
    abort();
}

pub fn main() noreturn {
    uart.uart_tx("hello world\n");
    while (true) {
        asm volatile ("nop");
    }
}

test "simple test" {}
