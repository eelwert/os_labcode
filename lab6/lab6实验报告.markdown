### 练习1:理解调度器框架的实现
>调度类结构体 sched_class 的分析：请详细解释 sched_class 结构体中每个函数指针的作用和调用时机，分析为什么需要将这些函数定义为函数指针，而不是直接实现函数。

#### 1. 函数指针详解

`sched_class` 结构体定义在 `kern/schedule/sched.h` 中，它是 ucore 操作系统实现调度器框架的核心接口。

| 成员变量/函数指针 | 作用 (Role) | 调用时机 (Timing) |
| :--- | :--- | :--- |
| `const char *name` | **调度类名称**。用于标识当前使用的调度算法（如 "RR_scheduler" 或 "stride_scheduler"）。 | 在 `sched_init` 初始化时或调试打印时使用。 |
| `void (*init)(struct run_queue *rq)` | **初始化运行队列**。负责初始化 `run_queue` 结构体中的相关成员（如链表头、斜堆根节点、进程计数等）。 | 在内核初始化阶段，由 `sched_init()` 函数调用（仅调用一次）。 |
| `void (*enqueue)(struct run_queue *rq, struct proc_struct *proc)` | **入队**。将一个处于 `RUNNABLE` 状态的进程加入到运行队列（链表或斜堆）中。 | 1. `wakeup_proc()`：当进程从等待状态被唤醒时。<br>2. `schedule()`：当当前进程时间片用完但仍处于 `RUNNABLE` 状态，需要重新放回队列等待下次调度时。 |
| `void (*dequeue)(struct run_queue *rq, struct proc_struct *proc)` | **出队**。将一个进程从运行队列中移除。 | 在 `schedule()` 函数中，当 `pick_next()` 选出了下一个要运行的进程后，会调用此函数将其从就绪队列中移除，准备投入运行。 |
| `struct proc_struct *(*pick_next)(struct run_queue *rq)` | **选择下一个进程**。根据特定的调度算法策略，从运行队列中选择最适合运行的进程。 | 在 `schedule()` 函数中调用，用于决定 CPU 控制权的下一个所有者。 |
| `void (*proc_tick)(struct run_queue *rq, struct proc_struct *proc)` | **时钟中断处理**。处理时钟 tick 事件，通常用于更新进程的时间片剩余值，并判断是否需要调度。 | 在时钟中断处理函数 `interrupt_handler` (位于 `kern/trap/trap.c`) 中，每当发生 `IRQ_S_TIMER` 中断时被调用。 |

#### 2. 为什么要使用函数指针？

将这些功能定义为函数指针而不是直接实现函数，主要基于以下设计思想：

1.  **接口与实现分离（Decoupling）**：
    *   `sched_class` 定义了一套通用的调度接口标准。内核的其余部分（如 `schedule` 函数、中断处理、进程创建等）只需要调用这些标准接口，而不需要知道具体是哪种算法在工作。
    *   这使得调度框架（Mechanism）保持稳定，而调度策略（Policy）可以灵活变化。

2.  **多态性（Polymorphism）**：
    *   这是在 C 语言中模拟面向对象编程中“接口”或“虚函数”的一种常见技术。
    *   通过替换全局变量 `sched_class` 指向的结构体实例（例如从 `default_sched_class` 切换到 `stride_sched_class`），可以在运行时或编译时轻松切换整个操作系统的调度行为，而无需修改调用这些函数的代码。

3.  **可扩展性（Extensibility）**：
    *   如果需要实现一个新的调度算法（例如完全公平调度 CFS），只需要定义一个新的 `sched_class` 实例并实现对应的函数即可，无需侵入式地修改内核核心代码。这借鉴了 Linux 内核的调度类设计。

>运行队列结构体 run_queue 的分析：比较lab5和lab6中 run_queue 结构体的差异，解释为什么lab6的 run_queue 需要支持两种数据结构（链表和斜堆）？。
#### 1. Lab5 与 Lab6 的差异

