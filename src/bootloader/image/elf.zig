// Taken from std.elf, does not work anymore since std's IO and UEFI changes

const std = @import("std");
const elf = std.elf;
const Header = elf.Header;
const Elf64_Phdr = elf.Elf64_Phdr;
const Elf32_Phdr = elf.Elf32_Phdr;
const UEFIReader = @import("UEFIReader.zig");

pub const ProgramHeaderIterator = struct {
    elf_header: Header,
    file_reader: *UEFIReader,
    index: usize = 0,

    pub fn next(it: *ProgramHeaderIterator) !?Elf64_Phdr {
        if (it.index >= it.elf_header.phnum) return null;
        defer it.index += 1;

        const size: u64 = if (it.elf_header.is_64) @sizeOf(Elf64_Phdr) else @sizeOf(Elf32_Phdr);
        const offset = it.elf_header.phoff + size * it.index;
        try it.file_reader.seekTo(offset);

        return takePhdr(&it.file_reader.interface, it.elf_header);
    }

    pub fn reset(it: *ProgramHeaderIterator) void {
        it.index = 0;
    }
};

fn takePhdr(reader: *std.io.Reader, elf_header: Header) !?Elf64_Phdr {
    if (elf_header.is_64) {
        const phdr = try reader.takeStruct(Elf64_Phdr, elf_header.endian);
        return phdr;
    }

    const phdr = try reader.takeStruct(Elf32_Phdr, elf_header.endian);
    return .{
        .p_type = phdr.p_type,
        .p_offset = phdr.p_offset,
        .p_vaddr = phdr.p_vaddr,
        .p_paddr = phdr.p_paddr,
        .p_filesz = phdr.p_filesz,
        .p_memsz = phdr.p_memsz,
        .p_flags = phdr.p_flags,
        .p_align = phdr.p_align,
    };
}