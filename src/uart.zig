const Field = @import("reg.zig").Field;
const Reg = @import("reg.zig").Reg;

const UART0_BASE = 0x60000000;
const UART_INT_ST_REG_OFFSET = 0x0008;
const UART_INT_ENA_REG_OFFSET = 0x000C;
const UART_INT_CLR_REG_OFFSET = 0x0010;
const UART_CONF1_REG_OFFSET = 0x0024;

const UART_FIFO_REG = Reg(
    UART0_BASE,
    0,
    enum { RXFIFO_RD_BYTE },
    [_]Field{
        Field{ .offset = 0, .mask = 0xFF },
    },
);

const UART_INT = enum { TXFIFO_EMPTY };
const UART_INT_ENA_REG = Reg(
    UART0_BASE,
    UART_INT_ENA_REG_OFFSET,
    UART_INT,
    [_]Field{
        Field{ .offset = 2, .mask = 0x1 },
    },
);

const UART_INT_ST_REG = Reg(
    UART0_BASE,
    UART_INT_ST_REG_OFFSET,
    UART_INT,
    [_]Field{
        Field{ .offset = 2, .mask = 0x1 },
    },
);

const UART_INT_CLR_REG = Reg(
    UART0_BASE,
    UART_INT_CLR_REG_OFFSET,
    UART_INT,
    [_]Field{
        Field{ .offset = 2, .mask = 0x1 },
    },
);

pub fn uart_tx(message: []const u8) void {
    // Set the empty threshold
    // *(uint32_t *)(UART0_BASE + UART_CONF1_REG) = sizeof(bytes);
    //
    for (message) |byte| {
        // disable empty interrupt
        UART_INT_ENA_REG.set(.TXFIFO_EMPTY, 0);
        // write data to FIFO
        UART_FIFO_REG.set(.RXFIFO_RD_BYTE, byte);
        // clear empty interrupt
        UART_INT_CLR_REG.set(.TXFIFO_EMPTY, 0);
        // enable empty interrupt
        UART_INT_ENA_REG.set(.TXFIFO_EMPTY, 1);
    }
}

test {
    UART_INT_ENA_REG.set(.TXFIFO_EMPTY, 0);
}
