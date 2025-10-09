## 练习1
### 指令 la sp, bootstacktop 完成了什么操作，目的是什么？
#### 作用：
la（Load Address）是一个伪指令（pseudo-instruction），会被汇编器转换为实际的 RISC-V 指令序列（auipc + addi）。
它的作用是 计算 bootstacktop 的地址 并加载到目标寄存器。

sp（Stack Pointer）是 RISC-V 的栈指针寄存器（Register x2），用于管理函数调用栈。

这条指令将 bootstacktop 的地址存入 sp，即 设置当前栈指针的位置。

bootstacktop是数据段中定义的一个符号，表示内核栈的 顶部地址（栈通常是向下增长的，所以 bootstacktop 是栈的最高地址）。

#### 目的：

1. 初始化内核栈，在跳转到 C 语言编写的 kern_init 之前，设置好栈空间。

2. 将 sp 初始化为栈的 最高地址（bootstacktop），后续的 push 操作会递减 sp。

3. 为函数调用做准备,tail kern_init 是一个尾调用（直接跳转，不保存返回地址），但 kern_init 本身可能调用其他函数，依赖栈的正确初始化。


这条指令的核心目的是 在内核启动的最早期，为 C 代码的运行准备好栈空间，确保后续的函数调用、局部变量存储等操作能正常执行。这是从汇编跳转到 C 代码的关键准备工作之一。
### tail kern_init 完成了什么操作，目的是什么?
tail kern_init 是 RISC-V 汇编中的 尾调用（Tail Call）指令，其作用相当于：jal zero, kern_init  # 跳转到 kern_init，同时丢弃返回地址（不保存 ra）

或更直观的伪代码：
kern_init();  // 直接跳转，不返回


行为是：

跳转到 kern_init：  
将程序计数器（PC）设置为 kern_init 的地址，开始执行 C 语言编写的内核初始化代码。


不保存返回地址：  
普通调用（如 call 或 jal）会保存返回地址到 ra 寄存器，但 tail 不保存，因为 kern_init 被声明为 noreturn（永不返回），无需保留返回信息。


优化栈空间：  尾调用不会增加调用栈深度，避免不必要的栈帧分配。

与 C 代码的 noreturn 对应：kern_init 在 C 中声明为 __attribute__((noreturn))，汇编层面用 tail 保持一致性。

由于之前已通过 la sp, bootstacktop 设置好栈指针，C 代码可正常使用栈（如局部变量、函数调用）。kern_init 最终会进入无限循环（while (1);），因此无需返回地址。

目的是：tail kern_init 跳转到内核主初始化函数，不保留返回地址，优化控制流和栈空间的使用。

#### kern_init函数：
函数声明：

    int kern_init(void) __attribute__((noreturn));

__attribute__((noreturn))  告诉编译器这个函数 不会返回（即无限循环或终止系统），避免编译器生成不必要的返回代码。

函数定义：

    int kern_init(void) 

定义内核初始化函数 kern_init，返回类型为 int（虽然实际不会返回）。

    memset(edata, 0, end - edata); 
这是这个函数最主要的部分，这一行代码的作用是 清零内核的 .bss 段（Block Started by Symbol），确保所有未初始化的全局变量和静态变量初始值为 0。这是 C/C++ 程序的运行时要求，因为标准规定未显式初始化的全局变量必须初始化为 0。

edata 和 end  这两个符号通常由 链接脚本（Linker Script） 定义，表示内核内存布局的关键地址：

edata：表示 .data 段的结束地址（即已初始化的全局变量的末尾）。同时也是 .bss 段的起始地址（未初始化的全局变量的开始）。  

end：表示 整个内核映像的结束地址（即 .bss 段的末尾）。  

内存布局示例：


    +-------------------+  
    | .text (代码段)     |  
    +-------------------+  
    | .data (已初始化数据) |  
    +-------------------+  <- edata (BSS 段从这里开始)  
    | .bss (未初始化数据)  |  
    +-------------------+  <- end (BSS 段到这里结束)  