*   **Lab5**：
    *   **没有 `run_queue` 结构体**。
    *   调度器在 `schedule()` 函数中直接遍历全局的进程链表 `proc_list`。
    *   它查找状态为 `PROC_RUNNABLE` 的进程，效率较低，因为 `proc_list` 包含了所有状态（包括睡眠、僵尸等）的进程。

*   **Lab6**：
    *   **引入了 `run_queue` 结构体**。
    *   `run_queue` 专门管理**就绪态（Runnable）**的进程，实现了就绪进程集合与全局进程集合的分离。
    *   结构体定义如下（`kern/schedule/sched.h`）：
        ```c
        struct run_queue {
            list_entry_t run_list;          // 用于 Round Robin 调度的链表
            unsigned int proc_num;          // 就绪进程数量
            int max_time_slice;             // 最大时间片
            skew_heap_entry_t *lab6_run_pool; // 用于 Stride 调度的斜堆（优先队列）
        };
        ```

#### 2. 为什么需要支持两种数据结构？

Lab6 的 `run_queue` 同时包含链表和斜堆，是为了支持不同的调度算法，体现了调度框架的通用性：

1.  **链表 (`run_list`)**：
    *   **服务于 Round Robin (RR) 算法**。
    *   RR 算法本质上是基于 FIFO（先进先出）队列的。使用双向链表可以以 $O(1)$ 的时间复杂度实现进程的入队（尾部插入）和出队（头部删除），非常适合轮转调度。

2.  **斜堆 (`lab6_run_pool`)**：
    *   **服务于 Stride Scheduling 算法**。
    *   Stride 算法需要每次选择 `stride`（步进值）最小的进程运行。
    *   如果使用链表，查找最小值的复杂度是 $O(N)$。
    *   使用 **斜堆（Skew Heap**作为优先队列，可以将插入和删除最小元素的时间复杂度降低到 $O(\log N)$，从而在大规模进程调度时保持高效。

通过在 `run_queue` 中同时保留这两种结构，ucore 可以在运行时根据配置（`sched_class`）灵活地选择使用链表还是斜堆来管理就绪进程，而无需重新编译内核结构。
>调度器框架函数分析：分析 sched_init()、wakeup_proc() 和 schedule() 函数在lab6中的实现变化，理解这些函数如何与具体的调度算法解耦。

#### 1. `sched_init()`
*   **功能**：初始化调度器。
*   **实现变化**：
    *   初始化全局定时器链表 `timer_list`。
    *   设置全局变量 `sched_class` 指向具体的调度算法实现（如 `default_sched_class` 或 `stride_sched_class`）。
    *   调用 `sched_class->init(rq)` 来初始化运行队列。
*   **解耦**：通过调用 `sched_class->init`，`sched_init` 不需要知道运行队列的具体结构（是链表还是斜堆），这由具体的调度类决定。

#### 2. `wakeup_proc()`
*   **功能**：唤醒进程，将其状态设置为 `PROC_RUNNABLE`。
*   **实现变化**：
    *   在设置进程状态后，调用 `sched_class_enqueue(proc)`。
    *   `sched_class_enqueue` 内部调用 `sched_class->enqueue(rq, proc)`。
*   **解耦**：唤醒函数不需要知道如何将进程加入就绪队列（是插到链表尾部还是插入斜堆），这由调度算法的 `enqueue` 方法实现。

#### 3. `schedule()`
*   **功能**：执行进程调度，选择下一个运行的进程。
*   **实现变化**：
    *   如果当前进程仍处于 `RUNNABLE` 状态（例如时间片用完），调用 `sched_class_enqueue(current)` 将其放回队列。
    *   调用 `sched_class_pick_next(rq)` 选择下一个进程。
    *   调用 `sched_class_dequeue(next)` 将选中的进程从队列中移除。
    *   调用 `proc_run(next)` 进行上下文切换。
*   **解耦**：`schedule` 函数只负责调度流程的控制（保存上下文、切换进程），而“谁是下一个”的决策逻辑完全封装在 `sched_class` 的 `pick_next` 方法中。

>调度类的初始化流程：描述从内核启动到调度器初始化完成的完整流程，分析 default_sched_class 如何与调度器框架关联。

