# GC32-20020 - An emulator for the Govno Core 32-20020 Gen 1 Tiger CPU

## Description
A 32-bit CPU, a successor to Govno Core 32 Igor. It is binary-compatible with the old Govno Core 32 CPU, and runs the same ROM and BIOS images without any changes to the binary.
However, the assembly is a little bit different

## Usage
```bash
gcc core/ball.c -o ball              # Bootstrap (use only on non-x86 platforms)
./ball                               # Build the tools and the emulator
sudo ./ball install                  # Install to $PATH
./prepare-disk disk.img              # Build GovnBIOS & GovnOS
./gc32-20020 -b bios.img -d disk.img # Run GovnOS on GC32-20020
```
Z

