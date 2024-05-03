pub inline fn w_mepc(addr: u64) void {
    asm volatile ("csrw mepc, %0"
        :
        : [addr] "r" (addr),
    );
}
