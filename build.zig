const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    const optimize = b.standardOptimizeOption(.{});

    const root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // -------------------------------------------------
    // 1. Build ELF executable (WITH debug symbols)
    // -------------------------------------------------
    const exe = b.addExecutable(.{
        .name = "dbg",
        .root_module = root_module,
    });

    exe.root_module.strip = true;
    exe.pie = false;
    exe.entry = .{ .symbol_name = "_start" };
    exe.link_gc_sections = true;
    exe.linker_script = b.path("linker.ld");

    exe.pie = false;
    exe.entry = .{ .symbol_name = "_start" };

    // Install ELF (creates zig-out/bin automatically)
    b.installArtifact(exe);

    // -------------------------------------------------
    // 2. Convert ELF → flat binary
    // -------------------------------------------------

    // Ensure output directory exists
    const mkdir = b.addSystemCommand(&.{
        "mkdir",
        "-p",
        "zig-out/bin",
    });
    mkdir.step.dependOn(&exe.step);

    const objcopy = b.addSystemCommand(&.{
        "zig",
        "objcopy",
        "-O",
        "binary",
    });

    objcopy.addArtifactArg(exe);
    objcopy.addArg("zig-out/bin/main.bin");

    objcopy.step.dependOn(&mkdir.step);

    // -------------------------------------------------
    // 3. QEMU Normal Run (flat binary)
    // -------------------------------------------------
    const run_qemu = b.addSystemCommand(&.{
        "qemu-system-arm",
        "-M", "versatilepb", // The Board
        "-cpu", "arm926", // <--- CHANGED: Matches your list exactly
        //"-nographic", // use current terminal for I/O
        "-serial", "stdio", // Redirect serial to terminal
        "-semihosting", // enable semihosting for print support
        "-kernel",
        "zig-out/bin/main.bin",
    });

    run_qemu.step.dependOn(&objcopy.step);

    // -------------------------------------------------
    // 4. QEMU Debug Mode (freeze + GDB)
    // -------------------------------------------------
    const run_qemu_dbg = b.addSystemCommand(&.{
        "qemu-system-arm",
        "-M", "versatilepb", // The Board
        "-cpu", "arm926", // <--- CHANGED: Matches your list exactly
        //"-nographic", // use current terminal for I/O
        "-serial", "stdio", // Redirect serial to terminal
        "-semihosting", // enable semihosting for print support
        "-kernel",
        "zig-out/bin/main.bin",
    });

    run_qemu_dbg.step.dependOn(&objcopy.step);

    // -------------------------------------------------
    // 5. Windows QEMU (from WSL)
    // -------------------------------------------------
    const run_qemu_win = b.addSystemCommand(&.{
        "/mnt/c/msys64/ucrt64/bin/qemu-system-arm.exe",
        "-M", "versatilepb", // The Board
        "-cpu", "arm926", // <--- CHANGED: Matches your list exactly
        //"-nographic", // use current terminal for I/O
        "-serial", "stdio", // Redirect serial to terminal
        "-semihosting", // enable semihosting for print support
        "-kernel",
        "zig-out/bin/main.bin",
    });

    run_qemu_win.step.dependOn(&objcopy.step);

    // -------------------------------------------------
    // 6. Expose build steps
    // -------------------------------------------------
    b.step("elf", "Build ELF with debug symbols")
        .dependOn(&exe.step);

    b.step("bin", "Build flat ARM binary")
        .dependOn(&objcopy.step);

    b.step("run", "Run in QEMU (Linux/WSL)")
        .dependOn(&run_qemu.step);

    b.step("run-dbg", "Run in QEMU Debug mode (freeze)")
        .dependOn(&run_qemu_dbg.step);

    b.step("run-wsl", "Run Windows QEMU from WSL")
        .dependOn(&run_qemu_win.step);
}
