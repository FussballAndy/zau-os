pub fn synchronizeInstructions() void {
    asm volatile ("isb sy");
}

pub fn synchronizeData() void {
    asm volatile ("dsb nsh");
}

pub fn invalidateTLB() void {
    asm volatile ("tlbi vmalle1");
}