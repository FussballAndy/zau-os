const std = @import("std");
const uefi = std.os.uefi;

const Status = uefi.Status;

const constants = @import("../consts.zig");
const KERNEL_PATH = constants.KERNEL_PATH;
const PAGE_SIZE = 4096;

const log = @import("../log.zig");

const UEFIReader = @import("UEFIReader.zig");
const elfAddon = @import("elf.zig");

pub const entryMod = @import("shared").entry;


pub const KernelData = struct {
    kernel_image: *uefi.protocol.File,
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

pub fn loadKernel(boot: *uefi.tables.BootServices, rootdir: *const uefi.protocol.File) !KernelData {
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
    

    var ph_it: elfAddon.ProgramHeaderIterator = .{ .elf_header = header, .file_reader = &kernel_reader };

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

    const image_addr_raw = boot.allocatePages(.any, .loader_data, (image_size + PAGE_SIZE - 1) / PAGE_SIZE) catch |err| {
        log.putslnErr("Failed to allocate page for kernel image.");
        return err;
    };
    const image_addr: []u8 = @ptrCast(image_addr_raw);

    @memset(image_addr[0..image_size], 0);

    ph_it.reset();

    while (ph_it.next() catch return handlePHeaderError()) |next| {
        if(next.p_type != std.elf.PT_LOAD) continue;

        const phdr_addr = next.p_vaddr - image_start;
        const phdr_addr_end = phdr_addr + next.p_filesz;
        const phdr_slice = image_addr[phdr_addr..phdr_addr_end];
        
        kernel_image.setPosition(next.p_offset) catch return handleReaderError();
        _ = kernel_image.read(phdr_slice) catch return handleReaderError();
    }

    // Note that here, just like in other places we subtract image_start which is because we load the parts of the
    // kernel into memory at their respective location minus image_start to not waste memory before the first actual content.
    // SAFETY: we calculate the entry point from the image address and the entry pointer in the header
    const kernel_image_entry_raw = @intFromPtr(image_addr.ptr) + header.entry - image_start;
    const kernel_image_entry: entryMod.EntryType = @ptrFromInt(kernel_image_entry_raw);

    return KernelData{
        .kernel_image = kernel_image,
        .kernel_image_entry = kernel_image_entry,
    };
}
