# 实验三：中断处理机制

## 练习1：完善中断处理
定时器中断处理流程:

- ### 中断触发阶段

1. 硬件中断：RISC-V定时器产生中断信号

2. 异常处理：CPU跳转到stvec寄存器指定的异常向量地址

3. 上下文保存：自动保存寄存器状态到陷阱帧

- ### 中断分发阶段

1. 陷阱分发：trap()函数调用trap_dispatch()

2. 类型判断：根据tf->cause判断中断类型

3. 路由处理：将定时器中断路由到interrupt_handler()

- ### 定时器处理阶段

1. 设置下次中断：调用clock_set_next_event()重置定时器

2. 计数器更新：全局ticks变量自动递增

3. 条件检查：检查ticks是否为100的倍数

4. 打印处理：满足条件时调用print_ticks()输出信息

5. 关机判断：打印10次后调用sbi_shutdown()关机

- ### 中断返回阶段

1. 上下文恢复：从陷阱帧恢复寄存器状态

2. 特权级返回：使用sret指令返回到中断前状态

3. 程序继续：恢复正常程序执行


练习一实现过程即为按照上述内容补全中断处理流程中对定时器处理的相关代码，主要体现在trap.c文件的interrupt_handler函数中，需要注意在clock.h中定义的ticks作为全局变量的使用。

## 扩展练习 Challenge1：描述与理解中断流程

- ### 问题：描述ucore中处理中断异常的流程（从异常的产生开始）

    完整流程如下：
1. 异常产生：
若为中断，硬件异步触发；若为异常，执行某条指令时同步触发。

2. 硬件自动处理：\
保存PC到sepc；\
设置scause（中断→最高位 1，异常→0，低 31 位为原因码）；\
设置stval（异常时存附加信息，如非法地址）；\
切特权级到 S 模式，保存SIE到SPIE，再禁中断（SIE=0）；\
PC 跳stvec指向的__alltraps。

3. 汇编层保存上下文：\
执行SAVE_ALL宏，把通用寄存器和关键 CSR 存入栈，形成TrapFrame；\
move a0, sp传TrapFrame地址，调用 trap()。

4. C 语言层分发处理：\
trap()→ trap_dispatch()，按scause分发给interrupt_handler（中断）或exception_handler（异常）；\
执行具体处理（如时钟中断计数、异常打印地址）。

5. 恢复上下文并返回：\
执行RESTORE_ALL宏，恢复寄存器和 sstatus/sepc；\
sret指令：PC=sepc，恢复SIE，切回原特权级，原程序继续执行。

- ### 问题：mov a0，sp的目的是什么？

    mov a0，sp 的目的是将栈顶的 TrapFrame 结构体地址传给 trap() 函数。\
    SAVE_ALL执行完后，栈顶就是TrapFrame的起始地址，而RISC-V环境下约定C函数第一个参数通过a0寄存器传递，因此 mov a0，sp 就是把 TrapFrame 的地址传给 trap() 函数的参数 struct trapframe *tf。

- ### 问题：SAVE_ALL中寄存器保存在栈中的位置是什么确定的？

    由 TrapFrame 结构体的成员顺序确定。\
    TrapFrame是连续的内存块，成员顺序固定。其中pushregs结构体的成员顺序和 RISC-V 通用寄存器的顺序一一对应（如pushregs.ra对应x1，pushregs.sp对应x2）。SAVE_ALL宏中，每个寄存器的存储位置（如1*REGBYTES(sp)）必须和TrapFrame的成员偏移一致，否则恢复时会读错寄存器值。

- ### 问题：对于任何中断，__alltraps 中都需要保存所有寄存器吗？

    需要保存所有寄存器。\
    中断是异步事件，无法预知当前程序正在使用哪些寄存器。为了中断后能完全恢复，必须保存所有寄存器。