memset 是标准 C 库函数，用于填充内存：

    void *memset(void *ptr, int value, size_t num);

• ptr：要填充的内存起始地址（这里是 edata）。  

• value：要填充的值（这里是 0）。  

• num：要填充的字节数（这里是 end - edata）。  

计算 end - edata：
• end - edata 就是 .bss 段的大小，即需要清零的字节数。  

这行代码实际上是清零 .bss 段在 C 语言中：已初始化的全局变量（如 int x = 1;）存储在 .data 段。未初始化的全局变量（如 int y;）存储在 .bss 段。C 标准规定：未显式初始化的全局变量和静态变量必须初始化为 0。

但编译器不会在二进制文件中存储 .bss 段的 0 值（因为全是 0，存储会浪费空间），而是 仅在运行时动态清零。因此，操作系统内核在启动时必须手动清零 .bss 段，否则这些变量可能包含随机垃圾值。


打印启动消息

    const char *message = "(THU.CST) os is loading ...\n";
    cprintf("%s\n\n", message);


无限循环

    while (1)
        ;
进入一个 无限循环，表示内核初始化完成后进入空闲状态（或等待中断）。  

  这是 noreturn 的体现，因为函数永远不会返回。

代码整体逻辑

1. 清零 .bss 段：确保未初始化的全局变量初始为 0。  
2. 打印启动消息：通知用户内核正在加载。  
3. 挂起系统：进入无限循环，等待后续的中断或调度。



## 练习2
*为了熟悉使用 QEMU 和 GDB 的调试方法，请使用 GDB 跟踪 QEMU 模拟的 RISC-V 从加电开始，直到执行内核第一条指令（跳转到 0x80200000）的整个过程。*
### RISC-V 硬件加电后最初执行的几条指令位于什么地址？它们主要完成了哪些功能？
最初的几条指令位于0x1000-0x1010


    (gdb) x/10i 0x1000
    0x1000:      auipc   t0,0x0
    0x1004:      addi    a1,t0,32
    0x1008:      csrr    a0,mhartid
    0x100c:      ld      t0,24(t0)
    0x1010:      jr      t0

是 ​RISC-V 平台的早期启动代码（Bootloader 的第一阶段）​，它的作用是将 CPU 控制权移交到内核（跳转到 0x80000000）.
跳转到0x80000000.

    0x80000000:	csrr	a6,mhartid
    0x80000004:	bgtz	a6,0x80000108
    0x80000008:	auipc	t0,0x0
    0x8000000c:	addi	t0,t0,1032
    0x80000010:	auipc	t1,0x0
    0x80000014:	addi	t1,t1,-16
    0x80000018:	sd	t1,0(t0)
    0x8000001c:	auipc	t0,0x0
    0x80000020:	addi	t0,t0,1020
    0x80000024:	ld	t0,0(t0)
    0x80000028:	auipc	t1,0x0
    0x8000002c:	addi	t1,t1,1016
    0x80000030:	ld	t1,0(t1)
    0x80000034:	auipc	t2,0x0
    0x80000038:	addi	t2,t2,988
    0x8000003c:	ld	t2,0(t2)
    0x80000040:	sub	t3,t1,t0
    0x80000044:	add	t3,t3,t2
    0x80000046:	beq	t0,t2,0x8000014e
