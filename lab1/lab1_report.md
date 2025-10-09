# 实验1报告

## 练习1

### la sp, bootstacktop
- 操作：将内核栈顶地址加载到sp寄存器
- 目的：设置内核栈指针，为C函数调用准备运行环境

### tail kern_init  
- 操作：尾调用跳转到kern_init函数
- 目的：从内核入口点代码跳转到内核初始化代码，开始执行内核主逻辑

## 练习2

### 调试过程
1. 使用make debug和make gdb启动调试环境
2. 在0x1000观察复位代码  
GDB连接成功后，程序停在复位地址，此时查看复位地址处的指令(对其功能解释以注释形式给出)：
```
(gdb) x/5i $pc
=> 0x1000:      auipc   t0,0x0          ;计算PC相对地址
   0x1004:      addi    a1,t0,32        ;设置参数寄存器
   0x1008:      csrr    a0,mhartid      ;读取硬件线程ID
   0x100c:      ld      t0,24(t0)       ;加载跳转目标地址
   0x1010:      jr      t0              ;跳转到OpenSBI主程序
```  
&emsp;&emsp;&emsp;通过si指令单步执行复位代码：
```
(gdb) si
0x0000000000001004 in ?? ()
(gdb) si
0x0000000000001008 in ?? ()
(gdb) si
0x000000000000100c in ?? ()
(gdb) si
0x0000000000001010 in ?? ()
(gdb) si
0x0000000080000000 in ?? ()
```
&emsp;&emsp;&emsp;观察到在执行完0x1010后跳转到0x80000000(OpenSBI)

3. 在0x80200000设置断点观察内核入口  
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