#### 1. 初始化流程
1.  **内核入口**：`kern/init/init.c` 中的 `kern_init()` 函数开始执行。
2.  **内存管理初始化**：先调用 `pmm_init()` 和 `vmm_init()` 初始化物理和虚拟内存。
3.  **调度器初始化**：调用 `sched_init()`（位于 `kern/schedule/sched.c`）。
    *   `sched_init()` 中将全局指针 `sched_class` 指向 `&default_sched_class`（或者在实验中修改为 `&stride_sched_class`）。
    *   调用 `sched_class->init(rq)` 初始化运行队列。
4.  **进程系统初始化**：调用 `proc_init()` 创建 `idleproc` 和 `initproc`。
5.  **中断初始化**：调用 `clock_init()` 和 `intr_enable()` 开启时钟中断，调度器开始工作。

#### 2. 关联方式
`default_sched_class` 是一个全局的 `struct sched_class` 实例（定义在 `kern/schedule/default_sched.c`）。在 `sched_init()` 函数中，通过赋值语句 `sched_class = &default_sched_class`，将调度器框架的接口指针指向了这个具体的实现。此后，所有通过 `sched_class` 调用的函数（如 `enqueue`, `pick_next`）都会指向 `default_sched_class` 中定义的 `RR_enqueue`, `RR_pick_next` 等函数。

>进程调度流程：绘制一个完整的进程调度流程图，包括：时钟中断触发、proc_tick 被调用、schedule() 函数执行、调度类各个函数的调用顺序。并解释 need_resched 标志位在调度过程中的作用

#### 1. 调度流程

1.  **触发中断**：硬件产生时钟中断，CPU 跳转到 `trap()` -> `trap_dispatch()` -> `interrupt_handler()`。
2.  **时钟处理**：
    *   `interrupt_handler` 识别 `IRQ_S_TIMER`。
    *   调用 `sched_class_proc_tick(current)`。
    *   `sched_class_proc_tick` 调用 `sched_class->proc_tick(rq, current)` (例如 `RR_proc_tick`)。
    *   **策略判断**：`RR_proc_tick` 递减当前进程的 `time_slice`。如果减为 0，设置 `current->need_resched = 1`。
3.  **中断返回前检查**：
    *   `trap()` 函数即将返回时，检查 `current->need_resched`。
    *   如果为 1，调用 `schedule()`。
4.  **执行调度 (`schedule()`)**：
    *   **保存当前**：如果 `current` 还是 `RUNNABLE`，调用 `sched_class->enqueue(rq, current)` 放回队列。
    *   **选择下一个**：调用 `next = sched_class->pick_next(rq)`。
    *   **移除下一个**：调用 `sched_class->dequeue(rq, next)`。
    *   **切换**：调用 `proc_run(next)` 切换上下文。

#### 2. `need_resched` 的作用
`need_resched` 是一个标志位，用于实现**抢占式调度**。
*   当时钟中断发生时，调度器策略（如 RR）检查当前进程的时间片是否用完。
*   如果用完，调度器**不会立即**进行上下文切换（因为还在中断处理上下文中），而是仅仅将 `need_resched` 置为 1。
*   真正的切换发生在中断处理程序即将返回用户态（或内核态）的时刻，检查到该标志位后才调用 `schedule()`。这保证了中断处理的原子性和调度的安全性。

>调度算法的切换机制：分析如果要添加一个新的调度算法（如stride），需要修改哪些代码？并解释为什么当前的设计使得切换调度算法变得容易。

#### 1. 修改的代码
要添加 Stride 算法，主要涉及：
1.  **实现算法**：创建 `kern/schedule/default_sched_stride.c`，定义一个 `struct sched_class stride_sched_class`，并实现 `init`, `enqueue`, `dequeue`, `pick_next`, `proc_tick` 等函数。
2.  **注册算法**：在 `kern/schedule/sched.c` 的 `sched_init()` 函数中，将 `sched_class` 的指向改为 `&stride_sched_class`。
    ```c
    void sched_init(void) {
        // ...
        sched_class = &stride_sched_class; // 
        // ...
    }
    ```

