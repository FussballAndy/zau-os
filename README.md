# **Z**ig **A**Arch **U**EFI OS

A continuation of my uefi bootloader (found [here](https://github.com/FussballAndy/zig-aarch64-kernel/tree/uefi)), turning it into a OS. WIP!

## Notes on emulating in QEMU

In order to start emulating this in QEMU you need a UEFI Firmware image. The [edk2 project](https://github.com/tianocore/edk2) provides such files however, unless
you are on a linux system, obtaining these files is a bit tricky.

So for Linux users simply fetch the `qemu-efi-aarch64` package and continue reading at the final stretch (if your package manager of choice has it, else continue reading).

For everyone else we are also going to download the files of said package from the debian packages website ([here](https://packages.debian.org/bookworm/qemu-efi-aarch64)) by clicking on `all` on the left and then choosing a mirror to download from (note that chromium browsers tend to block the download, so you may need to copy the address and paste it manually so that the browser actually prompts you whether you want to keep the download).

Now to get our lovely QEMU_EFI.fd file from this `.deb` file we need to extract it. Luckily `.deb` files are just ar archives. So on linux you can extract it using the `ar` command. On windows either use a tool like mingw or llvm ships `llvm-ar` which works equally here.

Then the command should be something along the lines of:
```sh
(llvm-)ar x "qemu-efi-aarch64.deb" --output "qemu-efi-output"
```
obviously the name of the .deb file and the output folder can be adjusted manually.

Now all you need to do is open the `data.tar.xz` file (which can be opened by pretty much any archive viewer/extractor) and grab the `./usr/share/qemu-efi-aarch64/QEMU_EFI.fd` file.

Now for the final stretch we need to turn this .fd file into a 64mb flash file. Linux users can simply use `dd` here and luckily for windows users git bash's mingw version
although not shipping ar, ships a dd version which works just the same.
So simply run the following two commands (further info can be found on kraxel's blog [here](https://www.kraxel.org/blog/2022/05/edk2-virt-quickstart/))
```sh
dd of="QEMU_EFI-pflash.raw" if="/dev/zero" bs=1M count=64
dd of="QEMU_EFI-pflash.raw" if="QEMU_EFI.fd" conv=notrunc
```

Now after all that is setup simply run the following command in the root directory:
```sh
qemu-system-aarch64 -machine virt -cpu max -drive if=pflash,format=raw,file=QEMU_EFI-pflash.raw -drive format=raw,file=fat:rw:./vm -net none -device ramfb -usb -device usb-ehci,id=ehci -device usb-kbd,bus=ehci.0
```

Once the uefi shell is ready for input, simply enter `boot_arm64.efi`.

Note that this will use an american keyboard layout. Additionally I use the directory `./vm` for future purposes if there ever is a proper fs. So before running you may want to create this directory and copy the `boot_arm64.efi` and `kernel` file into there.