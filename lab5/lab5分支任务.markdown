## 1. 在大模型的帮助下，完成整个调试的流程，观察一下ecall指令和sret指令是如何被qemu处理的，并简单阅读一下调试中涉及到的qemu源码，解释其中的关键流程。
开启挂在到qemu的终端, 并开启忽略管道信号, 并且打上ecall处的条件断点 **`break riscv_cpu_do_interrupt if cs->exception_index == 8`**, 这里的 8 正好代表User 态下的 ecall的异常号.
在ucore中执行下一步(ecall)了, 此时终端2会触发ecall异常导致终端, 先查看一些基础信息:
```bash
[Switching to Thread 0x7f28bffff640 (LWP 8094)]

Thread 3 "qemu-system-ris" hit Breakpoint 1, riscv_cpu_do_interrupt (cs=0x55eafa673f90) at /root/qemu-4.1.1/target/riscv/cpu_helper.c:507
507         RISCVCPU *cpu = RISCV_CPU(cs);
(gdb) bt
#0  riscv_cpu_do_interrupt (cs=0x55eafa673f90) at /root/qemu-4.1.1/target/riscv/cpu_helper.c:507
#1  0x000055eaf879425f in cpu_handle_exception (cpu=0x55eafa673f90, ret=0x7f28bfffe90c)
    at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:506
#2  0x000055eaf87948fa in cpu_exec (cpu=0x55eafa673f90) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:712
#3  0x000055eaf8746f16 in tcg_cpu_exec (cpu=0x55eafa673f90) at /root/qemu-4.1.1/cpus.c:1435
#4  0x000055eaf87477cf in qemu_tcg_cpu_thread_fn (arg=0x55eafa673f90) at /root/qemu-4.1.1/cpus.c:1743
#5  0x000055eaf8bcbbd3 in qemu_thread_start (args=0x55eafa68a630) at util/qemu-thread-posix.c:502
#6  0x00007f28c6ffeac3 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:442
#7  0x00007f28c70908c0 in clone3 () at ../sysdeps/unix/sysv/linux/x86_64/clone3.S:81
(gdb) info args
cs = 0x55eafa673f90
(gdb) info locals
cpu = 0x55eaf8747b18 <qemu_mutex_lock_iothread_impl+110>
__func__ = "riscv_cpu_do_interrupt"
env = 0x1f9f8ce9853
async = false
cause = 4174289584
deleg = 94467684997384
tval = 139812996638896
ecall_cause_map = {8, 9, 10, 11}
__PRETTY_FUNCTION__ = "riscv_cpu_do_interrupt"
```

此时正在处理异常的函数的开头, 因此栈顶的局部变量还没有被赋值, 因此是残留的陌生数字, 使用命令查看错误触发理由:
```
(gdb) p cs->exception_index
$1 = 8
```
发现是8, 正常. 然后使用命令 `n` 一步一步执行