#### 2. 为什么容易？
当前设计使用了**策略模式**（Strategy Pattern）。`sched_class` 封装了所有与调度策略相关的行为接口。内核的其他部分（进程管理、中断处理）只依赖于这些抽象接口，而不依赖于具体实现。因此，切换算法只需要改变 `sched_class` 指针的指向，而不需要修改 `schedule()`、`wakeup_proc()` 或中断处理程序的逻辑。

### 练习2: 实现 Round Robin 调度算法
>比较一个在lab5和lab6都有, 但是实现不同的函数, 说说为什么要做这个改动, 不做这个改动会出什么问题
提示: 如kern/schedule/sched.c里的函数。你也可以找个其他地方做了改动的函数。

#### 比较 `schedule()` 函数

*   **Lab5 实现**：
    ```c
    // 伪代码
    list_entry_t *le = last;
    do {
        le = list_next(le);
        next = le2proc(le, ...);
        if (next->state == PROC_RUNNABLE) break;
    } while (le != last);
    ```
    Lab5 直接遍历全局进程链表 `proc_list` 来寻找 `RUNNABLE` 的进程。

*   **Lab6 实现**：
    ```c
    if (current->state == PROC_RUNNABLE) sched_class_enqueue(current);
    next = sched_class_pick_next();
    if (next != NULL) sched_class_dequeue(next);
    ```
    Lab6 委托 `sched_class` 来选择进程。

*   **原因与后果**：
    *   **改动原因**：Lab5 的实现将调度策略（简单的轮询）硬编码在 `schedule` 函数中。Lab6 为了支持多种调度算法（如 RR, Stride），必须将策略剥离出去。
    *   **不改动的问题**：如果不改动，`schedule` 函数将无法利用 `run_queue` 结构，也无法支持优先级或斜堆等复杂数据结构。每次调度都需要 $O(N)$ 遍历所有进程（包括大量睡眠进程），效率极低且无法扩展。

>描述你实现每个函数的具体思路和方法，解释为什么选择特定的链表操作方法。对每个实现函数的关键代码进行解释说明，并解释如何处理边界情况.

1.  **`RR_init`**：
    *   使用 `list_init` 初始化 `run_list`。
    *   将 `proc_num` 置 0。
2.  **`RR_enqueue`**：
    *   **思路**：RR 算法要求新就绪的进程排在队尾。
    *   **方法**：使用 `list_add_before` 将进程插入到 `run_list` 的头部之前（即链表尾部）。
    *   **关键代码**：
        ```c
        list_add_before(&(rq->run_list), &(proc->run_link));
        if (proc->time_slice == 0 || proc->time_slice > rq->max_time_slice)
            proc->time_slice = rq->max_time_slice; // 重置时间片
        ```
    *   **边界处理**：检查 `proc->time_slice`，如果是 0（刚耗尽）或异常大，则重置为 `max_time_slice`。
3.  **`RR_dequeue`**：
    *   **思路**：将进程从队列中移除。
    *   **方法**：`list_del_init`。
4.  **`RR_pick_next`**：
    *   **思路**：RR 算法选择队头进程。
    *   **方法**：`list_next(&(rq->run_list))` 获取第一个节点。
    *   **边界处理**：如果链表为空（`le == &(rq->run_list)`），返回 `NULL`。
5.  **`RR_proc_tick`**：
    *   **思路**：每次时钟中断减少时间片。
    *   **关键代码**：
        ```c
        if (proc->time_slice > 0) proc->time_slice--;
        if (proc->time_slice == 0) proc->need_resched = 1;
        ```

>展示 make grade 的输出结果，并描述在 QEMU 中观察到的调度现象。

*   **Make Grade 输出**：
    ```
    priority:                (3.0s)
      -check result:                             OK
      -check output:                             OK
    Total Score: 50/50
    ```
