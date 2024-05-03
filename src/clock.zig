const expect = @import("std").testing.expect;
const main = @import("main.zig");
const std = @import("std");
const print = @import("std").debug.print;
const Reg = @import("reg.zig");

const CONFIG_XTAL_FREQ = 40;
const CPU_CLK_FREQ_MHZ_BTLD = 80;
const RTC_CNTL_CK8M_DFREQ_DEFAULT = 100;
const RTC_CNTL_SCK_DCAP_DEFAULT = 128;
const RTC_CNTL_RC32K_DFREQ_DEFAULT = 700;

const PCR_BASE = 0x6009_6000;
const LP_CLKRST_BASE = 0x600B_0400;
const LP_TIMER_BASE = 0x600B_0C00;
const LP_ANALOG_PERI_BASE = 0x600B_2C00;
const PMU_BASE = 0x600B_0000;

const PMU_HP_INT_ENA_REG = Reg.Reg(
    PMU_BASE,
    0x164,
    enum { SOC_SLEEP_REJECT, SOC_WAKEUP },
    [_]Reg.Field{
        Reg.Field{ .offset = 30, .mask = 1 },
        Reg.Field{ .offset = 31, .mask = 1 },
    },
);

const LP_ANALOG_PERI_FIB_ENA_REG = Reg.Reg(
    LP_ANALOG_PERI_BASE,
    0xc,
    enum { BOD, SWD },
    [_]Reg.Field{
        Reg.Field{ .offset = 1, .mask = 1 },
        Reg.Field{ .offset = 2, .mask = 1 },
    },
);
const LP_ANALOG_PERI_INT_ENA_REG = Reg.Reg(
    LP_ANALOG_PERI_BASE,
    0x28,
    enum { ENA },
    [_]Reg.Field{Reg.Field{ .offset = 31, .mask = 1 }},
);
const LP_ANALOG_PERI_INT_CLR_REG = Reg.Reg(
    LP_ANALOG_PERI_BASE,
    0x2c,
    enum { CLR },
    [_]Reg.Field{Reg.Field{ .offset = 31, .mask = 1 }},
);

const LP_TIMER_ENA_REG = Reg.Reg(
    LP_TIMER_BASE,
    0x40,
    enum { ENA },
    [_]Reg.Field{Reg.Field{ .offset = 31, .mask = 1 }},
);
const LP_TIMER_CLR_REG = Reg.Reg(
    LP_TIMER_BASE,
    0x44,
    enum { CLR },
    [_]Reg.Field{Reg.Field{ .offset = 31, .mask = 1 }},
);

const LP_CLKRST_FOSC_CNTL_REG = Reg.Reg(
    LP_CLKRST_BASE,
    0x18,
    enum { FOSC_DFREQ },
    [_]Reg.Field{Reg.Field{ .offset = 22, .mask = 0x3ff }},
);
const LP_CLKRST_RC32K_CNTL_REG = Reg.Reg(
    LP_CLKRST_BASE,
    0x001C,
    enum { RC32K_DFREQ },
    [_]Reg.Field{Reg.Field{ .offset = 22, .mask = 0x3ff }},
);

const SOC_RTC_FAST_CLK_SRC = enum(u2) {
    RC_FAST,
    XTAL_D2,
    XTAL_DIV,
    INVALID,
};

const SOC_RTC_SLOW_CLK_SRC = enum(u3) {
    RC_SLOW,
    XTAL32K,
    RC32K,
    OSC_SLOW,
    INVALID,
};

const rtc_clk_config = struct {
    xtal_freq: u32,
    cpu_freq_mhz: u32,
    fast_clk_src: SOC_RTC_FAST_CLK_SRC,
    slow_clk_src: SOC_RTC_SLOW_CLK_SRC,
    clk_rtc_clk_div: u32,
    clk_8m_clk_div: u32,
    slow_clk_dcap: u32,
    clk_8m_dfreq: u32,
    rc32k_dfreq: u32,

    pub fn default() rtc_clk_config {
        return .{
            .xtal_freq = CONFIG_XTAL_FREQ,
            .cpu_freq_mhz = 80,
            .fast_clk_src = SOC_RTC_FAST_CLK_SRC.RC_FAST,
            .slow_clk_src = SOC_RTC_SLOW_CLK_SRC.RC_SLOW,
            .clk_rtc_clk_div = 0,
            .clk_8m_clk_div = 0,
            .slow_clk_dcap = RTC_CNTL_SCK_DCAP_DEFAULT,
            .clk_8m_dfreq = RTC_CNTL_CK8M_DFREQ_DEFAULT,
            .rc32k_dfreq = RTC_CNTL_RC32K_DFREQ_DEFAULT,
        };
    }
};

pub fn clock_configure() void {
    const cpu_freq_mhz = CPU_CLK_FREQ_MHZ_BTLD;
    var cfg: rtc_clk_config = rtc_clk_config.default();
    cfg.cpu_freq_mhz = cpu_freq_mhz;
    LP_CLKRST_FOSC_CNTL_REG.set(.FOSC_DFREQ, cfg.clk_8m_dfreq);
    LP_CLKRST_RC32K_CNTL_REG.set(.RC32K_DFREQ, cfg.rc32k_dfreq);

    LP_TIMER_ENA_REG.set(.ENA, 0);
    LP_TIMER_CLR_REG.set(.CLR, 1);

    LP_ANALOG_PERI_FIB_ENA_REG.set(.SWD, 0);
    LP_ANALOG_PERI_FIB_ENA_REG.set(.BOD, 0);

    LP_ANALOG_PERI_INT_ENA_REG.set(.ENA, 0);
    LP_ANALOG_PERI_INT_CLR_REG.set(.CLR, 1);

    PMU_HP_INT_ENA_REG.set(.SOC_WAKEUP, 0);
    PMU_HP_INT_ENA_REG.set(.SOC_SLEEP_REJECT, 0);
    // main.set_reg(LP_CLKRST, FOSC_CNTL_REG, FOSC_DFREQ, cfg.clk_8m_dfreq);
}

test "Check FOSC_CNTL_REG" {
    // FOSC_CNTL_REG.set(.FOSC_DFREQ, 23);
    //
    // try expect(@intFromEnum(FOSC_CNTL_REG.testing().FOSC_DFREQ) == 22);
}
