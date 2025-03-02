pub fn getCurrentEl() usize {
    return asm (
        "mrs %[res], CurrentEL"
        : [res] "=r" (-> usize)
    ) >> 2;
}

pub fn getSPSel() usize {
    return asm (
        "mrs %[res], SPSel"
        : [res] "=r" (-> usize)
    );
}