```
(gdb) n
508         CPURISCVState *env = &cpu->env;
(gdb) n
513         bool async = !!(cs->exception_index & RISCV_EXCP_INT_FLAG);
(gdb) n
514         target_ulong cause = cs->exception_index & RISCV_EXCP_INT_MASK;
(gdb) n
515         target_ulong deleg = async ? env->mideleg : env->medeleg;
(gdb) n
516         target_ulong tval = 0;
(gdb) n
525         if (!async) {
    (gdb) n
527             switch (cause) {
(gdb) n
540                 break;
(gdb) n
543             if (cause == RISCV_EXCP_U_ECALL) {
(gdb) n
544                 assert(env->priv <= 3);
(gdb) n
545                 cause = ecall_cause_map[env->priv];
(gdb) n
549         trace_riscv_trap(env->mhartid, async, cause, env->pc, tval, cause < 16 ?
(gdb) n
550             (async ? riscv_intr_names : riscv_excp_names)[cause] : "(unknown)");
(gdb) n
549         trace_riscv_trap(env->mhartid, async, cause, env->pc, tval, cause < 16 ?
(gdb) n
552         if (env->priv <= PRV_S &&
(gdb) n
553                 cause < TARGET_LONG_BITS && ((deleg >> cause) & 1)) {
(gdb) n
555             target_ulong s = env->mstatus;
(gdb) n
556             s = set_field(s, MSTATUS_SPIE, env->priv_ver >= PRIV_VERSION_1_10_0 ?
(gdb) n
558             s = set_field(s, MSTATUS_SPP, env->priv);
(gdb) n
559             s = set_field(s, MSTATUS_SIE, 0);
(gdb) n
560             env->mstatus = s;
(gdb) p env->priv  # 到这里的特权级仍为0 (U), 说明还没有切换特权级
$8 = 0
(gdb) n
561             env->scause = cause | ((target_ulong)async << (TARGET_LONG_BITS - 1));
(gdb) n
562             env->sepc = env->pc;
(gdb) p env->scause   # 异常原因码（8 = U-mode ecall）
$9 = 8
(gdb) n
563             env->sbadaddr = tval;
(gdb) p env->sepc 
$10 = 8388868
(gdb) n
564             env->pc = (env->stvec >> 2 << 2) +
(gdb) n
565                 ((async && (env->stvec & 3) == 1) ? cause * 4 : 0);
(gdb) n
564             env->pc = (env->stvec >> 2 << 2) +
(gdb) n
566             riscv_cpu_set_mode(env, PRV_S);
(gdb) n
553                 cause < TARGET_LONG_BITS && ((deleg >> cause) & 1)) {
(gdb) p env->priv
$11 = 1    # 特权级切换到了1 (S)
(gdb) n
590         cs->exception_index = EXCP_NONE; /* mark handled to qemu */
(gdb) n
591     }
(gdb) n
cpu_handle_exception (cpu=0x55eafa673f90, ret=0x7f28bfffe90c) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:507
507                 qemu_mutex_unlock_iothread();
```

这里riscv_cpu_do_interrupt 执行完毕, 完成了sepc, scause的赋值和特权级 priv 的切换, 并成功跳转到了 stvec 指向的地址, 即 ecall 处理完毕.

接下来让终端2 继续运行, 等待下一次断点.