这段代码实现了某些数据结构的初始化，之后跳转到0x8000014e

    0x8000014e:	auipc	t0,0x0
    0x80000152:	addi	t0,t0,698
    0x80000156:	li	t1,1
    0x80000158:	sd	t1,0(t0)
    0x8000015c:	fence	rw,rw
    0x80000160:	li	ra,0
    0x80000162:	jal	ra,0x80000550
 这段代码设置初始化标志，接着跳转到0x80000550
    
    0x80000550:	fence.i
    0x80000554:	li	sp,0
    0x80000556:	li	gp,0
    0x80000558:	li	tp,0
    0x8000055a:	li	t0,0
    0x8000055c:	li	t1,0
    0x8000055e:	li	t2,0
    0x80000560:	li	s0,0
    0x80000562:	li	s1,0
    0x80000564:	li	a3,0
    0x80000566:	li	a4,0
    0x80000568:	li	a5,0
    0x8000056a:	li	a6,0
    0x8000056c:	li	a7,0
    0x8000056e:	li	s2,0 
    0x80000570:	li	s3,0
    0x80000572:	li	s4,0
    0x80000574:	li	s5,0
    0x80000576:	li	s6,0
    0x80000578:	li	s7,0
    0x8000057a:	li	s8,0
    0x8000057c:	li	s9,0
    0x8000057e:	li	s10,0
    0x80000580:	li	s11,0
    0x80000582:	li	t3,0
    0x80000584:	li	t4,0
    0x80000586:	li	t5,0
    0x80000588:	li	t6,0
    0x8000058a:	csrwi	mscratch,0
    0x8000058e:	ret

 这段程序实现了将寄存器初始化，接着跳转到0x80000166-0x80000238进行内存初始化。
 之后通过打断点的方式，监控到程序实现在0x80200000之前的各种初始化工作
 在0x80200000设置断点观察内核入口  
在内核入口地址设置断点并运行到kern_entry：
```
(gdb) b *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
(gdb) c
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7           la sp, bootstacktop
```
&emsp;&emsp;&emsp;检查寄存器状态(节选了有代表性的寄存器)：
```
(gdb) info registers
ra             0x80000a02       0x80000a02    # 返回地址（来自OpenSBI）
sp             0x8001bd80       0x8001bd80    # 当前栈指针
pc             0x80200000       0x80200000    # 程序计数器（内核入口）
a0             0x0              0             # 参数寄存器
```
&emsp;&emsp;&emsp;查看栈内存内容：
```
(gdb) x/10x $sp
0x8001bd80:     0x8001be00      0x00000000      0x8001be00      0x00000000
0x8001bd90:     0x46444341      0x55534d49      0x00000000      0x00000000
0x8001bda0:     0x00000000      0x00000000
```
&emsp;&emsp;&emsp;单步执行到kern_init，并再次查看此时的栈内存内容：
```
(gdb) si
0x0000000080200004 in kern_entry () at kern/init/entry.S:7
7           la sp, bootstacktop
(gdb) si
9           tail kern_init
(gdb) si
kern_init () at kern/init/init.c:8
8           memset(edata, 0, end - edata);
(gdb) x/10x $sp
0x80203000 <SBI_CONSOLE_PUTCHAR>:       0x00000001      0x00000000      0x00000000      0x00000000
0x80203010:     0x00000000      0x00000000      0x00000000      0x00000000
0x80203020:     0x00000000      0x00000000
```
对比栈顶地址和栈内容变化，初始使用OpenSBI设置的临时栈，执行la sp, bootstacktop后切换到内核自己的栈且初始为零。此外发现，栈顶值为1的原因是0x80203000是全局变量SBI_CONSOLE_PUTCHAR的地址，由此可以推断内核的全局变量和栈空间在内存中是相邻的，栈从高地址向低地址增长，所以栈顶正好是数据段的末尾。

### 启动流程总结
基于调试观察，完整的启动流程为：
1. 硬件复位阶段（0x1000）：

- CPU从复位地址开始执行
- 完成最基础的处理器状态初始化
- 跳转到OpenSBI固件

2. OpenSBI初始化阶段（0x80000000）：

- 进行全面的硬件初始化
- 设置内存管理单元（MMU）
- 加载内核到 0x80200000 地址
- 准备运行环境并传递控制权

3. 内核启动阶段（0x80200000）：

- 执行 kern_entry 设置内核栈
- 跳转到 kern_init C函数
- 初始化.bss段，调用格式化输出
- 进入主循环
