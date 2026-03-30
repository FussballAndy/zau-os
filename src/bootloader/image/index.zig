//! Functions for loading and executing the kernel image

const std = @import("std");
const uefi = std.os.uefi;
const Status = uefi.Status;

const loader = @import("./loader.zig");

const log = @import("../log.zig");

const constants = @import("../consts.zig");

pub fn loadKernelFromDisk(boot: *uefi.tables.BootServices, alloc: std.mem.Allocator) uefi.Error!loader.KernelData {
    const image = boot.openProtocol(uefi.protocol.LoadedImage, uefi.handle, .{ .by_handle_protocol = .{ .agent = uefi.handle } }) catch |err| {
        log.putslnErr("Failed to open loaded image protocol!");
        return err;
    };

    if (image == null) {
        log.putslnErr("Image somehow is null.");
        return uefi.Error.Aborted;
    }

    const root_device = image.?.device_handle orelse return uefi.Error.Aborted;

    const rootfs_raw = boot.openProtocol(uefi.protocol.SimpleFileSystem, root_device, .{ .by_handle_protocol = .{ .agent = uefi.handle } }) catch |err| {
        log.putslnErr("Failed to get root volume");
        return err;
    };

    var rootfs = rootfs_raw orelse return uefi.Error.Aborted;
    const rootdir = rootfs.openVolume() catch |err| {
        log.putslnErr("Failed to open volume.");
        return err;
    };

    const kernel_result = loader.loadKernel(boot, rootdir, alloc);

    boot.closeProtocol(root_device, uefi.protocol.SimpleFileSystem, uefi.handle, null) catch |err| {
        log.putslnErr("Failed to close SimpleFS protocol.");
        return err;
    };

    boot.closeProtocol(uefi.handle, uefi.protocol.LoadedImage, uefi.handle, null) catch |err| {
        log.putslnErr("Failed to close LoadedImage protocol.");
        return err;
    };

    return kernel_result;
}
