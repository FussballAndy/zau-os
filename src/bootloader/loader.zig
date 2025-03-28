const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;
const EfiError = Status.EfiError;

const constants = @import("./consts.zig");
const KERNEL_PATH = constants.KERNEL_PATH;
const PAGE_SIZE = 4096;

const statusMod = @import("./status.zig");
const Result = statusMod.UefiResult(KernelData);

const log = @import("./log.zig");

pub const entryMod = @import("shared").entry;


pub const KernelData = struct {
    kernel_image: *uefi.protocol.File,
    kernel_image_entry: entryMod.EntryType,
};

fn handlePHeaderError() Result {
    log.putslnErr("Failed to read next program header.");
    return Result{.err = Status.unsupported};
}

fn handleReaderError() Result {
    log.putslnErr("Failed to read program header slice into memory.");
    return Result{.err = Status.aborted};
}

pub fn loadKernel(boot: *uefi.tables.BootServices, rootdir: *const uefi.protocol.File) Result {
    var kernel_image_const: *const uefi.protocol.File = undefined;

    var status = rootdir.open(&kernel_image_const, KERNEL_PATH, uefi.protocol.File.efi_file_mode_read, uefi.protocol.File.efi_file_read_only);
    if(status != .success) {
        log.putslnErr("Failed to open kernel image file.");
        return Result{.err = status};
    }

    const kernel_image: *uefi.protocol.File = @constCast(kernel_image_const);

    const header = std.elf.Header.read(kernel_image) catch {
        log.putslnErr("Failed to read header");
        return Result{.err = Status.aborted};
    };
    

    var ph_it = header.program_header_iterator(kernel_image);

    var image_start: usize = std.math.maxInt(usize);
    var image_end: usize = 0;
    while(ph_it.next() catch return handlePHeaderError()) |next| {
        if(next.p_type != std.elf.PT_LOAD) continue;

        
        const alignment = @max(next.p_align, PAGE_SIZE);

        const hdr_begin = std.mem.alignBackward(u64, next.p_vaddr, alignment);
        if(image_start > hdr_begin) {
            image_start = hdr_begin;
        }

        const hdr_end = std.mem.alignForward(u64, next.p_vaddr + next.p_memsz, alignment);
        if(image_end < hdr_end) {
            image_end = hdr_end;
        }
    }

    const image_size = image_end - image_start;

    var image_addr: [*]align(PAGE_SIZE) u8 = undefined;

    status = boot.allocatePages(uefi.tables.AllocateType.allocate_any_pages, uefi.tables.MemoryType.loader_data, image_size / PAGE_SIZE, &image_addr);
    if(status != .success) {
        log.putslnErr("Failed to allocate page for kernel image.");
        return Result{.err = status};
    }

    @memset(image_addr[0..image_size], 0);

    ph_it = header.program_header_iterator(kernel_image);

    while (ph_it.next() catch return handlePHeaderError()) |next| {
        if(next.p_type != std.elf.PT_LOAD) continue;

        const phdr_addr = next.p_vaddr - image_start;
        const phdr_addr_end = phdr_addr + next.p_filesz;
        const phdr_slice = image_addr[phdr_addr..phdr_addr_end];

        kernel_image.seekableStream().seekTo(next.p_offset) catch return handleReaderError();
        _ = kernel_image.reader().read(phdr_slice) catch return handleReaderError();
    }

    // Note that here, just like in other places we subtract image_start which is because we load the parts of the
    // kernel into memory at their respective location minus image_start to not waste memory before the first actual content.
    // SAFETY: we calculate the entry point from the image address and the entry pointer in the header
    const kernel_image_entry_raw = @intFromPtr(image_addr) + header.entry - image_start;
    const kernel_image_entry: entryMod.EntryType = @ptrFromInt(kernel_image_entry_raw);

    return Result{.ok = KernelData{
        .kernel_image = kernel_image,
        .kernel_image_entry = kernel_image_entry,
    }};
}
