# **Z**ig **A**Arch **U**EFI OS

A continuation of my uefi bootloader (found [here](https://github.com/FussballAndy/zig-aarch64-kernel/tree/uefi)), turning it into a OS. WIP!

## Notes on emulating in QEMU

To emulate the OS, the following QEMU setup is used:
```sh
qemu-system-aarch64 -machine virt -cpu max -bios "/path/to/qemu/share/edk2-aarch64-code.fd" -drive format=raw,file=fat:rw:./vm -net none -device ramfb -usb -device usb-ehci,id=ehci -device usb-kbd,bus=ehci.0
```

Once the uefi shell is ready for input, simply enter `boot_arm64.efi`.

Note that this will use an american keyboard layout. Additionally I use the directory `./vm` for future purposes if there ever is a proper fs. So before running you may want to create this directory and copy the `boot_arm64.efi` and `kernel` file into there.