然后在终端2 中, ctrl+c 停下后, 打上断点`b helper_sret`, 然后继续运行, 转到终端3 si 进行下一步, 此时终端2 捕获到断点, 下面是调试信息:
```bash
Thread 3 "qemu-system-ris" hit Breakpoint 2, helper_sret (env=0x55eafa67c9a0, cpu_pc_deb=18446744072637910850) at /root/qemu-4.1.1/target/riscv/op_helper.c:76
76          if (!(env->priv >= PRV_S)) {
(gdb) bt
#0  helper_sret (env=0x55eafa67c9a0, cpu_pc_deb=18446744072637910850) at /root/qemu-4.1.1/target/riscv/op_helper.c:76
#1  0x00007f28c466d122 in code_gen_buffer ()
#2  0x000055eaf879373b in cpu_tb_exec (cpu=0x55eafa673f90, itb=0x7f28c466d040 <code_gen_buffer+19>)
    at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:173
#3  0x000055eaf8794581 in cpu_loop_exec_tb (cpu=0x55eafa673f90, tb=0x7f28c466d040 <code_gen_buffer+19>, 
    last_tb=0x7f28bfffe918, tb_exit=0x7f28bfffe910) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:621
#4  0x000055eaf87948b6 in cpu_exec (cpu=0x55eafa673f90) at /root/qemu-4.1.1/accel/tcg/cpu-exec.c:732
#5  0x000055eaf8746f16 in tcg_cpu_exec (cpu=0x55eafa673f90) at /root/qemu-4.1.1/cpus.c:1435
#6  0x000055eaf87477cf in qemu_tcg_cpu_thread_fn (arg=0x55eafa673f90) at /root/qemu-4.1.1/cpus.c:1743
#7  0x000055eaf8bcbbd3 in qemu_thread_start (args=0x55eafa68a630) at util/qemu-thread-posix.c:502
#8  0x00007f28c6ffeac3 in start_thread (arg=<optimized out>) at ./nptl/pthread_create.c:442
#9  0x00007f28c70908c0 in clone3 () at ../sysdeps/unix/sysv/linux/x86_64/clone3.S:81
(gdb) p env->priv       # 当前处于 S 模式, sret 必须在 S 模式下执行. 
$12 = 1
(gdb) p env->sepc
$13 = 8388872 # 0x800108, 即要返回的ecall(0x800104)的下一条指令的地址
(gdb) p env->pc
$14 = 18446744072637910850
(gdb) n
80          target_ulong retpc = env->sepc; # 取出 sepc 寄存器的值，作为即将返回的目标 PC
(gdb) n
81          if (!riscv_has_ext(env, RVC) && (retpc & 0x3)) {
(gdb) n
85          if (env->priv_ver >= PRIV_VERSION_1_10_0 &&
(gdb) n
86              get_field(env->mstatus, MSTATUS_TSR)) {
(gdb) n
85          if (env->priv_ver >= PRIV_VERSION_1_10_0 &&
(gdb) n
90          target_ulong mstatus = env->mstatus;
(gdb) n
91          target_ulong prev_priv = get_field(mstatus, MSTATUS_SPP); # 获取SPP, 即之前的特权级, 这里为0(U)
(gdb) n
92          mstatus = set_field(mstatus, MSTATUS_SIE, get_field(mstatus, MSTATUS_SPIE));
(gdb) n
96          mstatus = set_field(mstatus, MSTATUS_SPIE, 0);  # 清除 SPIE
(gdb) n
97          mstatus = set_field(mstatus, MSTATUS_SPP, PRV_U); # 将 SPP 设置为 U 模式, 为下一次中断做准备.
98          riscv_cpu_set_mode(env, prev_priv); # 修改当前特权级, 从 1 -> 0 (S -> U)
(gdb) n
99          env->mstatus = mstatus;     
(gdb) n
101         return retpc;
(gdb) p env->priv
$15 = 0
(gdb) p env->sepc
$16 = 8388872
(gdb) p env->pc
$17 = 18446744072637910850
(gdb) n
102     }
(gdb) n
0x00007f28c466d122 in code_gen_buffer ()
```

这里成功完成了 sret 的调试执行, 分析过程在注释中. 

---

## 2. 在执行ecall和sret这类汇编指令的时候，qemu进行了很关键的一步——指令翻译（TCG Translation），了解一下这个功能，思考一下另一个双重gdb调试的实验是否也涉及到了一些相关的内容。(询问了LLM)

### TCG (Tiny Code Generator) 指令翻译机制

QEMU 是一个动态二进制翻译器（Dynamic Binary Translator）。它并不像解释器那样逐条解释执行目标指令（RISC-V 指令），而是将目标指令块（Translation Block, TB）翻译成宿主机（Host，这里是 x86_64）的机器码，然后直接在宿主机 CPU 上运行这些翻译后的代码。

**ecall 和 sret 的翻译过程：**

1.  **翻译阶段 (Translation Phase)**:
    *   当 QEMU 第一次遇到 `ecall` 或 `sret` 指令时，TCG 前端（Frontend）会调用相应的翻译函数。
    *   对于 `ecall`，`trans_privileged.inc.c` 中的代码会调用 `generate_exception(ctx, RISCV_EXCP_U_ECALL)`。这会生成一段 TCG 中间代码，这段代码的作用是调用 C 辅助函数 `helper_raise_exception`。
    *   对于 `sret`，翻译代码会生成调用 `helper_sret` 的 TCG 操作。

2.  **执行阶段 (Execution Phase)**:
    *   生成的 TCG 中间代码被 TCG 后端（Backend）编译成 x86_64 汇编指令，存放在 `code_gen_buffer` 中。
    *   当 CPU 执行到这段代码时，实际上是在执行宿主机的指令，这些指令会调用我们在调试中看到的 C 函数（如 `riscv_cpu_do_interrupt` 或 `helper_sret`）。
    *   这就是为什么我们在 `bt`（调用栈）中看到了 `code_gen_buffer` —— 我们是从翻译后的代码缓冲区跳转到 C 辅助函数的。

