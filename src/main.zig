pub const panic = @compileError("panic not allowed in freestanding build");

export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\ ldr sp, =0x4000
        \\ mov r0, #10
        \\ mov r1, #40
        \\ mov r4, #66
        \\ add r0, r1, r4
        \\ sub r4, r0, r4
    );
    while (true) {}
}
