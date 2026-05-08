const std = @import("std");
const reg = @import("registers.zig");
const ins = @import("instructions.zig");
const desc = @import("descriptors.zig");
const mair = @import("mair.zig");

const TABLE_L1_ENTRY: u64 = 1 << 30;
const TABLE_MAX_SIZE: u64 = 512;
const BLOCK_TABLE_ALIGN = std.mem.Alignment.fromByteUnits(TABLE_MAX_SIZE*@sizeOf(desc.BlockDescriptor));

pub fn setupTCR() void {
    var tcr = reg.TCR_EL1.read();
    // lower space
    tcr.t0sz = 16;
    tcr.epd0 = false;
    tcr.irgn0 = 0b01;
    tcr.orgn0 = 0b01;
    tcr.sh0 = 0b11;
    tcr.tg0 = 0b00;
    
    // higher space
    tcr.t1sz = 34;
    tcr.a1 = true;
    tcr.epd1 = false;
    tcr.irgn1 = 0b01;
    tcr.orgn1 = 0b01;
    tcr.sh1 = 0b11;
    tcr.tg1 = 0b00;

    // inner physical size
    tcr.ips = 0b101;
    tcr.write();
    // ins.synchronizeInstructions();
}

pub fn setupIdentityMap(alloc: std.mem.Allocator, kernel_start: usize) !void {
    const tbl0_l0: *desc.TableDescriptor = @ptrCast((try alloc.alignedAlloc(desc.TableDescriptor, .@"32", 1)).ptr);
    const tbl0_l1 = try alloc.alignedAlloc(desc.BlockDescriptor, BLOCK_TABLE_ALIGN, TABLE_MAX_SIZE);
    tbl0_l0.* = .fromPointer(tbl0_l1.ptr);
    tbl0_l0.attributes.xn_table = true;
    const l1_phys_size = 1 << 30; // gb step
    for (tbl0_l1, 0..) |*entry, i| {
        const physical_address: *const u8 = @ptrFromInt(l1_phys_size * i);
        entry.* = .fromPointer(physical_address);
        if(i == 0) { // device memory
            entry.upper_attributes.xn = true;
            entry.upper_attributes.pxn = true;
            entry.lower_attributes.af = true;
            entry.lower_attributes.sh = 0b00;
            entry.lower_attributes.ap = 0b00;
            entry.lower_attributes.attr_index = mair.MT_DEVICE_nGnRnE;
        } else {
            entry.upper_attributes.xn = false;
            entry.upper_attributes.pxn = false;
            entry.lower_attributes.af = true;
            entry.lower_attributes.sh = 0b11;
            entry.lower_attributes.ap = 0b00;
            entry.lower_attributes.attr_index = mair.MT_NORMAL;
        }
    }

    const tbl1_l2 = try alloc.alignedAlloc(desc.BlockDescriptor, BLOCK_TABLE_ALIGN, TABLE_MAX_SIZE);
    const l2_phys_size = 1 << 21;
    for (tbl1_l2, 0..) |*entry, i| {
        const physical_address: *const u8 = @ptrFromInt(kernel_start + l2_phys_size * i);
        entry.* = .fromPointer(physical_address);
        entry.upper_attributes.xn = false;
        entry.upper_attributes.pxn = false;
        entry.lower_attributes.af = true;
        entry.lower_attributes.sh = 0b11;
        entry.lower_attributes.ap = 0b00;
        entry.lower_attributes.attr_index = mair.MT_NORMAL;
    }

    const r_ttbr0: reg.TTBR0_EL1 = @bitCast(@intFromPtr(tbl0_l0));
    var r_ttbr1: reg.TTBR1_EL1 = @bitCast(@intFromPtr(tbl1_l2.ptr));
    r_ttbr1.skl = 2;
    r_ttbr0.write();
    r_ttbr1.write();
    // ins.synchronizeInstructions();
    // ins.invalidateTLB();
    // ins.synchronizeData();
    // ins.synchronizeInstructions();
}

pub fn enableMMU() void {
    var sctlr = reg.SCTLR_EL1.read();
    sctlr.m = true;
    sctlr.write();
}