### 与 Lab2 地址翻译实验的联系

Lab2 的双重 GDB 调试实验（调试页表查询过程）**同样深度涉及了 TCG 机制**，但侧重点不同：

1.  **SoftMMU (软件内存管理单元)**:
    *   在 Lab2 中，我们观察的是访存指令（如 `ld`, `sd`）。
    *   TCG 在翻译这些访存指令时，不会直接生成简单的 x86 内存访问指令，而是会插入一段**SoftMMU 查找代码**。
    *   这段代码首先快速查找 **TLB (Translation Lookaside Buffer)**。
    *   如果 **TLB 命中**（Fast Path），则直接访问物理内存（在 QEMU 中是模拟的 RAM 数组）。
    *   如果 **TLB 未命中**（Slow Path），则会跳转到 C 辅助函数 `tlb_fill`（在 RISC-V 中对应 `riscv_cpu_tlb_fill`）。

2.  **对比**:
    *   **Lab5 (系统调用)**: 我们观察的是**控制流指令** (`ecall`, `sret`) 的 Slow Path（总是调用 C 辅助函数处理异常）。
    *   **Lab2 (地址翻译)**: 我们观察的是**数据流指令** (`load`, `store`) 的 Slow Path（TLB Miss 时的页表遍历）。

## 3 & 4. 有趣的细节 (~~问题~~)
由于终端开的太多, 有时候总是忘记先给终端2 continue 后再在终端3里si, 导致需要从头开始, 但是在执行到 sret 时犯了这个错误, 但是给终端2打上断点然后continue后居然触发了终端, 终端3 显示
```bash
(gdb) si
warning: Invalid remote reply: f2f1f6f5faf9fefd73140014f324001073291014f3293014732a201422e826e24ae64eea52ee0a85eff0bff09264326913f4041001e400127310041473900410

Program received signal SIGINT, Interrupt.
__trapret () at kern/trap/trapentry.S:133
133         sret
1: x/7i $pc
=> 0xffffffffc0200f42 <__trapret+86>:   sret
   0xffffffffc0200f46 <forkrets>:       mv      sp,a0
   0xffffffffc0200f48 <forkrets+2>:     j       0xffffffffc0200eec <__trapret>
   0xffffffffc0200f4a <kernel_execve_ret>:      addi    a1,a1,-288
   0xffffffffc0200f4e <kernel_execve_ret+4>:    ld      s1,280(a0)
   0xffffffffc0200f52 <kernel_execve_ret+8>:    sd      s1,280(a1)
   0xffffffffc0200f56 <kernel_execve_ret+12>:   ld      s1,272(a0)
```

LLM 给出的解释是
1. `warning: Invalid remote reply: ...`

    - 这是 终端 3 (ucore GDB) 发出的警告。
    - 当你执行 si 时，ucore GDB 向 QEMU 发送了单步执行请求。
    - 但是，因为你忘记先让终端 2 (QEMU GDB) continue，QEMU 实际上是被挂起的（Paused）。
    - ucore GDB 等待 QEMU 的回复超时了，或者收到了因为 QEMU 被强制暂停而产生的垃圾数据/不完整数据包。
    - 那串 f2f1f6... 其实是 GDB 试图解析 QEMU 发回的（可能是错误的或乱序的）寄存器数据包。
2. `Program received signal SIGINT, Interrupt.`

    - 因为通信异常，ucore GDB 认为目标机（QEMU）出了问题或者被中断了，所以它主动停止了等待，并报告收到了 SIGINT（通常是你按 Ctrl+C 或者超时自动触发）。**(这里确认是超时自动触发了)**

3. 为什么终端 2 后来又触发了断点？

    - 当你后来在终端 2 执行 continue 时，QEMU 恢复了运行。
    - 虽然终端 3 报错了，但它发送给 QEMU 的 si 请求（单步执行）可能在 QEMU 恢复运行的瞬间被处理了，或者你再次在终端 3 输入了命令。
    - 一旦 QEMU 开始执行那条 sret 指令，它就会立即命中你在终端 2 设置的 helper_sret 断点。