*   **QEMU 现象**：
    在运行 `priority` 测试时，可以看到 5 个子进程几乎交替输出信息（例如 `main: fork ok,now need to wait pids.` 后，各个子进程轮流执行）。如果打印调度日志，会发现进程 ID 是轮流切换的（如 `pid 2 -> pid 3 -> pid 4 ...`），体现了 Round Robin 的公平轮转特性。

>分析 Round Robin 调度算法的优缺点，讨论如何调整时间片大小来优化系统性能，并解释为什么需要在 RR_proc_tick 中设置 need_resched 标志。

*   **优点**：实现简单，公平性好（每个进程都有机会运行），响应时间较短（适合交互式系统）。
*   **缺点**：平均周转时间较长；不区分任务紧急程度（无优先级）；时间片设置不当会影响性能。

*   **`need_resched`**：在 `RR_proc_tick` 中设置该标志是为了通知内核“当前进程时间片已用完，请在适当时候（中断返回时）让出 CPU”。这是实现抢占的关键，否则进程会一直运行直到主动阻塞或退出。

>拓展思考：如果要实现优先级 RR 调度，你的代码需要如何修改？当前的实现是否支持多核调度？如果不支持，需要如何改进？

*   **优先级 RR**：
    *   可以维护多个 `run_list` 队列，每个队列对应一个优先级。
    *   `pick_next` 时优先扫描高优先级队列。
    *   或者在 `proc_struct` 中增加 `priority` 字段，调整时间片大小（高优先级时间片更长）。
*   **多核调度**：
    *   当前实现**不支持**多核。全局只有一个 `run_queue` 和 `sched_class`。
    *   **改进**：
        1.  为每个 CPU 核心定义一个独立的 `run_queue`。
        2.  在 `schedule` 时只访问当前 CPU 的 `run_queue`（需要加锁或关中断保护）。
        3.  实现**负载均衡**（Load Balancing）机制，允许进程在不同核心的队列间迁移。

### 扩展练习 Challenge 1: 实现 Stride Scheduling 调度算法
>简要说明如何设计实现”多级反馈队列调度算法“，给出概要设计，鼓励给出详细设计

**多级反馈队列 (MLFQ) 设计概要**：
1.  **队列结构**：定义 $N$ 个队列 $Q_0, Q_1, \dots, Q_{N-1}$，优先级依次降低。
2.  **时间片**：高优先级队列时间片短，低优先级时间片长。
3.  **入队规则**：新进程进入最高优先级队列 $Q_0$。
4.  **调度策略**：
    *   总是运行优先级最高的非空队列中的进程。
    *   同一队列内使用 RR 调度。
5.  **降级规则**：如果进程在当前队列的时间片内用完了 CPU 配额（说明是 CPU 密集型），则移入下一级队列。
6.  **升级规则（防饥饿）**：如果进程在低优先级队列等待过久，提升其优先级（Priority Boost）。

>简要证明/说明（不必特别严谨，但应当能够”说服你自己“），为什么Stride算法中，经过足够多的时间片之后，每个进程分配到的时间片数目和优先级成正比。

**证明思路**：
1.  **定义**：设进程 $P_i$ 的优先级为 $Priority_i$，步进值为 $Stride_i = \frac{BigStride}{Priority_i}$。
2.  **调度规则**：每次选择 $Pass$ 值最小的进程运行，运行后 $Pass_i += Stride_i$。
3.  **长期运行**：
    *   假设经过很长一段时间 $T$，进程 $P_i$ 运行了 $N_i$ 次。
    *   为了保持 $Pass$ 值“齐头并进”（因为调度器总是选最小的追赶），所有进程的最终 $Pass$ 值应该大致相等。
    *   即 $N_A \times Stride_A \approx N_B \times Stride_B$。
4.  **推导**：
    *   $\frac{N_A}{N_B} \approx \frac{Stride_B}{Stride_A}$
    *   代入 $Stride = \frac{C}{Priority}$：
    *   $\frac{N_A}{N_B} \approx \frac{C / Priority_B}{C / Priority_A} = \frac{Priority_A}{Priority_B}$
5.  **结论**：运行次数（即分配到的时间片数目） $N$ 与优先级 $Priority$ 成正比。

