pub fn getCurrentEl() usize {
    return asm (
        "mrs %[res], CurrentEL"
        : [res] "=r" (-> usize)
    ) >> 2;
}