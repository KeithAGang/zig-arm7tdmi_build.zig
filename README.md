# ARM7TDMI Flat Binary Generator

This project is configured to compile Zig inline assembly into **flat ARM7TDMI binaries**. It is primarily intended to generate test binaries for the [ARM7TDMI Interpreter in Zig](https://github.com/KeithAGang/arm7tdmi-interpreter-zig) project.

The build system handles cross-compilation to ARM, linking via a custom linker script, and conversion from ELF to a raw binary format, removing ELF headers and overhead to produce a pure instruction stream.

## Features

- **Target**: ARM7TDMI (`arm-freestanding-eabi`).
- **Output**: Raw flat binary (`.bin`) generated via `objcopy`.
- **Emulation**: Integrated QEMU run steps for testing.
- **Debug Support**: Includes a QEMU GDB stub run target for stepping through execution.

## Usage

### Build Requirements

Due to the freestanding nature of the code and the absence of a panic handler, you **must** build with the `ReleaseSmall` optimization level.

```bash
zig build bin -Doptimize=ReleaseSmall
```

**Why `ReleaseSmall`?**
The file `src/main.zig` explicitly forbids panic generation:
```zig
pub const panic = @compileError("panic not allowed in freestanding build");
```
In standard `Debug` builds, Zig inserts safety checks (e.g., overflow protection) that require a panic handler. Using `ReleaseSmall` eliminates these checks, allowing the code to compile without a runtime panic implementation and ensuring the resulting binary contains only the intended assembly instructions without bloat.

### Build Artifacts

- **Flat Binary**: `zig-out/bin/main.bin` (The final artifact for the interpreter).
- **ELF Executable**: `zig-out/bin/dbg` (Intermediate artifact).

### Running in QEMU

The `build.zig` file provides several steps to run the generated binary in QEMU.

| Step | Command | Description |
|------|---------|-------------|
| **Run** | `zig build run -Doptimize=ReleaseSmall` | Runs the binary in QEMU (`versatilepb`, `arm926`). |
| **Debug** | `zig build run-dbg -Doptimize=ReleaseSmall` | Runs QEMU paused (`-S`) with a GDB stub on port 1234 (`-s`). |
| **WSL** | `zig build run-wsl -Doptimize=ReleaseSmall` | Launches the Windows version of QEMU from a WSL environment. |

## Project Layout

- **`build.zig`**: Defines the build pipeline:
    1. Compiles `src/main.zig` as an ELF executable.
    2. Strips symbols to ensure minimal size.
    3. Uses `objcopy` to extract the raw binary.
- **`src/main.zig`**: Entry point containing the inline assembly to be compiled.