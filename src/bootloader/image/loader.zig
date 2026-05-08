const std = @import("std");
const uefi = std.os.uefi;

const constants = @import("../consts.zig");
const KERNEL_PATH = constants.KERNEL_PATH;
const PAGE_SIZE = 4096;

const log = @import("../log.zig");

const UEFIReader = @import("UEFIReader.zig");
const elfAddon = @import("elf.zig");

pub const entryMod = @import("shared").entry;

pub const KernelData = struct {
    physical_start: usize,
    virtual_start: usize,
    kernel_image_entry: entryMod.EntryType,
};

fn handlePHeaderError() uefi.Error {
    log.putslnErr("Failed to read next program header.");
    return uefi.Error.Unsupported;
}

fn handleReaderError() uefi.Error {
    log.putslnErr("Failed to read program header slice into memory.");
    return uefi.Error.Aborted;
}

pub fn loadKernel(boot: *uefi.tables.BootServices, rootdir: *const uefi.protocol.File, alloc: std.mem.Allocator) uefi.Error!KernelData {
    const kernel_image = rootdir.open(KERNEL_PATH, .read, .{ .read_only = true }) catch |err| {
        log.putslnErr("Failed to open kernel image file.");
        return err;
    };

    var reader_buffer = std.mem.zeroes([1024]u8);

    var kernel_reader = UEFIReader.init(kernel_image, &reader_buffer);

    const header = std.elf.Header.read(&kernel_reader.interface) catch {
        log.putslnErr("Failed to read header");
        return uefi.Error.Aborted;
    };

    const p_headers = alloc.alloc(std.elf.Elf64_Phdr, header.phnum) catch return uefi.Error.OutOfResources;

    var ph_it: elfAddon.ProgramHeaderIterator = .{ .elf_header = header, .file_reader = &kernel_reader };
    var i: usize = 0;
    while (ph_it.next() catch return handlePHeaderError()) |next| {
        p_headers[i] = next;
        i += 1;
    }

    var image_start: usize = std.math.maxInt(usize);
    var image_end: usize = 0;
    for (p_headers) |next| {
        if (next.p_type != std.elf.PT_LOAD) continue;

        const alignment = @max(next.p_align, PAGE_SIZE);

        const hdr_begin = std.mem.alignBackward(u64, next.p_vaddr, alignment);
        if (image_start > hdr_begin) {
            image_start = hdr_begin;
        }

        const hdr_end = std.mem.alignForward(u64, next.p_vaddr + next.p_memsz, alignment);
        if (image_end < hdr_end) {
            image_end = hdr_end;
        }
    }

    const image_size = image_end - image_start;

    const kernel_alignment = 1 << 21; // allign kernel on 2MB basis (for vmapping)
    const image_pages = (image_size + kernel_alignment + PAGE_SIZE - 1) / PAGE_SIZE;

    const image_addr_alloc = boot.allocatePages(.any, .vendor_start, image_pages) catch |err| {
        log.putslnErr("Failed to allocate page for kernel image.");
        return err;
    };
    const image_addr_raw = @intFromPtr(image_addr_alloc.ptr);
    const image_addr_aligned = std.mem.alignForward(usize, image_addr_raw, kernel_alignment);
    var image_addr_ptr: [*]u8 = @ptrFromInt(image_addr_aligned);
    var image_addr = image_addr_ptr[0..image_size];

    @memset(image_addr, 0);

    for (p_headers) |next| {
        if (next.p_type != std.elf.PT_LOAD) continue;

        const phdr_addr = next.p_vaddr - image_start;
        const phdr_addr_end = phdr_addr + next.p_filesz;
        const phdr_slice = image_addr[phdr_addr..phdr_addr_end];

        kernel_image.setPosition(next.p_offset) catch return handleReaderError();
        _ = kernel_image.read(phdr_slice) catch return handleReaderError();
    }

    try kernel_image.close();

    return KernelData{
        .physical_start = image_addr_aligned,
        .virtual_start = image_start,
        .kernel_image_entry = @ptrFromInt(header.entry),
    };
}
