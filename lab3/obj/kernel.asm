
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	44460613          	addi	a2,a2,1092 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	6bb010ef          	jal	ffffffffc0201f26 <memset>
    dtb_init();
ffffffffc0200070:	40a000ef          	jal	ffffffffc020047a <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3f8000ef          	jal	ffffffffc020046c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	ec050513          	addi	a0,a0,-320 # ffffffffc0201f38 <etext>
ffffffffc0200080:	08e000ef          	jal	ffffffffc020010e <cputs>

    print_kerninfo();
ffffffffc0200084:	0e8000ef          	jal	ffffffffc020016c <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	77a000ef          	jal	ffffffffc0200802 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	6e4010ef          	jal	ffffffffc0201770 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	772000ef          	jal	ffffffffc0200802 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	396000ef          	jal	ffffffffc020042a <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	75e000ef          	jal	ffffffffc02007f6 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3c8000ef          	jal	ffffffffc020046e <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	117010ef          	jal	ffffffffc02019e2 <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc02000de:	f42e                	sd	a1,40(sp)
ffffffffc02000e0:	f832                	sd	a2,48(sp)
ffffffffc02000e2:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	862a                	mv	a2,a0
ffffffffc02000e6:	004c                	addi	a1,sp,4
ffffffffc02000e8:	00000517          	auipc	a0,0x0
ffffffffc02000ec:	fb650513          	addi	a0,a0,-74 # ffffffffc020009e <cputch>
ffffffffc02000f0:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f2:	ec06                	sd	ra,24(sp)
ffffffffc02000f4:	e0ba                	sd	a4,64(sp)
ffffffffc02000f6:	e4be                	sd	a5,72(sp)
ffffffffc02000f8:	e8c2                	sd	a6,80(sp)
ffffffffc02000fa:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fc:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000fe:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200100:	0e3010ef          	jal	ffffffffc02019e2 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200104:	60e2                	ld	ra,24(sp)
ffffffffc0200106:	4512                	lw	a0,4(sp)
ffffffffc0200108:	6125                	addi	sp,sp,96
ffffffffc020010a:	8082                	ret

ffffffffc020010c <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010c:	a68d                	j	ffffffffc020046e <cons_putc>

ffffffffc020010e <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020010e:	1101                	addi	sp,sp,-32
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	87aa                	mv	a5,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200116:	00054503          	lbu	a0,0(a0)
ffffffffc020011a:	c905                	beqz	a0,ffffffffc020014a <cputs+0x3c>
ffffffffc020011c:	e426                	sd	s1,8(sp)
ffffffffc020011e:	00178493          	addi	s1,a5,1
ffffffffc0200122:	8426                	mv	s0,s1
    cons_putc(c);
ffffffffc0200124:	34a000ef          	jal	ffffffffc020046e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200128:	00044503          	lbu	a0,0(s0)
ffffffffc020012c:	87a2                	mv	a5,s0
ffffffffc020012e:	0405                	addi	s0,s0,1
ffffffffc0200130:	f975                	bnez	a0,ffffffffc0200124 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200132:	9f85                	subw	a5,a5,s1
    cons_putc(c);
ffffffffc0200134:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc0200136:	0027841b          	addiw	s0,a5,2
ffffffffc020013a:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc020013c:	332000ef          	jal	ffffffffc020046e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	6105                	addi	sp,sp,32
ffffffffc0200148:	8082                	ret
    cons_putc(c);
ffffffffc020014a:	4529                	li	a0,10
ffffffffc020014c:	322000ef          	jal	ffffffffc020046e <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200150:	4405                	li	s0,1
}
ffffffffc0200152:	60e2                	ld	ra,24(sp)
ffffffffc0200154:	8522                	mv	a0,s0
ffffffffc0200156:	6442                	ld	s0,16(sp)
ffffffffc0200158:	6105                	addi	sp,sp,32
ffffffffc020015a:	8082                	ret

ffffffffc020015c <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020015c:	1141                	addi	sp,sp,-16
ffffffffc020015e:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200160:	316000ef          	jal	ffffffffc0200476 <cons_getc>
ffffffffc0200164:	dd75                	beqz	a0,ffffffffc0200160 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200166:	60a2                	ld	ra,8(sp)
ffffffffc0200168:	0141                	addi	sp,sp,16
ffffffffc020016a:	8082                	ret

ffffffffc020016c <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020016c:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc020016e:	00002517          	auipc	a0,0x2
ffffffffc0200172:	dea50513          	addi	a0,a0,-534 # ffffffffc0201f58 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200176:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200178:	f61ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc020017c:	00000597          	auipc	a1,0x0
ffffffffc0200180:	ed858593          	addi	a1,a1,-296 # ffffffffc0200054 <kern_init>
ffffffffc0200184:	00002517          	auipc	a0,0x2
ffffffffc0200188:	df450513          	addi	a0,a0,-524 # ffffffffc0201f78 <etext+0x40>
ffffffffc020018c:	f4dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200190:	00002597          	auipc	a1,0x2
ffffffffc0200194:	da858593          	addi	a1,a1,-600 # ffffffffc0201f38 <etext>
ffffffffc0200198:	00002517          	auipc	a0,0x2
ffffffffc020019c:	e0050513          	addi	a0,a0,-512 # ffffffffc0201f98 <etext+0x60>
ffffffffc02001a0:	f39ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001a4:	00006597          	auipc	a1,0x6
ffffffffc02001a8:	e8458593          	addi	a1,a1,-380 # ffffffffc0206028 <free_area>
ffffffffc02001ac:	00002517          	auipc	a0,0x2
ffffffffc02001b0:	e0c50513          	addi	a0,a0,-500 # ffffffffc0201fb8 <etext+0x80>
ffffffffc02001b4:	f25ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001b8:	00006597          	auipc	a1,0x6
ffffffffc02001bc:	2e858593          	addi	a1,a1,744 # ffffffffc02064a0 <end>
ffffffffc02001c0:	00002517          	auipc	a0,0x2
ffffffffc02001c4:	e1850513          	addi	a0,a0,-488 # ffffffffc0201fd8 <etext+0xa0>
ffffffffc02001c8:	f11ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001cc:	00006797          	auipc	a5,0x6
ffffffffc02001d0:	6d378793          	addi	a5,a5,1747 # ffffffffc020689f <end+0x3ff>
ffffffffc02001d4:	00000717          	auipc	a4,0x0
ffffffffc02001d8:	e8070713          	addi	a4,a4,-384 # ffffffffc0200054 <kern_init>
ffffffffc02001dc:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001de:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001e2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001e4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e8:	95be                	add	a1,a1,a5
ffffffffc02001ea:	85a9                	srai	a1,a1,0xa
ffffffffc02001ec:	00002517          	auipc	a0,0x2
ffffffffc02001f0:	e0c50513          	addi	a0,a0,-500 # ffffffffc0201ff8 <etext+0xc0>
}
ffffffffc02001f4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001f6:	b5cd                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001f8 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f8:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001fa:	00002617          	auipc	a2,0x2
ffffffffc02001fe:	e2e60613          	addi	a2,a2,-466 # ffffffffc0202028 <etext+0xf0>
ffffffffc0200202:	04d00593          	li	a1,77
ffffffffc0200206:	00002517          	auipc	a0,0x2
ffffffffc020020a:	e3a50513          	addi	a0,a0,-454 # ffffffffc0202040 <etext+0x108>
void print_stackframe(void) {
ffffffffc020020e:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200210:	1bc000ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0200214 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200214:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200216:	00002617          	auipc	a2,0x2
ffffffffc020021a:	e4260613          	addi	a2,a2,-446 # ffffffffc0202058 <etext+0x120>
ffffffffc020021e:	00002597          	auipc	a1,0x2
ffffffffc0200222:	e5a58593          	addi	a1,a1,-422 # ffffffffc0202078 <etext+0x140>
ffffffffc0200226:	00002517          	auipc	a0,0x2
ffffffffc020022a:	e5a50513          	addi	a0,a0,-422 # ffffffffc0202080 <etext+0x148>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200230:	ea9ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200234:	00002617          	auipc	a2,0x2
ffffffffc0200238:	e5c60613          	addi	a2,a2,-420 # ffffffffc0202090 <etext+0x158>
ffffffffc020023c:	00002597          	auipc	a1,0x2
ffffffffc0200240:	e7c58593          	addi	a1,a1,-388 # ffffffffc02020b8 <etext+0x180>
ffffffffc0200244:	00002517          	auipc	a0,0x2
ffffffffc0200248:	e3c50513          	addi	a0,a0,-452 # ffffffffc0202080 <etext+0x148>
ffffffffc020024c:	e8dff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200250:	00002617          	auipc	a2,0x2
ffffffffc0200254:	e7860613          	addi	a2,a2,-392 # ffffffffc02020c8 <etext+0x190>
ffffffffc0200258:	00002597          	auipc	a1,0x2
ffffffffc020025c:	e9058593          	addi	a1,a1,-368 # ffffffffc02020e8 <etext+0x1b0>
ffffffffc0200260:	00002517          	auipc	a0,0x2
ffffffffc0200264:	e2050513          	addi	a0,a0,-480 # ffffffffc0202080 <etext+0x148>
ffffffffc0200268:	e71ff0ef          	jal	ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc020026c:	60a2                	ld	ra,8(sp)
ffffffffc020026e:	4501                	li	a0,0
ffffffffc0200270:	0141                	addi	sp,sp,16
ffffffffc0200272:	8082                	ret

ffffffffc0200274 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200274:	1141                	addi	sp,sp,-16
ffffffffc0200276:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200278:	ef5ff0ef          	jal	ffffffffc020016c <print_kerninfo>
    return 0;
}
ffffffffc020027c:	60a2                	ld	ra,8(sp)
ffffffffc020027e:	4501                	li	a0,0
ffffffffc0200280:	0141                	addi	sp,sp,16
ffffffffc0200282:	8082                	ret

ffffffffc0200284 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200284:	1141                	addi	sp,sp,-16
ffffffffc0200286:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200288:	f71ff0ef          	jal	ffffffffc02001f8 <print_stackframe>
    return 0;
}
ffffffffc020028c:	60a2                	ld	ra,8(sp)
ffffffffc020028e:	4501                	li	a0,0
ffffffffc0200290:	0141                	addi	sp,sp,16
ffffffffc0200292:	8082                	ret

ffffffffc0200294 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200294:	7115                	addi	sp,sp,-224
ffffffffc0200296:	f15a                	sd	s6,160(sp)
ffffffffc0200298:	8b2a                	mv	s6,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020029a:	00002517          	auipc	a0,0x2
ffffffffc020029e:	e5e50513          	addi	a0,a0,-418 # ffffffffc02020f8 <etext+0x1c0>
kmonitor(struct trapframe *tf) {
ffffffffc02002a2:	ed86                	sd	ra,216(sp)
ffffffffc02002a4:	e9a2                	sd	s0,208(sp)
ffffffffc02002a6:	e5a6                	sd	s1,200(sp)
ffffffffc02002a8:	e1ca                	sd	s2,192(sp)
ffffffffc02002aa:	fd4e                	sd	s3,184(sp)
ffffffffc02002ac:	f952                	sd	s4,176(sp)
ffffffffc02002ae:	f556                	sd	s5,168(sp)
ffffffffc02002b0:	ed5e                	sd	s7,152(sp)
ffffffffc02002b2:	e962                	sd	s8,144(sp)
ffffffffc02002b4:	e566                	sd	s9,136(sp)
ffffffffc02002b6:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b8:	e21ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002bc:	00002517          	auipc	a0,0x2
ffffffffc02002c0:	e6450513          	addi	a0,a0,-412 # ffffffffc0202120 <etext+0x1e8>
ffffffffc02002c4:	e15ff0ef          	jal	ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002c8:	000b0563          	beqz	s6,ffffffffc02002d2 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002cc:	855a                	mv	a0,s6
ffffffffc02002ce:	714000ef          	jal	ffffffffc02009e2 <print_trapframe>
ffffffffc02002d2:	00003c17          	auipc	s8,0x3
ffffffffc02002d6:	a56c0c13          	addi	s8,s8,-1450 # ffffffffc0202d28 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002da:	00002917          	auipc	s2,0x2
ffffffffc02002de:	e6e90913          	addi	s2,s2,-402 # ffffffffc0202148 <etext+0x210>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002e2:	00002497          	auipc	s1,0x2
ffffffffc02002e6:	e6e48493          	addi	s1,s1,-402 # ffffffffc0202150 <etext+0x218>
        if (argc == MAXARGS - 1) {
ffffffffc02002ea:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002ec:	00002a97          	auipc	s5,0x2
ffffffffc02002f0:	e6ca8a93          	addi	s5,s5,-404 # ffffffffc0202158 <etext+0x220>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f4:	4a0d                	li	s4,3
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02002f6:	00002b97          	auipc	s7,0x2
ffffffffc02002fa:	e82b8b93          	addi	s7,s7,-382 # ffffffffc0202178 <etext+0x240>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002fe:	854a                	mv	a0,s2
ffffffffc0200300:	25d010ef          	jal	ffffffffc0201d5c <readline>
ffffffffc0200304:	842a                	mv	s0,a0
ffffffffc0200306:	dd65                	beqz	a0,ffffffffc02002fe <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200308:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020030c:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	e59d                	bnez	a1,ffffffffc020033c <kmonitor+0xa8>
    if (argc == 0) {
ffffffffc0200310:	fe0c87e3          	beqz	s9,ffffffffc02002fe <kmonitor+0x6a>
ffffffffc0200314:	00003d17          	auipc	s10,0x3
ffffffffc0200318:	a14d0d13          	addi	s10,s10,-1516 # ffffffffc0202d28 <commands>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031e:	6582                	ld	a1,0(sp)
ffffffffc0200320:	000d3503          	ld	a0,0(s10)
ffffffffc0200324:	38d010ef          	jal	ffffffffc0201eb0 <strcmp>
ffffffffc0200328:	c53d                	beqz	a0,ffffffffc0200396 <kmonitor+0x102>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	2405                	addiw	s0,s0,1
ffffffffc020032c:	0d61                	addi	s10,s10,24
ffffffffc020032e:	ff4418e3          	bne	s0,s4,ffffffffc020031e <kmonitor+0x8a>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200332:	6582                	ld	a1,0(sp)
ffffffffc0200334:	855e                	mv	a0,s7
ffffffffc0200336:	da3ff0ef          	jal	ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc020033a:	b7d1                	j	ffffffffc02002fe <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033c:	8526                	mv	a0,s1
ffffffffc020033e:	3d3010ef          	jal	ffffffffc0201f10 <strchr>
ffffffffc0200342:	c901                	beqz	a0,ffffffffc0200352 <kmonitor+0xbe>
ffffffffc0200344:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200348:	00040023          	sb	zero,0(s0)
ffffffffc020034c:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020034e:	d1e9                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc0200350:	b7f5                	j	ffffffffc020033c <kmonitor+0xa8>
        if (*buf == '\0') {
ffffffffc0200352:	00044783          	lbu	a5,0(s0)
ffffffffc0200356:	dfcd                	beqz	a5,ffffffffc0200310 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200358:	033c8a63          	beq	s9,s3,ffffffffc020038c <kmonitor+0xf8>
        argv[argc ++] = buf;
ffffffffc020035c:	003c9793          	slli	a5,s9,0x3
ffffffffc0200360:	08078793          	addi	a5,a5,128
ffffffffc0200364:	978a                	add	a5,a5,sp
ffffffffc0200366:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020036a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020036e:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200370:	e591                	bnez	a1,ffffffffc020037c <kmonitor+0xe8>
ffffffffc0200372:	bf79                	j	ffffffffc0200310 <kmonitor+0x7c>
ffffffffc0200374:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200378:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020037a:	d9d9                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc020037c:	8526                	mv	a0,s1
ffffffffc020037e:	393010ef          	jal	ffffffffc0201f10 <strchr>
ffffffffc0200382:	d96d                	beqz	a0,ffffffffc0200374 <kmonitor+0xe0>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200384:	00044583          	lbu	a1,0(s0)
ffffffffc0200388:	d5c1                	beqz	a1,ffffffffc0200310 <kmonitor+0x7c>
ffffffffc020038a:	bf4d                	j	ffffffffc020033c <kmonitor+0xa8>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020038c:	45c1                	li	a1,16
ffffffffc020038e:	8556                	mv	a0,s5
ffffffffc0200390:	d49ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc0200394:	b7e1                	j	ffffffffc020035c <kmonitor+0xc8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200396:	00141793          	slli	a5,s0,0x1
ffffffffc020039a:	97a2                	add	a5,a5,s0
ffffffffc020039c:	078e                	slli	a5,a5,0x3
ffffffffc020039e:	97e2                	add	a5,a5,s8
ffffffffc02003a0:	6b9c                	ld	a5,16(a5)
ffffffffc02003a2:	865a                	mv	a2,s6
ffffffffc02003a4:	002c                	addi	a1,sp,8
ffffffffc02003a6:	fffc851b          	addiw	a0,s9,-1
ffffffffc02003aa:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc02003ac:	f40559e3          	bgez	a0,ffffffffc02002fe <kmonitor+0x6a>
}
ffffffffc02003b0:	60ee                	ld	ra,216(sp)
ffffffffc02003b2:	644e                	ld	s0,208(sp)
ffffffffc02003b4:	64ae                	ld	s1,200(sp)
ffffffffc02003b6:	690e                	ld	s2,192(sp)
ffffffffc02003b8:	79ea                	ld	s3,184(sp)
ffffffffc02003ba:	7a4a                	ld	s4,176(sp)
ffffffffc02003bc:	7aaa                	ld	s5,168(sp)
ffffffffc02003be:	7b0a                	ld	s6,160(sp)
ffffffffc02003c0:	6bea                	ld	s7,152(sp)
ffffffffc02003c2:	6c4a                	ld	s8,144(sp)
ffffffffc02003c4:	6caa                	ld	s9,136(sp)
ffffffffc02003c6:	6d0a                	ld	s10,128(sp)
ffffffffc02003c8:	612d                	addi	sp,sp,224
ffffffffc02003ca:	8082                	ret

ffffffffc02003cc <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003cc:	00006317          	auipc	t1,0x6
ffffffffc02003d0:	07430313          	addi	t1,t1,116 # ffffffffc0206440 <is_panic>
ffffffffc02003d4:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003d8:	715d                	addi	sp,sp,-80
ffffffffc02003da:	ec06                	sd	ra,24(sp)
ffffffffc02003dc:	f436                	sd	a3,40(sp)
ffffffffc02003de:	f83a                	sd	a4,48(sp)
ffffffffc02003e0:	fc3e                	sd	a5,56(sp)
ffffffffc02003e2:	e0c2                	sd	a6,64(sp)
ffffffffc02003e4:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003e6:	020e1c63          	bnez	t3,ffffffffc020041e <__panic+0x52>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003ea:	4785                	li	a5,1
ffffffffc02003ec:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f0:	e822                	sd	s0,16(sp)
ffffffffc02003f2:	103c                	addi	a5,sp,40
ffffffffc02003f4:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003f6:	862e                	mv	a2,a1
ffffffffc02003f8:	85aa                	mv	a1,a0
ffffffffc02003fa:	00002517          	auipc	a0,0x2
ffffffffc02003fe:	d9650513          	addi	a0,a0,-618 # ffffffffc0202190 <etext+0x258>
    va_start(ap, fmt);
ffffffffc0200402:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200404:	cd5ff0ef          	jal	ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200408:	65a2                	ld	a1,8(sp)
ffffffffc020040a:	8522                	mv	a0,s0
ffffffffc020040c:	cadff0ef          	jal	ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200410:	00002517          	auipc	a0,0x2
ffffffffc0200414:	da050513          	addi	a0,a0,-608 # ffffffffc02021b0 <etext+0x278>
ffffffffc0200418:	cc1ff0ef          	jal	ffffffffc02000d8 <cprintf>
ffffffffc020041c:	6442                	ld	s0,16(sp)
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020041e:	3de000ef          	jal	ffffffffc02007fc <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200422:	4501                	li	a0,0
ffffffffc0200424:	e71ff0ef          	jal	ffffffffc0200294 <kmonitor>
    while (1) {
ffffffffc0200428:	bfed                	j	ffffffffc0200422 <__panic+0x56>

ffffffffc020042a <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042a:	1141                	addi	sp,sp,-16
ffffffffc020042c:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020042e:	02000793          	li	a5,32
ffffffffc0200432:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200436:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	67e1                	lui	a5,0x18
ffffffffc020043c:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200440:	953e                	add	a0,a0,a5
ffffffffc0200442:	1e9010ef          	jal	ffffffffc0201e2a <sbi_set_timer>
}
ffffffffc0200446:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200448:	00006797          	auipc	a5,0x6
ffffffffc020044c:	0007b023          	sd	zero,0(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200450:	00002517          	auipc	a0,0x2
ffffffffc0200454:	d6850513          	addi	a0,a0,-664 # ffffffffc02021b8 <etext+0x280>
}
ffffffffc0200458:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045a:	b9bd                	j	ffffffffc02000d8 <cprintf>

ffffffffc020045c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020045c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200460:	67e1                	lui	a5,0x18
ffffffffc0200462:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200466:	953e                	add	a0,a0,a5
ffffffffc0200468:	1c30106f          	j	ffffffffc0201e2a <sbi_set_timer>

ffffffffc020046c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020046c:	8082                	ret

ffffffffc020046e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020046e:	0ff57513          	zext.b	a0,a0
ffffffffc0200472:	19f0106f          	j	ffffffffc0201e10 <sbi_console_putchar>

ffffffffc0200476 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200476:	1cf0106f          	j	ffffffffc0201e44 <sbi_console_getchar>

ffffffffc020047a <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047a:	711d                	addi	sp,sp,-96
    cprintf("DTB Init\n");
ffffffffc020047c:	00002517          	auipc	a0,0x2
ffffffffc0200480:	d5c50513          	addi	a0,a0,-676 # ffffffffc02021d8 <etext+0x2a0>
void dtb_init(void) {
ffffffffc0200484:	ec86                	sd	ra,88(sp)
ffffffffc0200486:	e8a2                	sd	s0,80(sp)
    cprintf("DTB Init\n");
ffffffffc0200488:	c51ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020048c:	00006597          	auipc	a1,0x6
ffffffffc0200490:	b745b583          	ld	a1,-1164(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200494:	00002517          	auipc	a0,0x2
ffffffffc0200498:	d5450513          	addi	a0,a0,-684 # ffffffffc02021e8 <etext+0x2b0>
ffffffffc020049c:	c3dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004a0:	00006417          	auipc	s0,0x6
ffffffffc02004a4:	b6840413          	addi	s0,s0,-1176 # ffffffffc0206008 <boot_dtb>
ffffffffc02004a8:	600c                	ld	a1,0(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	d4e50513          	addi	a0,a0,-690 # ffffffffc02021f8 <etext+0x2c0>
ffffffffc02004b2:	c27ff0ef          	jal	ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004b6:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	d5850513          	addi	a0,a0,-680 # ffffffffc0202210 <etext+0x2d8>
    if (boot_dtb == 0) {
ffffffffc02004c0:	12070d63          	beqz	a4,ffffffffc02005fa <dtb_init+0x180>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004c4:	57f5                	li	a5,-3
ffffffffc02004c6:	07fa                	slli	a5,a5,0x1e
ffffffffc02004c8:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004ca:	431c                	lw	a5,0(a4)
ffffffffc02004cc:	f456                	sd	s5,40(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ce:	00ff0637          	lui	a2,0xff0
ffffffffc02004d2:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004d6:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004da:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004de:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02004e6:	6ac1                	lui	s5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e8:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ea:	8ec9                	or	a3,a3,a0
ffffffffc02004ec:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004f0:	1afd                	addi	s5,s5,-1 # ffff <kern_entry-0xffffffffc01f0001>
ffffffffc02004f2:	0157f7b3          	and	a5,a5,s5
ffffffffc02004f6:	8dd5                	or	a1,a1,a3
ffffffffc02004f8:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02004fa:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004fe:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc0200500:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200504:	0ef59f63          	bne	a1,a5,ffffffffc0200602 <dtb_init+0x188>
ffffffffc0200508:	471c                	lw	a5,8(a4)
ffffffffc020050a:	4754                	lw	a3,12(a4)
ffffffffc020050c:	fc4e                	sd	s3,56(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020050e:	0087d99b          	srliw	s3,a5,0x8
ffffffffc0200512:	0086d41b          	srliw	s0,a3,0x8
ffffffffc0200516:	0186951b          	slliw	a0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020051e:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200522:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	0109999b          	slliw	s3,s3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200536:	8c71                	and	s0,s0,a2
ffffffffc0200538:	00c9f9b3          	and	s3,s3,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053c:	01156533          	or	a0,a0,a7
ffffffffc0200540:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200544:	0105e633          	or	a2,a1,a6
ffffffffc0200548:	0087979b          	slliw	a5,a5,0x8
ffffffffc020054c:	8c49                	or	s0,s0,a0
ffffffffc020054e:	0156f6b3          	and	a3,a3,s5
ffffffffc0200552:	00c9e9b3          	or	s3,s3,a2
ffffffffc0200556:	0157f7b3          	and	a5,a5,s5
ffffffffc020055a:	8c55                	or	s0,s0,a3
ffffffffc020055c:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200560:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200562:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200564:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200566:	0209d993          	srli	s3,s3,0x20
ffffffffc020056a:	e4a6                	sd	s1,72(sp)
ffffffffc020056c:	e0ca                	sd	s2,64(sp)
ffffffffc020056e:	ec5e                	sd	s7,24(sp)
ffffffffc0200570:	e862                	sd	s8,16(sp)
ffffffffc0200572:	e466                	sd	s9,8(sp)
ffffffffc0200574:	e06a                	sd	s10,0(sp)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200576:	f852                	sd	s4,48(sp)
    int in_memory_node = 0;
ffffffffc0200578:	4b81                	li	s7,0
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020057e:	00ff0cb7          	lui	s9,0xff0
        switch (token) {
ffffffffc0200582:	4c0d                	li	s8,3
ffffffffc0200584:	4911                	li	s2,4
ffffffffc0200586:	4d05                	li	s10,1
ffffffffc0200588:	4489                	li	s1,2
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020058a:	0009a703          	lw	a4,0(s3)
ffffffffc020058e:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200592:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200596:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020059e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a2:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005a6:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a8:	0196f6b3          	and	a3,a3,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ac:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005b0:	8fd5                	or	a5,a5,a3
ffffffffc02005b2:	00eaf733          	and	a4,s5,a4
ffffffffc02005b6:	8fd9                	or	a5,a5,a4
ffffffffc02005b8:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005ba:	09878263          	beq	a5,s8,ffffffffc020063e <dtb_init+0x1c4>
ffffffffc02005be:	00fc6963          	bltu	s8,a5,ffffffffc02005d0 <dtb_init+0x156>
ffffffffc02005c2:	05a78963          	beq	a5,s10,ffffffffc0200614 <dtb_init+0x19a>
ffffffffc02005c6:	00979763          	bne	a5,s1,ffffffffc02005d4 <dtb_init+0x15a>
ffffffffc02005ca:	4b81                	li	s7,0
ffffffffc02005cc:	89d2                	mv	s3,s4
ffffffffc02005ce:	bf75                	j	ffffffffc020058a <dtb_init+0x110>
ffffffffc02005d0:	ff278ee3          	beq	a5,s2,ffffffffc02005cc <dtb_init+0x152>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005d4:	00002517          	auipc	a0,0x2
ffffffffc02005d8:	d0450513          	addi	a0,a0,-764 # ffffffffc02022d8 <etext+0x3a0>
ffffffffc02005dc:	afdff0ef          	jal	ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005e0:	64a6                	ld	s1,72(sp)
ffffffffc02005e2:	6906                	ld	s2,64(sp)
ffffffffc02005e4:	79e2                	ld	s3,56(sp)
ffffffffc02005e6:	7a42                	ld	s4,48(sp)
ffffffffc02005e8:	7aa2                	ld	s5,40(sp)
ffffffffc02005ea:	6be2                	ld	s7,24(sp)
ffffffffc02005ec:	6c42                	ld	s8,16(sp)
ffffffffc02005ee:	6ca2                	ld	s9,8(sp)
ffffffffc02005f0:	6d02                	ld	s10,0(sp)
ffffffffc02005f2:	00002517          	auipc	a0,0x2
ffffffffc02005f6:	d1e50513          	addi	a0,a0,-738 # ffffffffc0202310 <etext+0x3d8>
}
ffffffffc02005fa:	6446                	ld	s0,80(sp)
ffffffffc02005fc:	60e6                	ld	ra,88(sp)
ffffffffc02005fe:	6125                	addi	sp,sp,96
    cprintf("DTB init completed\n");
ffffffffc0200600:	bce1                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200602:	6446                	ld	s0,80(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200604:	7aa2                	ld	s5,40(sp)
}
ffffffffc0200606:	60e6                	ld	ra,88(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	c2850513          	addi	a0,a0,-984 # ffffffffc0202230 <etext+0x2f8>
}
ffffffffc0200610:	6125                	addi	sp,sp,96
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200612:	b4d9                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200614:	8552                	mv	a0,s4
ffffffffc0200616:	065010ef          	jal	ffffffffc0201e7a <strlen>
ffffffffc020061a:	89aa                	mv	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020061c:	4619                	li	a2,6
ffffffffc020061e:	00002597          	auipc	a1,0x2
ffffffffc0200622:	c3a58593          	addi	a1,a1,-966 # ffffffffc0202258 <etext+0x320>
ffffffffc0200626:	8552                	mv	a0,s4
                int name_len = strlen(name);
ffffffffc0200628:	2981                	sext.w	s3,s3
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020062a:	0bf010ef          	jal	ffffffffc0201ee8 <strncmp>
ffffffffc020062e:	e111                	bnez	a0,ffffffffc0200632 <dtb_init+0x1b8>
                    in_memory_node = 1;
ffffffffc0200630:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200632:	0a11                	addi	s4,s4,4
ffffffffc0200634:	9a4e                	add	s4,s4,s3
ffffffffc0200636:	ffca7a13          	andi	s4,s4,-4
        switch (token) {
ffffffffc020063a:	89d2                	mv	s3,s4
ffffffffc020063c:	b7b9                	j	ffffffffc020058a <dtb_init+0x110>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020063e:	0049a783          	lw	a5,4(s3)
ffffffffc0200642:	f05a                	sd	s6,32(sp)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200644:	0089a683          	lw	a3,8(s3)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200648:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020064c:	01879b1b          	slliw	s6,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200650:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200654:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200658:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020065c:	00cb6b33          	or	s6,s6,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200660:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200664:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200668:	00eb6b33          	or	s6,s6,a4
ffffffffc020066c:	00faf7b3          	and	a5,s5,a5
ffffffffc0200670:	00fb6b33          	or	s6,s6,a5
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200674:	00c98a13          	addi	s4,s3,12
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200678:	2b01                	sext.w	s6,s6
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020067a:	000b9c63          	bnez	s7,ffffffffc0200692 <dtb_init+0x218>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020067e:	1b02                	slli	s6,s6,0x20
ffffffffc0200680:	020b5b13          	srli	s6,s6,0x20
ffffffffc0200684:	0a0d                	addi	s4,s4,3
ffffffffc0200686:	9a5a                	add	s4,s4,s6
ffffffffc0200688:	ffca7a13          	andi	s4,s4,-4
                break;
ffffffffc020068c:	7b02                	ld	s6,32(sp)
        switch (token) {
ffffffffc020068e:	89d2                	mv	s3,s4
ffffffffc0200690:	bded                	j	ffffffffc020058a <dtb_init+0x110>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200692:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200696:	0186979b          	slliw	a5,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020069a:	0186d71b          	srliw	a4,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020069e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006a2:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006aa:	8fd9                	or	a5,a5,a4
ffffffffc02006ac:	0086969b          	slliw	a3,a3,0x8
ffffffffc02006b0:	8d5d                	or	a0,a0,a5
ffffffffc02006b2:	00daf6b3          	and	a3,s5,a3
ffffffffc02006b6:	8d55                	or	a0,a0,a3
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006b8:	1502                	slli	a0,a0,0x20
ffffffffc02006ba:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006bc:	00002597          	auipc	a1,0x2
ffffffffc02006c0:	ba458593          	addi	a1,a1,-1116 # ffffffffc0202260 <etext+0x328>
ffffffffc02006c4:	9522                	add	a0,a0,s0
ffffffffc02006c6:	7ea010ef          	jal	ffffffffc0201eb0 <strcmp>
ffffffffc02006ca:	f955                	bnez	a0,ffffffffc020067e <dtb_init+0x204>
ffffffffc02006cc:	47bd                	li	a5,15
ffffffffc02006ce:	fb67f8e3          	bgeu	a5,s6,ffffffffc020067e <dtb_init+0x204>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006d2:	00c9b783          	ld	a5,12(s3)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006d6:	0149b703          	ld	a4,20(s3)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	b8e50513          	addi	a0,a0,-1138 # ffffffffc0202268 <etext+0x330>
           fdt32_to_cpu(x >> 32);
ffffffffc02006e2:	4207d693          	srai	a3,a5,0x20
ffffffffc02006e6:	42075813          	srai	a6,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ea:	0187d39b          	srliw	t2,a5,0x18
ffffffffc02006ee:	0186d29b          	srliw	t0,a3,0x18
ffffffffc02006f2:	01875f9b          	srliw	t6,a4,0x18
ffffffffc02006f6:	01885f1b          	srliw	t5,a6,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006fa:	0087d49b          	srliw	s1,a5,0x8
ffffffffc02006fe:	0087541b          	srliw	s0,a4,0x8
ffffffffc0200702:	01879e9b          	slliw	t4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200706:	0107d59b          	srliw	a1,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070a:	01869e1b          	slliw	t3,a3,0x18
ffffffffc020070e:	0187131b          	slliw	t1,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200712:	0107561b          	srliw	a2,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200716:	0188189b          	slliw	a7,a6,0x18
ffffffffc020071a:	83e1                	srli	a5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020071c:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200720:	8361                	srli	a4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0108581b          	srliw	a6,a6,0x10
ffffffffc0200726:	005e6e33          	or	t3,t3,t0
ffffffffc020072a:	01e8e8b3          	or	a7,a7,t5
ffffffffc020072e:	0088181b          	slliw	a6,a6,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0104949b          	slliw	s1,s1,0x10
ffffffffc0200736:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073a:	0085959b          	slliw	a1,a1,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073e:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200742:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200746:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074a:	01977733          	and	a4,a4,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074e:	00daf6b3          	and	a3,s5,a3
ffffffffc0200752:	007eeeb3          	or	t4,t4,t2
ffffffffc0200756:	01f36333          	or	t1,t1,t6
ffffffffc020075a:	01c7e7b3          	or	a5,a5,t3
ffffffffc020075e:	00caf633          	and	a2,s5,a2
ffffffffc0200762:	01176733          	or	a4,a4,a7
ffffffffc0200766:	00baf5b3          	and	a1,s5,a1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020076a:	0194f4b3          	and	s1,s1,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020076e:	010afab3          	and	s5,s5,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200772:	01947433          	and	s0,s0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200776:	01d4e4b3          	or	s1,s1,t4
ffffffffc020077a:	00646433          	or	s0,s0,t1
ffffffffc020077e:	8fd5                	or	a5,a5,a3
ffffffffc0200780:	01576733          	or	a4,a4,s5
ffffffffc0200784:	8c51                	or	s0,s0,a2
ffffffffc0200786:	8ccd                	or	s1,s1,a1
           fdt32_to_cpu(x >> 32);
ffffffffc0200788:	1782                	slli	a5,a5,0x20
ffffffffc020078a:	1702                	slli	a4,a4,0x20
ffffffffc020078c:	9381                	srli	a5,a5,0x20
ffffffffc020078e:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200790:	1482                	slli	s1,s1,0x20
ffffffffc0200792:	1402                	slli	s0,s0,0x20
ffffffffc0200794:	8cdd                	or	s1,s1,a5
ffffffffc0200796:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200798:	941ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020079c:	85a6                	mv	a1,s1
ffffffffc020079e:	00002517          	auipc	a0,0x2
ffffffffc02007a2:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202288 <etext+0x350>
ffffffffc02007a6:	933ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007aa:	01445613          	srli	a2,s0,0x14
ffffffffc02007ae:	85a2                	mv	a1,s0
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	af050513          	addi	a0,a0,-1296 # ffffffffc02022a0 <etext+0x368>
ffffffffc02007b8:	921ff0ef          	jal	ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007bc:	009405b3          	add	a1,s0,s1
ffffffffc02007c0:	15fd                	addi	a1,a1,-1
ffffffffc02007c2:	00002517          	auipc	a0,0x2
ffffffffc02007c6:	afe50513          	addi	a0,a0,-1282 # ffffffffc02022c0 <etext+0x388>
ffffffffc02007ca:	90fff0ef          	jal	ffffffffc02000d8 <cprintf>
        memory_base = mem_base;
ffffffffc02007ce:	7b02                	ld	s6,32(sp)
ffffffffc02007d0:	00006797          	auipc	a5,0x6
ffffffffc02007d4:	c897b423          	sd	s1,-888(a5) # ffffffffc0206458 <memory_base>
        memory_size = mem_size;
ffffffffc02007d8:	00006797          	auipc	a5,0x6
ffffffffc02007dc:	c687bc23          	sd	s0,-904(a5) # ffffffffc0206450 <memory_size>
ffffffffc02007e0:	b501                	j	ffffffffc02005e0 <dtb_init+0x166>

ffffffffc02007e2 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02007e2:	00006517          	auipc	a0,0x6
ffffffffc02007e6:	c7653503          	ld	a0,-906(a0) # ffffffffc0206458 <memory_base>
ffffffffc02007ea:	8082                	ret

ffffffffc02007ec <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	c6453503          	ld	a0,-924(a0) # ffffffffc0206450 <memory_size>
ffffffffc02007f4:	8082                	ret

ffffffffc02007f6 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007f6:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02007fa:	8082                	ret

ffffffffc02007fc <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007fc:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200800:	8082                	ret

ffffffffc0200802 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200802:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200806:	00000797          	auipc	a5,0x0
ffffffffc020080a:	31278793          	addi	a5,a5,786 # ffffffffc0200b18 <__alltraps>
ffffffffc020080e:	10579073          	csrw	stvec,a5
}
ffffffffc0200812:	8082                	ret

ffffffffc0200814 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200814:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200816:	1141                	addi	sp,sp,-16
ffffffffc0200818:	e022                	sd	s0,0(sp)
ffffffffc020081a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020081c:	00002517          	auipc	a0,0x2
ffffffffc0200820:	b0c50513          	addi	a0,a0,-1268 # ffffffffc0202328 <etext+0x3f0>
void print_regs(struct pushregs *gpr) {
ffffffffc0200824:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200826:	8b3ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020082a:	640c                	ld	a1,8(s0)
ffffffffc020082c:	00002517          	auipc	a0,0x2
ffffffffc0200830:	b1450513          	addi	a0,a0,-1260 # ffffffffc0202340 <etext+0x408>
ffffffffc0200834:	8a5ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200838:	680c                	ld	a1,16(s0)
ffffffffc020083a:	00002517          	auipc	a0,0x2
ffffffffc020083e:	b1e50513          	addi	a0,a0,-1250 # ffffffffc0202358 <etext+0x420>
ffffffffc0200842:	897ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200846:	6c0c                	ld	a1,24(s0)
ffffffffc0200848:	00002517          	auipc	a0,0x2
ffffffffc020084c:	b2850513          	addi	a0,a0,-1240 # ffffffffc0202370 <etext+0x438>
ffffffffc0200850:	889ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200854:	700c                	ld	a1,32(s0)
ffffffffc0200856:	00002517          	auipc	a0,0x2
ffffffffc020085a:	b3250513          	addi	a0,a0,-1230 # ffffffffc0202388 <etext+0x450>
ffffffffc020085e:	87bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200862:	740c                	ld	a1,40(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	b3c50513          	addi	a0,a0,-1220 # ffffffffc02023a0 <etext+0x468>
ffffffffc020086c:	86dff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200870:	780c                	ld	a1,48(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	b4650513          	addi	a0,a0,-1210 # ffffffffc02023b8 <etext+0x480>
ffffffffc020087a:	85fff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020087e:	7c0c                	ld	a1,56(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	b5050513          	addi	a0,a0,-1200 # ffffffffc02023d0 <etext+0x498>
ffffffffc0200888:	851ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020088c:	602c                	ld	a1,64(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	b5a50513          	addi	a0,a0,-1190 # ffffffffc02023e8 <etext+0x4b0>
ffffffffc0200896:	843ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020089a:	642c                	ld	a1,72(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	b6450513          	addi	a0,a0,-1180 # ffffffffc0202400 <etext+0x4c8>
ffffffffc02008a4:	835ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008a8:	682c                	ld	a1,80(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	b6e50513          	addi	a0,a0,-1170 # ffffffffc0202418 <etext+0x4e0>
ffffffffc02008b2:	827ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008b6:	6c2c                	ld	a1,88(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202430 <etext+0x4f8>
ffffffffc02008c0:	819ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008c4:	702c                	ld	a1,96(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	b8250513          	addi	a0,a0,-1150 # ffffffffc0202448 <etext+0x510>
ffffffffc02008ce:	80bff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008d2:	742c                	ld	a1,104(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202460 <etext+0x528>
ffffffffc02008dc:	ffcff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008e0:	782c                	ld	a1,112(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202478 <etext+0x540>
ffffffffc02008ea:	feeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008ee:	7c2c                	ld	a1,120(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	ba050513          	addi	a0,a0,-1120 # ffffffffc0202490 <etext+0x558>
ffffffffc02008f8:	fe0ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02008fc:	604c                	ld	a1,128(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	baa50513          	addi	a0,a0,-1110 # ffffffffc02024a8 <etext+0x570>
ffffffffc0200906:	fd2ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020090a:	644c                	ld	a1,136(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	bb450513          	addi	a0,a0,-1100 # ffffffffc02024c0 <etext+0x588>
ffffffffc0200914:	fc4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200918:	684c                	ld	a1,144(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	bbe50513          	addi	a0,a0,-1090 # ffffffffc02024d8 <etext+0x5a0>
ffffffffc0200922:	fb6ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200926:	6c4c                	ld	a1,152(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	bc850513          	addi	a0,a0,-1080 # ffffffffc02024f0 <etext+0x5b8>
ffffffffc0200930:	fa8ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200934:	704c                	ld	a1,160(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	bd250513          	addi	a0,a0,-1070 # ffffffffc0202508 <etext+0x5d0>
ffffffffc020093e:	f9aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200942:	744c                	ld	a1,168(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0202520 <etext+0x5e8>
ffffffffc020094c:	f8cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200950:	784c                	ld	a1,176(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	be650513          	addi	a0,a0,-1050 # ffffffffc0202538 <etext+0x600>
ffffffffc020095a:	f7eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020095e:	7c4c                	ld	a1,184(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	bf050513          	addi	a0,a0,-1040 # ffffffffc0202550 <etext+0x618>
ffffffffc0200968:	f70ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020096c:	606c                	ld	a1,192(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	bfa50513          	addi	a0,a0,-1030 # ffffffffc0202568 <etext+0x630>
ffffffffc0200976:	f62ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc020097a:	646c                	ld	a1,200(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	c0450513          	addi	a0,a0,-1020 # ffffffffc0202580 <etext+0x648>
ffffffffc0200984:	f54ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200988:	686c                	ld	a1,208(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	c0e50513          	addi	a0,a0,-1010 # ffffffffc0202598 <etext+0x660>
ffffffffc0200992:	f46ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200996:	6c6c                	ld	a1,216(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	c1850513          	addi	a0,a0,-1000 # ffffffffc02025b0 <etext+0x678>
ffffffffc02009a0:	f38ff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009a4:	706c                	ld	a1,224(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	c2250513          	addi	a0,a0,-990 # ffffffffc02025c8 <etext+0x690>
ffffffffc02009ae:	f2aff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009b2:	746c                	ld	a1,232(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	c2c50513          	addi	a0,a0,-980 # ffffffffc02025e0 <etext+0x6a8>
ffffffffc02009bc:	f1cff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009c0:	786c                	ld	a1,240(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	c3650513          	addi	a0,a0,-970 # ffffffffc02025f8 <etext+0x6c0>
ffffffffc02009ca:	f0eff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ce:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009d0:	6402                	ld	s0,0(sp)
ffffffffc02009d2:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009d4:	00002517          	auipc	a0,0x2
ffffffffc02009d8:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202610 <etext+0x6d8>
}
ffffffffc02009dc:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009de:	efaff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc02009e2 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e2:	1141                	addi	sp,sp,-16
ffffffffc02009e4:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009e6:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009e8:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009ea:	00002517          	auipc	a0,0x2
ffffffffc02009ee:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202628 <etext+0x6f0>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009f2:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009f4:	ee4ff0ef          	jal	ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009f8:	8522                	mv	a0,s0
ffffffffc02009fa:	e1bff0ef          	jal	ffffffffc0200814 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02009fe:	10043583          	ld	a1,256(s0)
ffffffffc0200a02:	00002517          	auipc	a0,0x2
ffffffffc0200a06:	c3e50513          	addi	a0,a0,-962 # ffffffffc0202640 <etext+0x708>
ffffffffc0200a0a:	eceff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a0e:	10843583          	ld	a1,264(s0)
ffffffffc0200a12:	00002517          	auipc	a0,0x2
ffffffffc0200a16:	c4650513          	addi	a0,a0,-954 # ffffffffc0202658 <etext+0x720>
ffffffffc0200a1a:	ebeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a1e:	11043583          	ld	a1,272(s0)
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202670 <etext+0x738>
ffffffffc0200a2a:	eaeff0ef          	jal	ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a2e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a32:	6402                	ld	s0,0(sp)
ffffffffc0200a34:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a36:	00002517          	auipc	a0,0x2
ffffffffc0200a3a:	c5250513          	addi	a0,a0,-942 # ffffffffc0202688 <etext+0x750>
}
ffffffffc0200a3e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a40:	e98ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a44 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
ffffffffc0200a44:	11853783          	ld	a5,280(a0)
ffffffffc0200a48:	472d                	li	a4,11
ffffffffc0200a4a:	0786                	slli	a5,a5,0x1
ffffffffc0200a4c:	8385                	srli	a5,a5,0x1
ffffffffc0200a4e:	08f76363          	bltu	a4,a5,ffffffffc0200ad4 <interrupt_handler+0x90>
ffffffffc0200a52:	00002717          	auipc	a4,0x2
ffffffffc0200a56:	31e70713          	addi	a4,a4,798 # ffffffffc0202d70 <commands+0x48>
ffffffffc0200a5a:	078a                	slli	a5,a5,0x2
ffffffffc0200a5c:	97ba                	add	a5,a5,a4
ffffffffc0200a5e:	439c                	lw	a5,0(a5)
ffffffffc0200a60:	97ba                	add	a5,a5,a4
ffffffffc0200a62:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a64:	00002517          	auipc	a0,0x2
ffffffffc0200a68:	c9c50513          	addi	a0,a0,-868 # ffffffffc0202700 <etext+0x7c8>
ffffffffc0200a6c:	e6cff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a70:	00002517          	auipc	a0,0x2
ffffffffc0200a74:	c7050513          	addi	a0,a0,-912 # ffffffffc02026e0 <etext+0x7a8>
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a7c:	00002517          	auipc	a0,0x2
ffffffffc0200a80:	c2450513          	addi	a0,a0,-988 # ffffffffc02026a0 <etext+0x768>
ffffffffc0200a84:	e54ff06f          	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a88:	00002517          	auipc	a0,0x2
ffffffffc0200a8c:	c9850513          	addi	a0,a0,-872 # ffffffffc0202720 <etext+0x7e8>
ffffffffc0200a90:	e48ff06f          	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a94:	1141                	addi	sp,sp,-16
ffffffffc0200a96:	e406                	sd	ra,8(sp)
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            // (1) 设置下次时钟中断
            clock_set_next_event();
ffffffffc0200a98:	9c5ff0ef          	jal	ffffffffc020045c <clock_set_next_event>
            
            // (2) 计数器加一
            ticks++;
ffffffffc0200a9c:	00006797          	auipc	a5,0x6
ffffffffc0200aa0:	9ac78793          	addi	a5,a5,-1620 # ffffffffc0206448 <ticks>
ffffffffc0200aa4:	6398                	ld	a4,0(a5)
ffffffffc0200aa6:	0705                	addi	a4,a4,1
ffffffffc0200aa8:	e398                	sd	a4,0(a5)
            // (3) 每100次时钟中断打印一次
            if (ticks % TICK_NUM == 0) {
ffffffffc0200aaa:	639c                	ld	a5,0(a5)
ffffffffc0200aac:	06400713          	li	a4,100
ffffffffc0200ab0:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200ab4:	c38d                	beqz	a5,ffffffffc0200ad6 <interrupt_handler+0x92>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200ab6:	60a2                	ld	ra,8(sp)
ffffffffc0200ab8:	0141                	addi	sp,sp,16
ffffffffc0200aba:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200abc:	00002517          	auipc	a0,0x2
ffffffffc0200ac0:	c8c50513          	addi	a0,a0,-884 # ffffffffc0202748 <etext+0x810>
ffffffffc0200ac4:	e14ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ac8:	00002517          	auipc	a0,0x2
ffffffffc0200acc:	bf850513          	addi	a0,a0,-1032 # ffffffffc02026c0 <etext+0x788>
ffffffffc0200ad0:	e08ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200ad4:	b739                	j	ffffffffc02009e2 <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ad6:	06400593          	li	a1,100
ffffffffc0200ada:	00002517          	auipc	a0,0x2
ffffffffc0200ade:	c5e50513          	addi	a0,a0,-930 # ffffffffc0202738 <etext+0x800>
ffffffffc0200ae2:	df6ff0ef          	jal	ffffffffc02000d8 <cprintf>
                num++;
ffffffffc0200ae6:	00006717          	auipc	a4,0x6
ffffffffc0200aea:	97a70713          	addi	a4,a4,-1670 # ffffffffc0206460 <num>
ffffffffc0200aee:	431c                	lw	a5,0(a4)
                if (num == 10) {
ffffffffc0200af0:	46a9                	li	a3,10
                num++;
ffffffffc0200af2:	0017861b          	addiw	a2,a5,1
ffffffffc0200af6:	c310                	sw	a2,0(a4)
                if (num == 10) {
ffffffffc0200af8:	fad61fe3          	bne	a2,a3,ffffffffc0200ab6 <interrupt_handler+0x72>
}
ffffffffc0200afc:	60a2                	ld	ra,8(sp)
ffffffffc0200afe:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200b00:	3600106f          	j	ffffffffc0201e60 <sbi_shutdown>

ffffffffc0200b04 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b04:	11853783          	ld	a5,280(a0)
ffffffffc0200b08:	0007c763          	bltz	a5,ffffffffc0200b16 <trap+0x12>
    switch (tf->cause) {
ffffffffc0200b0c:	472d                	li	a4,11
ffffffffc0200b0e:	00f76363          	bltu	a4,a5,ffffffffc0200b14 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200b12:	8082                	ret
            print_trapframe(tf);
ffffffffc0200b14:	b5f9                	j	ffffffffc02009e2 <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200b16:	b73d                	j	ffffffffc0200a44 <interrupt_handler>

ffffffffc0200b18 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b18:	14011073          	csrw	sscratch,sp
ffffffffc0200b1c:	712d                	addi	sp,sp,-288
ffffffffc0200b1e:	e002                	sd	zero,0(sp)
ffffffffc0200b20:	e406                	sd	ra,8(sp)
ffffffffc0200b22:	ec0e                	sd	gp,24(sp)
ffffffffc0200b24:	f012                	sd	tp,32(sp)
ffffffffc0200b26:	f416                	sd	t0,40(sp)
ffffffffc0200b28:	f81a                	sd	t1,48(sp)
ffffffffc0200b2a:	fc1e                	sd	t2,56(sp)
ffffffffc0200b2c:	e0a2                	sd	s0,64(sp)
ffffffffc0200b2e:	e4a6                	sd	s1,72(sp)
ffffffffc0200b30:	e8aa                	sd	a0,80(sp)
ffffffffc0200b32:	ecae                	sd	a1,88(sp)
ffffffffc0200b34:	f0b2                	sd	a2,96(sp)
ffffffffc0200b36:	f4b6                	sd	a3,104(sp)
ffffffffc0200b38:	f8ba                	sd	a4,112(sp)
ffffffffc0200b3a:	fcbe                	sd	a5,120(sp)
ffffffffc0200b3c:	e142                	sd	a6,128(sp)
ffffffffc0200b3e:	e546                	sd	a7,136(sp)
ffffffffc0200b40:	e94a                	sd	s2,144(sp)
ffffffffc0200b42:	ed4e                	sd	s3,152(sp)
ffffffffc0200b44:	f152                	sd	s4,160(sp)
ffffffffc0200b46:	f556                	sd	s5,168(sp)
ffffffffc0200b48:	f95a                	sd	s6,176(sp)
ffffffffc0200b4a:	fd5e                	sd	s7,184(sp)
ffffffffc0200b4c:	e1e2                	sd	s8,192(sp)
ffffffffc0200b4e:	e5e6                	sd	s9,200(sp)
ffffffffc0200b50:	e9ea                	sd	s10,208(sp)
ffffffffc0200b52:	edee                	sd	s11,216(sp)
ffffffffc0200b54:	f1f2                	sd	t3,224(sp)
ffffffffc0200b56:	f5f6                	sd	t4,232(sp)
ffffffffc0200b58:	f9fa                	sd	t5,240(sp)
ffffffffc0200b5a:	fdfe                	sd	t6,248(sp)
ffffffffc0200b5c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200b60:	100024f3          	csrr	s1,sstatus
ffffffffc0200b64:	14102973          	csrr	s2,sepc
ffffffffc0200b68:	143029f3          	csrr	s3,stval
ffffffffc0200b6c:	14202a73          	csrr	s4,scause
ffffffffc0200b70:	e822                	sd	s0,16(sp)
ffffffffc0200b72:	e226                	sd	s1,256(sp)
ffffffffc0200b74:	e64a                	sd	s2,264(sp)
ffffffffc0200b76:	ea4e                	sd	s3,272(sp)
ffffffffc0200b78:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b7a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b7c:	f89ff0ef          	jal	ffffffffc0200b04 <trap>

ffffffffc0200b80 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b80:	6492                	ld	s1,256(sp)
ffffffffc0200b82:	6932                	ld	s2,264(sp)
ffffffffc0200b84:	10049073          	csrw	sstatus,s1
ffffffffc0200b88:	14191073          	csrw	sepc,s2
ffffffffc0200b8c:	60a2                	ld	ra,8(sp)
ffffffffc0200b8e:	61e2                	ld	gp,24(sp)
ffffffffc0200b90:	7202                	ld	tp,32(sp)
ffffffffc0200b92:	72a2                	ld	t0,40(sp)
ffffffffc0200b94:	7342                	ld	t1,48(sp)
ffffffffc0200b96:	73e2                	ld	t2,56(sp)
ffffffffc0200b98:	6406                	ld	s0,64(sp)
ffffffffc0200b9a:	64a6                	ld	s1,72(sp)
ffffffffc0200b9c:	6546                	ld	a0,80(sp)
ffffffffc0200b9e:	65e6                	ld	a1,88(sp)
ffffffffc0200ba0:	7606                	ld	a2,96(sp)
ffffffffc0200ba2:	76a6                	ld	a3,104(sp)
ffffffffc0200ba4:	7746                	ld	a4,112(sp)
ffffffffc0200ba6:	77e6                	ld	a5,120(sp)
ffffffffc0200ba8:	680a                	ld	a6,128(sp)
ffffffffc0200baa:	68aa                	ld	a7,136(sp)
ffffffffc0200bac:	694a                	ld	s2,144(sp)
ffffffffc0200bae:	69ea                	ld	s3,152(sp)
ffffffffc0200bb0:	7a0a                	ld	s4,160(sp)
ffffffffc0200bb2:	7aaa                	ld	s5,168(sp)
ffffffffc0200bb4:	7b4a                	ld	s6,176(sp)
ffffffffc0200bb6:	7bea                	ld	s7,184(sp)
ffffffffc0200bb8:	6c0e                	ld	s8,192(sp)
ffffffffc0200bba:	6cae                	ld	s9,200(sp)
ffffffffc0200bbc:	6d4e                	ld	s10,208(sp)
ffffffffc0200bbe:	6dee                	ld	s11,216(sp)
ffffffffc0200bc0:	7e0e                	ld	t3,224(sp)
ffffffffc0200bc2:	7eae                	ld	t4,232(sp)
ffffffffc0200bc4:	7f4e                	ld	t5,240(sp)
ffffffffc0200bc6:	7fee                	ld	t6,248(sp)
ffffffffc0200bc8:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200bca:	10200073          	sret

ffffffffc0200bce <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200bce:	00005797          	auipc	a5,0x5
ffffffffc0200bd2:	45a78793          	addi	a5,a5,1114 # ffffffffc0206028 <free_area>
ffffffffc0200bd6:	e79c                	sd	a5,8(a5)
ffffffffc0200bd8:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200bda:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200bde:	8082                	ret

ffffffffc0200be0 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200be0:	00005517          	auipc	a0,0x5
ffffffffc0200be4:	45856503          	lwu	a0,1112(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200be8:	8082                	ret

ffffffffc0200bea <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200bea:	715d                	addi	sp,sp,-80
ffffffffc0200bec:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200bee:	00005417          	auipc	s0,0x5
ffffffffc0200bf2:	43a40413          	addi	s0,s0,1082 # ffffffffc0206028 <free_area>
ffffffffc0200bf6:	641c                	ld	a5,8(s0)
ffffffffc0200bf8:	e486                	sd	ra,72(sp)
ffffffffc0200bfa:	fc26                	sd	s1,56(sp)
ffffffffc0200bfc:	f84a                	sd	s2,48(sp)
ffffffffc0200bfe:	f44e                	sd	s3,40(sp)
ffffffffc0200c00:	f052                	sd	s4,32(sp)
ffffffffc0200c02:	ec56                	sd	s5,24(sp)
ffffffffc0200c04:	e85a                	sd	s6,16(sp)
ffffffffc0200c06:	e45e                	sd	s7,8(sp)
ffffffffc0200c08:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c0a:	2e878063          	beq	a5,s0,ffffffffc0200eea <default_check+0x300>
    int count = 0, total = 0;
ffffffffc0200c0e:	4481                	li	s1,0
ffffffffc0200c10:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c12:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c16:	8b09                	andi	a4,a4,2
ffffffffc0200c18:	2c070d63          	beqz	a4,ffffffffc0200ef2 <default_check+0x308>
        count ++, total += p->property;
ffffffffc0200c1c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c20:	679c                	ld	a5,8(a5)
ffffffffc0200c22:	2905                	addiw	s2,s2,1
ffffffffc0200c24:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c26:	fe8796e3          	bne	a5,s0,ffffffffc0200c12 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200c2a:	89a6                	mv	s3,s1
ffffffffc0200c2c:	30b000ef          	jal	ffffffffc0201736 <nr_free_pages>
ffffffffc0200c30:	73351163          	bne	a0,s3,ffffffffc0201352 <default_check+0x768>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c34:	4505                	li	a0,1
ffffffffc0200c36:	283000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200c3a:	8a2a                	mv	s4,a0
ffffffffc0200c3c:	44050b63          	beqz	a0,ffffffffc0201092 <default_check+0x4a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c40:	4505                	li	a0,1
ffffffffc0200c42:	277000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200c46:	89aa                	mv	s3,a0
ffffffffc0200c48:	72050563          	beqz	a0,ffffffffc0201372 <default_check+0x788>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c4c:	4505                	li	a0,1
ffffffffc0200c4e:	26b000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200c52:	8aaa                	mv	s5,a0
ffffffffc0200c54:	4a050f63          	beqz	a0,ffffffffc0201112 <default_check+0x528>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c58:	2b3a0d63          	beq	s4,s3,ffffffffc0200f12 <default_check+0x328>
ffffffffc0200c5c:	2aaa0b63          	beq	s4,a0,ffffffffc0200f12 <default_check+0x328>
ffffffffc0200c60:	2aa98963          	beq	s3,a0,ffffffffc0200f12 <default_check+0x328>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c64:	000a2783          	lw	a5,0(s4)
ffffffffc0200c68:	2c079563          	bnez	a5,ffffffffc0200f32 <default_check+0x348>
ffffffffc0200c6c:	0009a783          	lw	a5,0(s3)
ffffffffc0200c70:	2c079163          	bnez	a5,ffffffffc0200f32 <default_check+0x348>
ffffffffc0200c74:	411c                	lw	a5,0(a0)
ffffffffc0200c76:	2a079e63          	bnez	a5,ffffffffc0200f32 <default_check+0x348>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200c7a:	fcccd7b7          	lui	a5,0xfcccd
ffffffffc0200c7e:	ccd78793          	addi	a5,a5,-819 # fffffffffccccccd <end+0x3cac682d>
ffffffffc0200c82:	07b2                	slli	a5,a5,0xc
ffffffffc0200c84:	ccd78793          	addi	a5,a5,-819
ffffffffc0200c88:	07b2                	slli	a5,a5,0xc
ffffffffc0200c8a:	00006717          	auipc	a4,0x6
ffffffffc0200c8e:	80673703          	ld	a4,-2042(a4) # ffffffffc0206490 <pages>
ffffffffc0200c92:	ccd78793          	addi	a5,a5,-819
ffffffffc0200c96:	40ea06b3          	sub	a3,s4,a4
ffffffffc0200c9a:	07b2                	slli	a5,a5,0xc
ffffffffc0200c9c:	868d                	srai	a3,a3,0x3
ffffffffc0200c9e:	ccd78793          	addi	a5,a5,-819
ffffffffc0200ca2:	02f686b3          	mul	a3,a3,a5
ffffffffc0200ca6:	00002597          	auipc	a1,0x2
ffffffffc0200caa:	2c25b583          	ld	a1,706(a1) # ffffffffc0202f68 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cae:	00005617          	auipc	a2,0x5
ffffffffc0200cb2:	7da63603          	ld	a2,2010(a2) # ffffffffc0206488 <npage>
ffffffffc0200cb6:	0632                	slli	a2,a2,0xc
ffffffffc0200cb8:	96ae                	add	a3,a3,a1

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cba:	06b2                	slli	a3,a3,0xc
ffffffffc0200cbc:	28c6fb63          	bgeu	a3,a2,ffffffffc0200f52 <default_check+0x368>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cc0:	40e986b3          	sub	a3,s3,a4
ffffffffc0200cc4:	868d                	srai	a3,a3,0x3
ffffffffc0200cc6:	02f686b3          	mul	a3,a3,a5
ffffffffc0200cca:	96ae                	add	a3,a3,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200ccc:	06b2                	slli	a3,a3,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200cce:	4cc6f263          	bgeu	a3,a2,ffffffffc0201192 <default_check+0x5a8>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cd2:	40e50733          	sub	a4,a0,a4
ffffffffc0200cd6:	870d                	srai	a4,a4,0x3
ffffffffc0200cd8:	02f707b3          	mul	a5,a4,a5
ffffffffc0200cdc:	97ae                	add	a5,a5,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc0200cde:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ce0:	30c7f963          	bgeu	a5,a2,ffffffffc0200ff2 <default_check+0x408>
    assert(alloc_page() == NULL);
ffffffffc0200ce4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200ce6:	00043c03          	ld	s8,0(s0)
ffffffffc0200cea:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200cee:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200cf2:	e400                	sd	s0,8(s0)
ffffffffc0200cf4:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200cf6:	00005797          	auipc	a5,0x5
ffffffffc0200cfa:	3407a123          	sw	zero,834(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200cfe:	1bb000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d02:	2c051863          	bnez	a0,ffffffffc0200fd2 <default_check+0x3e8>
    free_page(p0);
ffffffffc0200d06:	4585                	li	a1,1
ffffffffc0200d08:	8552                	mv	a0,s4
ffffffffc0200d0a:	1ed000ef          	jal	ffffffffc02016f6 <free_pages>
    free_page(p1);
ffffffffc0200d0e:	4585                	li	a1,1
ffffffffc0200d10:	854e                	mv	a0,s3
ffffffffc0200d12:	1e5000ef          	jal	ffffffffc02016f6 <free_pages>
    free_page(p2);
ffffffffc0200d16:	4585                	li	a1,1
ffffffffc0200d18:	8556                	mv	a0,s5
ffffffffc0200d1a:	1dd000ef          	jal	ffffffffc02016f6 <free_pages>
    assert(nr_free == 3);
ffffffffc0200d1e:	4818                	lw	a4,16(s0)
ffffffffc0200d20:	478d                	li	a5,3
ffffffffc0200d22:	28f71863          	bne	a4,a5,ffffffffc0200fb2 <default_check+0x3c8>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d26:	4505                	li	a0,1
ffffffffc0200d28:	191000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d2c:	89aa                	mv	s3,a0
ffffffffc0200d2e:	26050263          	beqz	a0,ffffffffc0200f92 <default_check+0x3a8>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d32:	4505                	li	a0,1
ffffffffc0200d34:	185000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d38:	8aaa                	mv	s5,a0
ffffffffc0200d3a:	3a050c63          	beqz	a0,ffffffffc02010f2 <default_check+0x508>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d3e:	4505                	li	a0,1
ffffffffc0200d40:	179000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d44:	8a2a                	mv	s4,a0
ffffffffc0200d46:	38050663          	beqz	a0,ffffffffc02010d2 <default_check+0x4e8>
    assert(alloc_page() == NULL);
ffffffffc0200d4a:	4505                	li	a0,1
ffffffffc0200d4c:	16d000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d50:	36051163          	bnez	a0,ffffffffc02010b2 <default_check+0x4c8>
    free_page(p0);
ffffffffc0200d54:	4585                	li	a1,1
ffffffffc0200d56:	854e                	mv	a0,s3
ffffffffc0200d58:	19f000ef          	jal	ffffffffc02016f6 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200d5c:	641c                	ld	a5,8(s0)
ffffffffc0200d5e:	20878a63          	beq	a5,s0,ffffffffc0200f72 <default_check+0x388>
    assert((p = alloc_page()) == p0);
ffffffffc0200d62:	4505                	li	a0,1
ffffffffc0200d64:	155000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d68:	30a99563          	bne	s3,a0,ffffffffc0201072 <default_check+0x488>
    assert(alloc_page() == NULL);
ffffffffc0200d6c:	4505                	li	a0,1
ffffffffc0200d6e:	14b000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200d72:	2e051063          	bnez	a0,ffffffffc0201052 <default_check+0x468>
    assert(nr_free == 0);
ffffffffc0200d76:	481c                	lw	a5,16(s0)
ffffffffc0200d78:	2a079d63          	bnez	a5,ffffffffc0201032 <default_check+0x448>
    free_page(p);
ffffffffc0200d7c:	854e                	mv	a0,s3
ffffffffc0200d7e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200d80:	01843023          	sd	s8,0(s0)
ffffffffc0200d84:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200d88:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200d8c:	16b000ef          	jal	ffffffffc02016f6 <free_pages>
    free_page(p1);
ffffffffc0200d90:	4585                	li	a1,1
ffffffffc0200d92:	8556                	mv	a0,s5
ffffffffc0200d94:	163000ef          	jal	ffffffffc02016f6 <free_pages>
    free_page(p2);
ffffffffc0200d98:	4585                	li	a1,1
ffffffffc0200d9a:	8552                	mv	a0,s4
ffffffffc0200d9c:	15b000ef          	jal	ffffffffc02016f6 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200da0:	4515                	li	a0,5
ffffffffc0200da2:	117000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200da6:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200da8:	26050563          	beqz	a0,ffffffffc0201012 <default_check+0x428>
ffffffffc0200dac:	651c                	ld	a5,8(a0)
ffffffffc0200dae:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200db0:	8b85                	andi	a5,a5,1
ffffffffc0200db2:	54079063          	bnez	a5,ffffffffc02012f2 <default_check+0x708>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200db6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200db8:	00043b03          	ld	s6,0(s0)
ffffffffc0200dbc:	00843a83          	ld	s5,8(s0)
ffffffffc0200dc0:	e000                	sd	s0,0(s0)
ffffffffc0200dc2:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200dc4:	0f5000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200dc8:	50051563          	bnez	a0,ffffffffc02012d2 <default_check+0x6e8>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0200dcc:	05098a13          	addi	s4,s3,80
ffffffffc0200dd0:	8552                	mv	a0,s4
ffffffffc0200dd2:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0200dd4:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0200dd8:	00005797          	auipc	a5,0x5
ffffffffc0200ddc:	2607a023          	sw	zero,608(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0200de0:	117000ef          	jal	ffffffffc02016f6 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200de4:	4511                	li	a0,4
ffffffffc0200de6:	0d3000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200dea:	4c051463          	bnez	a0,ffffffffc02012b2 <default_check+0x6c8>
ffffffffc0200dee:	0589b783          	ld	a5,88(s3)
ffffffffc0200df2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0200df4:	8b85                	andi	a5,a5,1
ffffffffc0200df6:	48078e63          	beqz	a5,ffffffffc0201292 <default_check+0x6a8>
ffffffffc0200dfa:	0609a703          	lw	a4,96(s3)
ffffffffc0200dfe:	478d                	li	a5,3
ffffffffc0200e00:	48f71963          	bne	a4,a5,ffffffffc0201292 <default_check+0x6a8>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0200e04:	450d                	li	a0,3
ffffffffc0200e06:	0b3000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200e0a:	8c2a                	mv	s8,a0
ffffffffc0200e0c:	46050363          	beqz	a0,ffffffffc0201272 <default_check+0x688>
    assert(alloc_page() == NULL);
ffffffffc0200e10:	4505                	li	a0,1
ffffffffc0200e12:	0a7000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200e16:	42051e63          	bnez	a0,ffffffffc0201252 <default_check+0x668>
    assert(p0 + 2 == p1);
ffffffffc0200e1a:	418a1c63          	bne	s4,s8,ffffffffc0201232 <default_check+0x648>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0200e1e:	4585                	li	a1,1
ffffffffc0200e20:	854e                	mv	a0,s3
ffffffffc0200e22:	0d5000ef          	jal	ffffffffc02016f6 <free_pages>
    free_pages(p1, 3);
ffffffffc0200e26:	458d                	li	a1,3
ffffffffc0200e28:	8552                	mv	a0,s4
ffffffffc0200e2a:	0cd000ef          	jal	ffffffffc02016f6 <free_pages>
ffffffffc0200e2e:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0200e32:	02898c13          	addi	s8,s3,40
ffffffffc0200e36:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0200e38:	8b85                	andi	a5,a5,1
ffffffffc0200e3a:	3c078c63          	beqz	a5,ffffffffc0201212 <default_check+0x628>
ffffffffc0200e3e:	0109a703          	lw	a4,16(s3)
ffffffffc0200e42:	4785                	li	a5,1
ffffffffc0200e44:	3cf71763          	bne	a4,a5,ffffffffc0201212 <default_check+0x628>
ffffffffc0200e48:	008a3783          	ld	a5,8(s4)
ffffffffc0200e4c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0200e4e:	8b85                	andi	a5,a5,1
ffffffffc0200e50:	3a078163          	beqz	a5,ffffffffc02011f2 <default_check+0x608>
ffffffffc0200e54:	010a2703          	lw	a4,16(s4)
ffffffffc0200e58:	478d                	li	a5,3
ffffffffc0200e5a:	38f71c63          	bne	a4,a5,ffffffffc02011f2 <default_check+0x608>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0200e5e:	4505                	li	a0,1
ffffffffc0200e60:	059000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200e64:	36a99763          	bne	s3,a0,ffffffffc02011d2 <default_check+0x5e8>
    free_page(p0);
ffffffffc0200e68:	4585                	li	a1,1
ffffffffc0200e6a:	08d000ef          	jal	ffffffffc02016f6 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0200e6e:	4509                	li	a0,2
ffffffffc0200e70:	049000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200e74:	32aa1f63          	bne	s4,a0,ffffffffc02011b2 <default_check+0x5c8>

    free_pages(p0, 2);
ffffffffc0200e78:	4589                	li	a1,2
ffffffffc0200e7a:	07d000ef          	jal	ffffffffc02016f6 <free_pages>
    free_page(p2);
ffffffffc0200e7e:	4585                	li	a1,1
ffffffffc0200e80:	8562                	mv	a0,s8
ffffffffc0200e82:	075000ef          	jal	ffffffffc02016f6 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e86:	4515                	li	a0,5
ffffffffc0200e88:	031000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200e8c:	89aa                	mv	s3,a0
ffffffffc0200e8e:	48050263          	beqz	a0,ffffffffc0201312 <default_check+0x728>
    assert(alloc_page() == NULL);
ffffffffc0200e92:	4505                	li	a0,1
ffffffffc0200e94:	025000ef          	jal	ffffffffc02016b8 <alloc_pages>
ffffffffc0200e98:	2c051d63          	bnez	a0,ffffffffc0201172 <default_check+0x588>

    assert(nr_free == 0);
ffffffffc0200e9c:	481c                	lw	a5,16(s0)
ffffffffc0200e9e:	2a079a63          	bnez	a5,ffffffffc0201152 <default_check+0x568>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ea2:	4595                	li	a1,5
ffffffffc0200ea4:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200ea6:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200eaa:	01643023          	sd	s6,0(s0)
ffffffffc0200eae:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0200eb2:	045000ef          	jal	ffffffffc02016f6 <free_pages>
    return listelm->next;
ffffffffc0200eb6:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eb8:	00878963          	beq	a5,s0,ffffffffc0200eca <default_check+0x2e0>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200ebc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ec0:	679c                	ld	a5,8(a5)
ffffffffc0200ec2:	397d                	addiw	s2,s2,-1
ffffffffc0200ec4:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ec6:	fe879be3          	bne	a5,s0,ffffffffc0200ebc <default_check+0x2d2>
    }
    assert(count == 0);
ffffffffc0200eca:	26091463          	bnez	s2,ffffffffc0201132 <default_check+0x548>
    assert(total == 0);
ffffffffc0200ece:	46049263          	bnez	s1,ffffffffc0201332 <default_check+0x748>
}
ffffffffc0200ed2:	60a6                	ld	ra,72(sp)
ffffffffc0200ed4:	6406                	ld	s0,64(sp)
ffffffffc0200ed6:	74e2                	ld	s1,56(sp)
ffffffffc0200ed8:	7942                	ld	s2,48(sp)
ffffffffc0200eda:	79a2                	ld	s3,40(sp)
ffffffffc0200edc:	7a02                	ld	s4,32(sp)
ffffffffc0200ede:	6ae2                	ld	s5,24(sp)
ffffffffc0200ee0:	6b42                	ld	s6,16(sp)
ffffffffc0200ee2:	6ba2                	ld	s7,8(sp)
ffffffffc0200ee4:	6c02                	ld	s8,0(sp)
ffffffffc0200ee6:	6161                	addi	sp,sp,80
ffffffffc0200ee8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eea:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200eec:	4481                	li	s1,0
ffffffffc0200eee:	4901                	li	s2,0
ffffffffc0200ef0:	bb35                	j	ffffffffc0200c2c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0200ef2:	00002697          	auipc	a3,0x2
ffffffffc0200ef6:	87668693          	addi	a3,a3,-1930 # ffffffffc0202768 <etext+0x830>
ffffffffc0200efa:	00002617          	auipc	a2,0x2
ffffffffc0200efe:	87e60613          	addi	a2,a2,-1922 # ffffffffc0202778 <etext+0x840>
ffffffffc0200f02:	0f000593          	li	a1,240
ffffffffc0200f06:	00002517          	auipc	a0,0x2
ffffffffc0200f0a:	88a50513          	addi	a0,a0,-1910 # ffffffffc0202790 <etext+0x858>
ffffffffc0200f0e:	cbeff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f12:	00002697          	auipc	a3,0x2
ffffffffc0200f16:	91668693          	addi	a3,a3,-1770 # ffffffffc0202828 <etext+0x8f0>
ffffffffc0200f1a:	00002617          	auipc	a2,0x2
ffffffffc0200f1e:	85e60613          	addi	a2,a2,-1954 # ffffffffc0202778 <etext+0x840>
ffffffffc0200f22:	0bd00593          	li	a1,189
ffffffffc0200f26:	00002517          	auipc	a0,0x2
ffffffffc0200f2a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0202790 <etext+0x858>
ffffffffc0200f2e:	c9eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f32:	00002697          	auipc	a3,0x2
ffffffffc0200f36:	91e68693          	addi	a3,a3,-1762 # ffffffffc0202850 <etext+0x918>
ffffffffc0200f3a:	00002617          	auipc	a2,0x2
ffffffffc0200f3e:	83e60613          	addi	a2,a2,-1986 # ffffffffc0202778 <etext+0x840>
ffffffffc0200f42:	0be00593          	li	a1,190
ffffffffc0200f46:	00002517          	auipc	a0,0x2
ffffffffc0200f4a:	84a50513          	addi	a0,a0,-1974 # ffffffffc0202790 <etext+0x858>
ffffffffc0200f4e:	c7eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f52:	00002697          	auipc	a3,0x2
ffffffffc0200f56:	93e68693          	addi	a3,a3,-1730 # ffffffffc0202890 <etext+0x958>
ffffffffc0200f5a:	00002617          	auipc	a2,0x2
ffffffffc0200f5e:	81e60613          	addi	a2,a2,-2018 # ffffffffc0202778 <etext+0x840>
ffffffffc0200f62:	0c000593          	li	a1,192
ffffffffc0200f66:	00002517          	auipc	a0,0x2
ffffffffc0200f6a:	82a50513          	addi	a0,a0,-2006 # ffffffffc0202790 <etext+0x858>
ffffffffc0200f6e:	c5eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f72:	00002697          	auipc	a3,0x2
ffffffffc0200f76:	9a668693          	addi	a3,a3,-1626 # ffffffffc0202918 <etext+0x9e0>
ffffffffc0200f7a:	00001617          	auipc	a2,0x1
ffffffffc0200f7e:	7fe60613          	addi	a2,a2,2046 # ffffffffc0202778 <etext+0x840>
ffffffffc0200f82:	0d900593          	li	a1,217
ffffffffc0200f86:	00002517          	auipc	a0,0x2
ffffffffc0200f8a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0202790 <etext+0x858>
ffffffffc0200f8e:	c3eff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200f92:	00002697          	auipc	a3,0x2
ffffffffc0200f96:	83668693          	addi	a3,a3,-1994 # ffffffffc02027c8 <etext+0x890>
ffffffffc0200f9a:	00001617          	auipc	a2,0x1
ffffffffc0200f9e:	7de60613          	addi	a2,a2,2014 # ffffffffc0202778 <etext+0x840>
ffffffffc0200fa2:	0d200593          	li	a1,210
ffffffffc0200fa6:	00001517          	auipc	a0,0x1
ffffffffc0200faa:	7ea50513          	addi	a0,a0,2026 # ffffffffc0202790 <etext+0x858>
ffffffffc0200fae:	c1eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 3);
ffffffffc0200fb2:	00002697          	auipc	a3,0x2
ffffffffc0200fb6:	95668693          	addi	a3,a3,-1706 # ffffffffc0202908 <etext+0x9d0>
ffffffffc0200fba:	00001617          	auipc	a2,0x1
ffffffffc0200fbe:	7be60613          	addi	a2,a2,1982 # ffffffffc0202778 <etext+0x840>
ffffffffc0200fc2:	0d000593          	li	a1,208
ffffffffc0200fc6:	00001517          	auipc	a0,0x1
ffffffffc0200fca:	7ca50513          	addi	a0,a0,1994 # ffffffffc0202790 <etext+0x858>
ffffffffc0200fce:	bfeff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fd2:	00002697          	auipc	a3,0x2
ffffffffc0200fd6:	91e68693          	addi	a3,a3,-1762 # ffffffffc02028f0 <etext+0x9b8>
ffffffffc0200fda:	00001617          	auipc	a2,0x1
ffffffffc0200fde:	79e60613          	addi	a2,a2,1950 # ffffffffc0202778 <etext+0x840>
ffffffffc0200fe2:	0cb00593          	li	a1,203
ffffffffc0200fe6:	00001517          	auipc	a0,0x1
ffffffffc0200fea:	7aa50513          	addi	a0,a0,1962 # ffffffffc0202790 <etext+0x858>
ffffffffc0200fee:	bdeff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200ff2:	00002697          	auipc	a3,0x2
ffffffffc0200ff6:	8de68693          	addi	a3,a3,-1826 # ffffffffc02028d0 <etext+0x998>
ffffffffc0200ffa:	00001617          	auipc	a2,0x1
ffffffffc0200ffe:	77e60613          	addi	a2,a2,1918 # ffffffffc0202778 <etext+0x840>
ffffffffc0201002:	0c200593          	li	a1,194
ffffffffc0201006:	00001517          	auipc	a0,0x1
ffffffffc020100a:	78a50513          	addi	a0,a0,1930 # ffffffffc0202790 <etext+0x858>
ffffffffc020100e:	bbeff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 != NULL);
ffffffffc0201012:	00002697          	auipc	a3,0x2
ffffffffc0201016:	94e68693          	addi	a3,a3,-1714 # ffffffffc0202960 <etext+0xa28>
ffffffffc020101a:	00001617          	auipc	a2,0x1
ffffffffc020101e:	75e60613          	addi	a2,a2,1886 # ffffffffc0202778 <etext+0x840>
ffffffffc0201022:	0f800593          	li	a1,248
ffffffffc0201026:	00001517          	auipc	a0,0x1
ffffffffc020102a:	76a50513          	addi	a0,a0,1898 # ffffffffc0202790 <etext+0x858>
ffffffffc020102e:	b9eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 0);
ffffffffc0201032:	00002697          	auipc	a3,0x2
ffffffffc0201036:	91e68693          	addi	a3,a3,-1762 # ffffffffc0202950 <etext+0xa18>
ffffffffc020103a:	00001617          	auipc	a2,0x1
ffffffffc020103e:	73e60613          	addi	a2,a2,1854 # ffffffffc0202778 <etext+0x840>
ffffffffc0201042:	0df00593          	li	a1,223
ffffffffc0201046:	00001517          	auipc	a0,0x1
ffffffffc020104a:	74a50513          	addi	a0,a0,1866 # ffffffffc0202790 <etext+0x858>
ffffffffc020104e:	b7eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201052:	00002697          	auipc	a3,0x2
ffffffffc0201056:	89e68693          	addi	a3,a3,-1890 # ffffffffc02028f0 <etext+0x9b8>
ffffffffc020105a:	00001617          	auipc	a2,0x1
ffffffffc020105e:	71e60613          	addi	a2,a2,1822 # ffffffffc0202778 <etext+0x840>
ffffffffc0201062:	0dd00593          	li	a1,221
ffffffffc0201066:	00001517          	auipc	a0,0x1
ffffffffc020106a:	72a50513          	addi	a0,a0,1834 # ffffffffc0202790 <etext+0x858>
ffffffffc020106e:	b5eff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201072:	00002697          	auipc	a3,0x2
ffffffffc0201076:	8be68693          	addi	a3,a3,-1858 # ffffffffc0202930 <etext+0x9f8>
ffffffffc020107a:	00001617          	auipc	a2,0x1
ffffffffc020107e:	6fe60613          	addi	a2,a2,1790 # ffffffffc0202778 <etext+0x840>
ffffffffc0201082:	0dc00593          	li	a1,220
ffffffffc0201086:	00001517          	auipc	a0,0x1
ffffffffc020108a:	70a50513          	addi	a0,a0,1802 # ffffffffc0202790 <etext+0x858>
ffffffffc020108e:	b3eff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201092:	00001697          	auipc	a3,0x1
ffffffffc0201096:	73668693          	addi	a3,a3,1846 # ffffffffc02027c8 <etext+0x890>
ffffffffc020109a:	00001617          	auipc	a2,0x1
ffffffffc020109e:	6de60613          	addi	a2,a2,1758 # ffffffffc0202778 <etext+0x840>
ffffffffc02010a2:	0b900593          	li	a1,185
ffffffffc02010a6:	00001517          	auipc	a0,0x1
ffffffffc02010aa:	6ea50513          	addi	a0,a0,1770 # ffffffffc0202790 <etext+0x858>
ffffffffc02010ae:	b1eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010b2:	00002697          	auipc	a3,0x2
ffffffffc02010b6:	83e68693          	addi	a3,a3,-1986 # ffffffffc02028f0 <etext+0x9b8>
ffffffffc02010ba:	00001617          	auipc	a2,0x1
ffffffffc02010be:	6be60613          	addi	a2,a2,1726 # ffffffffc0202778 <etext+0x840>
ffffffffc02010c2:	0d600593          	li	a1,214
ffffffffc02010c6:	00001517          	auipc	a0,0x1
ffffffffc02010ca:	6ca50513          	addi	a0,a0,1738 # ffffffffc0202790 <etext+0x858>
ffffffffc02010ce:	afeff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010d2:	00001697          	auipc	a3,0x1
ffffffffc02010d6:	73668693          	addi	a3,a3,1846 # ffffffffc0202808 <etext+0x8d0>
ffffffffc02010da:	00001617          	auipc	a2,0x1
ffffffffc02010de:	69e60613          	addi	a2,a2,1694 # ffffffffc0202778 <etext+0x840>
ffffffffc02010e2:	0d400593          	li	a1,212
ffffffffc02010e6:	00001517          	auipc	a0,0x1
ffffffffc02010ea:	6aa50513          	addi	a0,a0,1706 # ffffffffc0202790 <etext+0x858>
ffffffffc02010ee:	adeff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010f2:	00001697          	auipc	a3,0x1
ffffffffc02010f6:	6f668693          	addi	a3,a3,1782 # ffffffffc02027e8 <etext+0x8b0>
ffffffffc02010fa:	00001617          	auipc	a2,0x1
ffffffffc02010fe:	67e60613          	addi	a2,a2,1662 # ffffffffc0202778 <etext+0x840>
ffffffffc0201102:	0d300593          	li	a1,211
ffffffffc0201106:	00001517          	auipc	a0,0x1
ffffffffc020110a:	68a50513          	addi	a0,a0,1674 # ffffffffc0202790 <etext+0x858>
ffffffffc020110e:	abeff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201112:	00001697          	auipc	a3,0x1
ffffffffc0201116:	6f668693          	addi	a3,a3,1782 # ffffffffc0202808 <etext+0x8d0>
ffffffffc020111a:	00001617          	auipc	a2,0x1
ffffffffc020111e:	65e60613          	addi	a2,a2,1630 # ffffffffc0202778 <etext+0x840>
ffffffffc0201122:	0bb00593          	li	a1,187
ffffffffc0201126:	00001517          	auipc	a0,0x1
ffffffffc020112a:	66a50513          	addi	a0,a0,1642 # ffffffffc0202790 <etext+0x858>
ffffffffc020112e:	a9eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(count == 0);
ffffffffc0201132:	00002697          	auipc	a3,0x2
ffffffffc0201136:	97e68693          	addi	a3,a3,-1666 # ffffffffc0202ab0 <etext+0xb78>
ffffffffc020113a:	00001617          	auipc	a2,0x1
ffffffffc020113e:	63e60613          	addi	a2,a2,1598 # ffffffffc0202778 <etext+0x840>
ffffffffc0201142:	12500593          	li	a1,293
ffffffffc0201146:	00001517          	auipc	a0,0x1
ffffffffc020114a:	64a50513          	addi	a0,a0,1610 # ffffffffc0202790 <etext+0x858>
ffffffffc020114e:	a7eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(nr_free == 0);
ffffffffc0201152:	00001697          	auipc	a3,0x1
ffffffffc0201156:	7fe68693          	addi	a3,a3,2046 # ffffffffc0202950 <etext+0xa18>
ffffffffc020115a:	00001617          	auipc	a2,0x1
ffffffffc020115e:	61e60613          	addi	a2,a2,1566 # ffffffffc0202778 <etext+0x840>
ffffffffc0201162:	11a00593          	li	a1,282
ffffffffc0201166:	00001517          	auipc	a0,0x1
ffffffffc020116a:	62a50513          	addi	a0,a0,1578 # ffffffffc0202790 <etext+0x858>
ffffffffc020116e:	a5eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201172:	00001697          	auipc	a3,0x1
ffffffffc0201176:	77e68693          	addi	a3,a3,1918 # ffffffffc02028f0 <etext+0x9b8>
ffffffffc020117a:	00001617          	auipc	a2,0x1
ffffffffc020117e:	5fe60613          	addi	a2,a2,1534 # ffffffffc0202778 <etext+0x840>
ffffffffc0201182:	11800593          	li	a1,280
ffffffffc0201186:	00001517          	auipc	a0,0x1
ffffffffc020118a:	60a50513          	addi	a0,a0,1546 # ffffffffc0202790 <etext+0x858>
ffffffffc020118e:	a3eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201192:	00001697          	auipc	a3,0x1
ffffffffc0201196:	71e68693          	addi	a3,a3,1822 # ffffffffc02028b0 <etext+0x978>
ffffffffc020119a:	00001617          	auipc	a2,0x1
ffffffffc020119e:	5de60613          	addi	a2,a2,1502 # ffffffffc0202778 <etext+0x840>
ffffffffc02011a2:	0c100593          	li	a1,193
ffffffffc02011a6:	00001517          	auipc	a0,0x1
ffffffffc02011aa:	5ea50513          	addi	a0,a0,1514 # ffffffffc0202790 <etext+0x858>
ffffffffc02011ae:	a1eff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011b2:	00002697          	auipc	a3,0x2
ffffffffc02011b6:	8be68693          	addi	a3,a3,-1858 # ffffffffc0202a70 <etext+0xb38>
ffffffffc02011ba:	00001617          	auipc	a2,0x1
ffffffffc02011be:	5be60613          	addi	a2,a2,1470 # ffffffffc0202778 <etext+0x840>
ffffffffc02011c2:	11200593          	li	a1,274
ffffffffc02011c6:	00001517          	auipc	a0,0x1
ffffffffc02011ca:	5ca50513          	addi	a0,a0,1482 # ffffffffc0202790 <etext+0x858>
ffffffffc02011ce:	9feff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011d2:	00002697          	auipc	a3,0x2
ffffffffc02011d6:	87e68693          	addi	a3,a3,-1922 # ffffffffc0202a50 <etext+0xb18>
ffffffffc02011da:	00001617          	auipc	a2,0x1
ffffffffc02011de:	59e60613          	addi	a2,a2,1438 # ffffffffc0202778 <etext+0x840>
ffffffffc02011e2:	11000593          	li	a1,272
ffffffffc02011e6:	00001517          	auipc	a0,0x1
ffffffffc02011ea:	5aa50513          	addi	a0,a0,1450 # ffffffffc0202790 <etext+0x858>
ffffffffc02011ee:	9deff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011f2:	00002697          	auipc	a3,0x2
ffffffffc02011f6:	83668693          	addi	a3,a3,-1994 # ffffffffc0202a28 <etext+0xaf0>
ffffffffc02011fa:	00001617          	auipc	a2,0x1
ffffffffc02011fe:	57e60613          	addi	a2,a2,1406 # ffffffffc0202778 <etext+0x840>
ffffffffc0201202:	10e00593          	li	a1,270
ffffffffc0201206:	00001517          	auipc	a0,0x1
ffffffffc020120a:	58a50513          	addi	a0,a0,1418 # ffffffffc0202790 <etext+0x858>
ffffffffc020120e:	9beff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201212:	00001697          	auipc	a3,0x1
ffffffffc0201216:	7ee68693          	addi	a3,a3,2030 # ffffffffc0202a00 <etext+0xac8>
ffffffffc020121a:	00001617          	auipc	a2,0x1
ffffffffc020121e:	55e60613          	addi	a2,a2,1374 # ffffffffc0202778 <etext+0x840>
ffffffffc0201222:	10d00593          	li	a1,269
ffffffffc0201226:	00001517          	auipc	a0,0x1
ffffffffc020122a:	56a50513          	addi	a0,a0,1386 # ffffffffc0202790 <etext+0x858>
ffffffffc020122e:	99eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(p0 + 2 == p1);
ffffffffc0201232:	00001697          	auipc	a3,0x1
ffffffffc0201236:	7be68693          	addi	a3,a3,1982 # ffffffffc02029f0 <etext+0xab8>
ffffffffc020123a:	00001617          	auipc	a2,0x1
ffffffffc020123e:	53e60613          	addi	a2,a2,1342 # ffffffffc0202778 <etext+0x840>
ffffffffc0201242:	10800593          	li	a1,264
ffffffffc0201246:	00001517          	auipc	a0,0x1
ffffffffc020124a:	54a50513          	addi	a0,a0,1354 # ffffffffc0202790 <etext+0x858>
ffffffffc020124e:	97eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201252:	00001697          	auipc	a3,0x1
ffffffffc0201256:	69e68693          	addi	a3,a3,1694 # ffffffffc02028f0 <etext+0x9b8>
ffffffffc020125a:	00001617          	auipc	a2,0x1
ffffffffc020125e:	51e60613          	addi	a2,a2,1310 # ffffffffc0202778 <etext+0x840>
ffffffffc0201262:	10700593          	li	a1,263
ffffffffc0201266:	00001517          	auipc	a0,0x1
ffffffffc020126a:	52a50513          	addi	a0,a0,1322 # ffffffffc0202790 <etext+0x858>
ffffffffc020126e:	95eff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201272:	00001697          	auipc	a3,0x1
ffffffffc0201276:	75e68693          	addi	a3,a3,1886 # ffffffffc02029d0 <etext+0xa98>
ffffffffc020127a:	00001617          	auipc	a2,0x1
ffffffffc020127e:	4fe60613          	addi	a2,a2,1278 # ffffffffc0202778 <etext+0x840>
ffffffffc0201282:	10600593          	li	a1,262
ffffffffc0201286:	00001517          	auipc	a0,0x1
ffffffffc020128a:	50a50513          	addi	a0,a0,1290 # ffffffffc0202790 <etext+0x858>
ffffffffc020128e:	93eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201292:	00001697          	auipc	a3,0x1
ffffffffc0201296:	70e68693          	addi	a3,a3,1806 # ffffffffc02029a0 <etext+0xa68>
ffffffffc020129a:	00001617          	auipc	a2,0x1
ffffffffc020129e:	4de60613          	addi	a2,a2,1246 # ffffffffc0202778 <etext+0x840>
ffffffffc02012a2:	10500593          	li	a1,261
ffffffffc02012a6:	00001517          	auipc	a0,0x1
ffffffffc02012aa:	4ea50513          	addi	a0,a0,1258 # ffffffffc0202790 <etext+0x858>
ffffffffc02012ae:	91eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02012b2:	00001697          	auipc	a3,0x1
ffffffffc02012b6:	6d668693          	addi	a3,a3,1750 # ffffffffc0202988 <etext+0xa50>
ffffffffc02012ba:	00001617          	auipc	a2,0x1
ffffffffc02012be:	4be60613          	addi	a2,a2,1214 # ffffffffc0202778 <etext+0x840>
ffffffffc02012c2:	10400593          	li	a1,260
ffffffffc02012c6:	00001517          	auipc	a0,0x1
ffffffffc02012ca:	4ca50513          	addi	a0,a0,1226 # ffffffffc0202790 <etext+0x858>
ffffffffc02012ce:	8feff0ef          	jal	ffffffffc02003cc <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012d2:	00001697          	auipc	a3,0x1
ffffffffc02012d6:	61e68693          	addi	a3,a3,1566 # ffffffffc02028f0 <etext+0x9b8>
ffffffffc02012da:	00001617          	auipc	a2,0x1
ffffffffc02012de:	49e60613          	addi	a2,a2,1182 # ffffffffc0202778 <etext+0x840>
ffffffffc02012e2:	0fe00593          	li	a1,254
ffffffffc02012e6:	00001517          	auipc	a0,0x1
ffffffffc02012ea:	4aa50513          	addi	a0,a0,1194 # ffffffffc0202790 <etext+0x858>
ffffffffc02012ee:	8deff0ef          	jal	ffffffffc02003cc <__panic>
    assert(!PageProperty(p0));
ffffffffc02012f2:	00001697          	auipc	a3,0x1
ffffffffc02012f6:	67e68693          	addi	a3,a3,1662 # ffffffffc0202970 <etext+0xa38>
ffffffffc02012fa:	00001617          	auipc	a2,0x1
ffffffffc02012fe:	47e60613          	addi	a2,a2,1150 # ffffffffc0202778 <etext+0x840>
ffffffffc0201302:	0f900593          	li	a1,249
ffffffffc0201306:	00001517          	auipc	a0,0x1
ffffffffc020130a:	48a50513          	addi	a0,a0,1162 # ffffffffc0202790 <etext+0x858>
ffffffffc020130e:	8beff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201312:	00001697          	auipc	a3,0x1
ffffffffc0201316:	77e68693          	addi	a3,a3,1918 # ffffffffc0202a90 <etext+0xb58>
ffffffffc020131a:	00001617          	auipc	a2,0x1
ffffffffc020131e:	45e60613          	addi	a2,a2,1118 # ffffffffc0202778 <etext+0x840>
ffffffffc0201322:	11700593          	li	a1,279
ffffffffc0201326:	00001517          	auipc	a0,0x1
ffffffffc020132a:	46a50513          	addi	a0,a0,1130 # ffffffffc0202790 <etext+0x858>
ffffffffc020132e:	89eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(total == 0);
ffffffffc0201332:	00001697          	auipc	a3,0x1
ffffffffc0201336:	78e68693          	addi	a3,a3,1934 # ffffffffc0202ac0 <etext+0xb88>
ffffffffc020133a:	00001617          	auipc	a2,0x1
ffffffffc020133e:	43e60613          	addi	a2,a2,1086 # ffffffffc0202778 <etext+0x840>
ffffffffc0201342:	12600593          	li	a1,294
ffffffffc0201346:	00001517          	auipc	a0,0x1
ffffffffc020134a:	44a50513          	addi	a0,a0,1098 # ffffffffc0202790 <etext+0x858>
ffffffffc020134e:	87eff0ef          	jal	ffffffffc02003cc <__panic>
    assert(total == nr_free_pages());
ffffffffc0201352:	00001697          	auipc	a3,0x1
ffffffffc0201356:	45668693          	addi	a3,a3,1110 # ffffffffc02027a8 <etext+0x870>
ffffffffc020135a:	00001617          	auipc	a2,0x1
ffffffffc020135e:	41e60613          	addi	a2,a2,1054 # ffffffffc0202778 <etext+0x840>
ffffffffc0201362:	0f300593          	li	a1,243
ffffffffc0201366:	00001517          	auipc	a0,0x1
ffffffffc020136a:	42a50513          	addi	a0,a0,1066 # ffffffffc0202790 <etext+0x858>
ffffffffc020136e:	85eff0ef          	jal	ffffffffc02003cc <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201372:	00001697          	auipc	a3,0x1
ffffffffc0201376:	47668693          	addi	a3,a3,1142 # ffffffffc02027e8 <etext+0x8b0>
ffffffffc020137a:	00001617          	auipc	a2,0x1
ffffffffc020137e:	3fe60613          	addi	a2,a2,1022 # ffffffffc0202778 <etext+0x840>
ffffffffc0201382:	0ba00593          	li	a1,186
ffffffffc0201386:	00001517          	auipc	a0,0x1
ffffffffc020138a:	40a50513          	addi	a0,a0,1034 # ffffffffc0202790 <etext+0x858>
ffffffffc020138e:	83eff0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0201392 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201392:	1141                	addi	sp,sp,-16
ffffffffc0201394:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201396:	14058a63          	beqz	a1,ffffffffc02014ea <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020139a:	00259713          	slli	a4,a1,0x2
ffffffffc020139e:	972e                	add	a4,a4,a1
ffffffffc02013a0:	070e                	slli	a4,a4,0x3
ffffffffc02013a2:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02013a6:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02013a8:	c30d                	beqz	a4,ffffffffc02013ca <default_free_pages+0x38>
ffffffffc02013aa:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02013ac:	8b05                	andi	a4,a4,1
ffffffffc02013ae:	10071e63          	bnez	a4,ffffffffc02014ca <default_free_pages+0x138>
ffffffffc02013b2:	6798                	ld	a4,8(a5)
ffffffffc02013b4:	8b09                	andi	a4,a4,2
ffffffffc02013b6:	10071a63          	bnez	a4,ffffffffc02014ca <default_free_pages+0x138>
        p->flags = 0;
ffffffffc02013ba:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02013be:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02013c2:	02878793          	addi	a5,a5,40
ffffffffc02013c6:	fed792e3          	bne	a5,a3,ffffffffc02013aa <default_free_pages+0x18>
    base->property = n;
ffffffffc02013ca:	2581                	sext.w	a1,a1
ffffffffc02013cc:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02013ce:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02013d2:	4789                	li	a5,2
ffffffffc02013d4:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	c5068693          	addi	a3,a3,-944 # ffffffffc0206028 <free_area>
ffffffffc02013e0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02013e2:	669c                	ld	a5,8(a3)
ffffffffc02013e4:	9f2d                	addw	a4,a4,a1
ffffffffc02013e6:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02013e8:	0ad78563          	beq	a5,a3,ffffffffc0201492 <default_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc02013ec:	fe878713          	addi	a4,a5,-24
ffffffffc02013f0:	4581                	li	a1,0
ffffffffc02013f2:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02013f6:	00e56a63          	bltu	a0,a4,ffffffffc020140a <default_free_pages+0x78>
    return listelm->next;
ffffffffc02013fa:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02013fc:	06d70263          	beq	a4,a3,ffffffffc0201460 <default_free_pages+0xce>
    struct Page *p = base;
ffffffffc0201400:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201402:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201406:	fee57ae3          	bgeu	a0,a4,ffffffffc02013fa <default_free_pages+0x68>
ffffffffc020140a:	c199                	beqz	a1,ffffffffc0201410 <default_free_pages+0x7e>
ffffffffc020140c:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201410:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201412:	e390                	sd	a2,0(a5)
ffffffffc0201414:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201416:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201418:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020141a:	02d70063          	beq	a4,a3,ffffffffc020143a <default_free_pages+0xa8>
        if (p + p->property == base) {
ffffffffc020141e:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201422:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc0201426:	02081613          	slli	a2,a6,0x20
ffffffffc020142a:	9201                	srli	a2,a2,0x20
ffffffffc020142c:	00261793          	slli	a5,a2,0x2
ffffffffc0201430:	97b2                	add	a5,a5,a2
ffffffffc0201432:	078e                	slli	a5,a5,0x3
ffffffffc0201434:	97ae                	add	a5,a5,a1
ffffffffc0201436:	02f50f63          	beq	a0,a5,ffffffffc0201474 <default_free_pages+0xe2>
    return listelm->next;
ffffffffc020143a:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc020143c:	00d70f63          	beq	a4,a3,ffffffffc020145a <default_free_pages+0xc8>
        if (base + base->property == p) {
ffffffffc0201440:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0201442:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc0201446:	02059613          	slli	a2,a1,0x20
ffffffffc020144a:	9201                	srli	a2,a2,0x20
ffffffffc020144c:	00261793          	slli	a5,a2,0x2
ffffffffc0201450:	97b2                	add	a5,a5,a2
ffffffffc0201452:	078e                	slli	a5,a5,0x3
ffffffffc0201454:	97aa                	add	a5,a5,a0
ffffffffc0201456:	04f68a63          	beq	a3,a5,ffffffffc02014aa <default_free_pages+0x118>
}
ffffffffc020145a:	60a2                	ld	ra,8(sp)
ffffffffc020145c:	0141                	addi	sp,sp,16
ffffffffc020145e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201460:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201462:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201464:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201466:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201468:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020146a:	02d70d63          	beq	a4,a3,ffffffffc02014a4 <default_free_pages+0x112>
ffffffffc020146e:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0201470:	87ba                	mv	a5,a4
ffffffffc0201472:	bf41                	j	ffffffffc0201402 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0201474:	491c                	lw	a5,16(a0)
ffffffffc0201476:	010787bb          	addw	a5,a5,a6
ffffffffc020147a:	fef72c23          	sw	a5,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020147e:	57f5                	li	a5,-3
ffffffffc0201480:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201484:	6d10                	ld	a2,24(a0)
ffffffffc0201486:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201488:	852e                	mv	a0,a1
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020148a:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc020148c:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020148e:	e390                	sd	a2,0(a5)
ffffffffc0201490:	b775                	j	ffffffffc020143c <default_free_pages+0xaa>
}
ffffffffc0201492:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201494:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201498:	e398                	sd	a4,0(a5)
ffffffffc020149a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020149c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020149e:	ed1c                	sd	a5,24(a0)
}
ffffffffc02014a0:	0141                	addi	sp,sp,16
ffffffffc02014a2:	8082                	ret
ffffffffc02014a4:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02014a6:	873e                	mv	a4,a5
ffffffffc02014a8:	bf8d                	j	ffffffffc020141a <default_free_pages+0x88>
            base->property += p->property;
ffffffffc02014aa:	ff872783          	lw	a5,-8(a4)
ffffffffc02014ae:	ff070693          	addi	a3,a4,-16
ffffffffc02014b2:	9fad                	addw	a5,a5,a1
ffffffffc02014b4:	c91c                	sw	a5,16(a0)
ffffffffc02014b6:	57f5                	li	a5,-3
ffffffffc02014b8:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02014bc:	6314                	ld	a3,0(a4)
ffffffffc02014be:	671c                	ld	a5,8(a4)
}
ffffffffc02014c0:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc02014c2:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02014c4:	e394                	sd	a3,0(a5)
ffffffffc02014c6:	0141                	addi	sp,sp,16
ffffffffc02014c8:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02014ca:	00001697          	auipc	a3,0x1
ffffffffc02014ce:	60e68693          	addi	a3,a3,1550 # ffffffffc0202ad8 <etext+0xba0>
ffffffffc02014d2:	00001617          	auipc	a2,0x1
ffffffffc02014d6:	2a660613          	addi	a2,a2,678 # ffffffffc0202778 <etext+0x840>
ffffffffc02014da:	08300593          	li	a1,131
ffffffffc02014de:	00001517          	auipc	a0,0x1
ffffffffc02014e2:	2b250513          	addi	a0,a0,690 # ffffffffc0202790 <etext+0x858>
ffffffffc02014e6:	ee7fe0ef          	jal	ffffffffc02003cc <__panic>
    assert(n > 0);
ffffffffc02014ea:	00001697          	auipc	a3,0x1
ffffffffc02014ee:	5e668693          	addi	a3,a3,1510 # ffffffffc0202ad0 <etext+0xb98>
ffffffffc02014f2:	00001617          	auipc	a2,0x1
ffffffffc02014f6:	28660613          	addi	a2,a2,646 # ffffffffc0202778 <etext+0x840>
ffffffffc02014fa:	08000593          	li	a1,128
ffffffffc02014fe:	00001517          	auipc	a0,0x1
ffffffffc0201502:	29250513          	addi	a0,a0,658 # ffffffffc0202790 <etext+0x858>
ffffffffc0201506:	ec7fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc020150a <default_alloc_pages>:
    assert(n > 0);
ffffffffc020150a:	c959                	beqz	a0,ffffffffc02015a0 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	b1c60613          	addi	a2,a2,-1252 # ffffffffc0206028 <free_area>
ffffffffc0201514:	4a0c                	lw	a1,16(a2)
ffffffffc0201516:	86aa                	mv	a3,a0
ffffffffc0201518:	02059793          	slli	a5,a1,0x20
ffffffffc020151c:	9381                	srli	a5,a5,0x20
ffffffffc020151e:	00a7eb63          	bltu	a5,a0,ffffffffc0201534 <default_alloc_pages+0x2a>
    list_entry_t *le = &free_list;
ffffffffc0201522:	87b2                	mv	a5,a2
ffffffffc0201524:	a029                	j	ffffffffc020152e <default_alloc_pages+0x24>
        if (p->property >= n) {
ffffffffc0201526:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020152a:	00d77763          	bgeu	a4,a3,ffffffffc0201538 <default_alloc_pages+0x2e>
    return listelm->next;
ffffffffc020152e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201530:	fec79be3          	bne	a5,a2,ffffffffc0201526 <default_alloc_pages+0x1c>
        return NULL;
ffffffffc0201534:	4501                	li	a0,0
}
ffffffffc0201536:	8082                	ret
    __list_del(listelm->prev, listelm->next);
ffffffffc0201538:	6798                	ld	a4,8(a5)
    return listelm->prev;
ffffffffc020153a:	0007b803          	ld	a6,0(a5)
        if (page->property > n) {
ffffffffc020153e:	ff87a883          	lw	a7,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0201542:	fe878513          	addi	a0,a5,-24
    prev->next = next;
ffffffffc0201546:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020154a:	01073023          	sd	a6,0(a4)
        if (page->property > n) {
ffffffffc020154e:	02089713          	slli	a4,a7,0x20
ffffffffc0201552:	9301                	srli	a4,a4,0x20
            p->property = page->property - n;
ffffffffc0201554:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc0201558:	02e6fc63          	bgeu	a3,a4,ffffffffc0201590 <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc020155c:	00269713          	slli	a4,a3,0x2
ffffffffc0201560:	9736                	add	a4,a4,a3
ffffffffc0201562:	070e                	slli	a4,a4,0x3
ffffffffc0201564:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0201566:	406888bb          	subw	a7,a7,t1
ffffffffc020156a:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020156e:	4689                	li	a3,2
ffffffffc0201570:	00870593          	addi	a1,a4,8
ffffffffc0201574:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201578:	00883683          	ld	a3,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc020157c:	01870893          	addi	a7,a4,24
        nr_free -= n;
ffffffffc0201580:	4a0c                	lw	a1,16(a2)
    prev->next = next->prev = elm;
ffffffffc0201582:	0116b023          	sd	a7,0(a3)
ffffffffc0201586:	01183423          	sd	a7,8(a6)
    elm->next = next;
ffffffffc020158a:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc020158c:	01073c23          	sd	a6,24(a4)
ffffffffc0201590:	406585bb          	subw	a1,a1,t1
ffffffffc0201594:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201596:	5775                	li	a4,-3
ffffffffc0201598:	17c1                	addi	a5,a5,-16
ffffffffc020159a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020159e:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc02015a0:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02015a2:	00001697          	auipc	a3,0x1
ffffffffc02015a6:	52e68693          	addi	a3,a3,1326 # ffffffffc0202ad0 <etext+0xb98>
ffffffffc02015aa:	00001617          	auipc	a2,0x1
ffffffffc02015ae:	1ce60613          	addi	a2,a2,462 # ffffffffc0202778 <etext+0x840>
ffffffffc02015b2:	06200593          	li	a1,98
ffffffffc02015b6:	00001517          	auipc	a0,0x1
ffffffffc02015ba:	1da50513          	addi	a0,a0,474 # ffffffffc0202790 <etext+0x858>
default_alloc_pages(size_t n) {
ffffffffc02015be:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015c0:	e0dfe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc02015c4 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc02015c4:	1141                	addi	sp,sp,-16
ffffffffc02015c6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015c8:	c9e1                	beqz	a1,ffffffffc0201698 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc02015ca:	00259713          	slli	a4,a1,0x2
ffffffffc02015ce:	972e                	add	a4,a4,a1
ffffffffc02015d0:	070e                	slli	a4,a4,0x3
ffffffffc02015d2:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc02015d6:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc02015d8:	cf11                	beqz	a4,ffffffffc02015f4 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02015da:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc02015dc:	8b05                	andi	a4,a4,1
ffffffffc02015de:	cf49                	beqz	a4,ffffffffc0201678 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02015e0:	0007a823          	sw	zero,16(a5)
ffffffffc02015e4:	0007b423          	sd	zero,8(a5)
ffffffffc02015e8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02015ec:	02878793          	addi	a5,a5,40
ffffffffc02015f0:	fed795e3          	bne	a5,a3,ffffffffc02015da <default_init_memmap+0x16>
    base->property = n;
ffffffffc02015f4:	2581                	sext.w	a1,a1
ffffffffc02015f6:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02015f8:	4789                	li	a5,2
ffffffffc02015fa:	00850713          	addi	a4,a0,8
ffffffffc02015fe:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201602:	00005697          	auipc	a3,0x5
ffffffffc0201606:	a2668693          	addi	a3,a3,-1498 # ffffffffc0206028 <free_area>
ffffffffc020160a:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020160c:	669c                	ld	a5,8(a3)
ffffffffc020160e:	9f2d                	addw	a4,a4,a1
ffffffffc0201610:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201612:	04d78663          	beq	a5,a3,ffffffffc020165e <default_init_memmap+0x9a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201616:	fe878713          	addi	a4,a5,-24
ffffffffc020161a:	4581                	li	a1,0
ffffffffc020161c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201620:	00e56a63          	bltu	a0,a4,ffffffffc0201634 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0201624:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201626:	02d70263          	beq	a4,a3,ffffffffc020164a <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc020162a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020162c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201630:	fee57ae3          	bgeu	a0,a4,ffffffffc0201624 <default_init_memmap+0x60>
ffffffffc0201634:	c199                	beqz	a1,ffffffffc020163a <default_init_memmap+0x76>
ffffffffc0201636:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020163a:	6398                	ld	a4,0(a5)
}
ffffffffc020163c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020163e:	e390                	sd	a2,0(a5)
ffffffffc0201640:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201642:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201644:	ed18                	sd	a4,24(a0)
ffffffffc0201646:	0141                	addi	sp,sp,16
ffffffffc0201648:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020164a:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020164c:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc020164e:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201650:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201652:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201654:	00d70e63          	beq	a4,a3,ffffffffc0201670 <default_init_memmap+0xac>
ffffffffc0201658:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc020165a:	87ba                	mv	a5,a4
ffffffffc020165c:	bfc1                	j	ffffffffc020162c <default_init_memmap+0x68>
}
ffffffffc020165e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201660:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201664:	e398                	sd	a4,0(a5)
ffffffffc0201666:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201668:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020166a:	ed1c                	sd	a5,24(a0)
}
ffffffffc020166c:	0141                	addi	sp,sp,16
ffffffffc020166e:	8082                	ret
ffffffffc0201670:	60a2                	ld	ra,8(sp)
ffffffffc0201672:	e290                	sd	a2,0(a3)
ffffffffc0201674:	0141                	addi	sp,sp,16
ffffffffc0201676:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201678:	00001697          	auipc	a3,0x1
ffffffffc020167c:	48868693          	addi	a3,a3,1160 # ffffffffc0202b00 <etext+0xbc8>
ffffffffc0201680:	00001617          	auipc	a2,0x1
ffffffffc0201684:	0f860613          	addi	a2,a2,248 # ffffffffc0202778 <etext+0x840>
ffffffffc0201688:	04900593          	li	a1,73
ffffffffc020168c:	00001517          	auipc	a0,0x1
ffffffffc0201690:	10450513          	addi	a0,a0,260 # ffffffffc0202790 <etext+0x858>
ffffffffc0201694:	d39fe0ef          	jal	ffffffffc02003cc <__panic>
    assert(n > 0);
ffffffffc0201698:	00001697          	auipc	a3,0x1
ffffffffc020169c:	43868693          	addi	a3,a3,1080 # ffffffffc0202ad0 <etext+0xb98>
ffffffffc02016a0:	00001617          	auipc	a2,0x1
ffffffffc02016a4:	0d860613          	addi	a2,a2,216 # ffffffffc0202778 <etext+0x840>
ffffffffc02016a8:	04600593          	li	a1,70
ffffffffc02016ac:	00001517          	auipc	a0,0x1
ffffffffc02016b0:	0e450513          	addi	a0,a0,228 # ffffffffc0202790 <etext+0x858>
ffffffffc02016b4:	d19fe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc02016b8 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016b8:	100027f3          	csrr	a5,sstatus
ffffffffc02016bc:	8b89                	andi	a5,a5,2
ffffffffc02016be:	e799                	bnez	a5,ffffffffc02016cc <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016c0:	00005797          	auipc	a5,0x5
ffffffffc02016c4:	da87b783          	ld	a5,-600(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc02016c8:	6f9c                	ld	a5,24(a5)
ffffffffc02016ca:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc02016cc:	1141                	addi	sp,sp,-16
ffffffffc02016ce:	e406                	sd	ra,8(sp)
ffffffffc02016d0:	e022                	sd	s0,0(sp)
ffffffffc02016d2:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02016d4:	928ff0ef          	jal	ffffffffc02007fc <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02016d8:	00005797          	auipc	a5,0x5
ffffffffc02016dc:	d907b783          	ld	a5,-624(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc02016e0:	6f9c                	ld	a5,24(a5)
ffffffffc02016e2:	8522                	mv	a0,s0
ffffffffc02016e4:	9782                	jalr	a5
ffffffffc02016e6:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02016e8:	90eff0ef          	jal	ffffffffc02007f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02016ec:	60a2                	ld	ra,8(sp)
ffffffffc02016ee:	8522                	mv	a0,s0
ffffffffc02016f0:	6402                	ld	s0,0(sp)
ffffffffc02016f2:	0141                	addi	sp,sp,16
ffffffffc02016f4:	8082                	ret

ffffffffc02016f6 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016f6:	100027f3          	csrr	a5,sstatus
ffffffffc02016fa:	8b89                	andi	a5,a5,2
ffffffffc02016fc:	e799                	bnez	a5,ffffffffc020170a <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02016fe:	00005797          	auipc	a5,0x5
ffffffffc0201702:	d6a7b783          	ld	a5,-662(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201706:	739c                	ld	a5,32(a5)
ffffffffc0201708:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020170a:	1101                	addi	sp,sp,-32
ffffffffc020170c:	ec06                	sd	ra,24(sp)
ffffffffc020170e:	e822                	sd	s0,16(sp)
ffffffffc0201710:	e426                	sd	s1,8(sp)
ffffffffc0201712:	842a                	mv	s0,a0
ffffffffc0201714:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201716:	8e6ff0ef          	jal	ffffffffc02007fc <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020171a:	00005797          	auipc	a5,0x5
ffffffffc020171e:	d4e7b783          	ld	a5,-690(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201722:	739c                	ld	a5,32(a5)
ffffffffc0201724:	85a6                	mv	a1,s1
ffffffffc0201726:	8522                	mv	a0,s0
ffffffffc0201728:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020172a:	6442                	ld	s0,16(sp)
ffffffffc020172c:	60e2                	ld	ra,24(sp)
ffffffffc020172e:	64a2                	ld	s1,8(sp)
ffffffffc0201730:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201732:	8c4ff06f          	j	ffffffffc02007f6 <intr_enable>

ffffffffc0201736 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201736:	100027f3          	csrr	a5,sstatus
ffffffffc020173a:	8b89                	andi	a5,a5,2
ffffffffc020173c:	e799                	bnez	a5,ffffffffc020174a <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020173e:	00005797          	auipc	a5,0x5
ffffffffc0201742:	d2a7b783          	ld	a5,-726(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc0201746:	779c                	ld	a5,40(a5)
ffffffffc0201748:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc020174a:	1141                	addi	sp,sp,-16
ffffffffc020174c:	e406                	sd	ra,8(sp)
ffffffffc020174e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201750:	8acff0ef          	jal	ffffffffc02007fc <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201754:	00005797          	auipc	a5,0x5
ffffffffc0201758:	d147b783          	ld	a5,-748(a5) # ffffffffc0206468 <pmm_manager>
ffffffffc020175c:	779c                	ld	a5,40(a5)
ffffffffc020175e:	9782                	jalr	a5
ffffffffc0201760:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201762:	894ff0ef          	jal	ffffffffc02007f6 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201766:	60a2                	ld	ra,8(sp)
ffffffffc0201768:	8522                	mv	a0,s0
ffffffffc020176a:	6402                	ld	s0,0(sp)
ffffffffc020176c:	0141                	addi	sp,sp,16
ffffffffc020176e:	8082                	ret

ffffffffc0201770 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0201770:	00001797          	auipc	a5,0x1
ffffffffc0201774:	63078793          	addi	a5,a5,1584 # ffffffffc0202da0 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201778:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020177a:	7179                	addi	sp,sp,-48
ffffffffc020177c:	f406                	sd	ra,40(sp)
ffffffffc020177e:	f022                	sd	s0,32(sp)
ffffffffc0201780:	ec26                	sd	s1,24(sp)
ffffffffc0201782:	e052                	sd	s4,0(sp)
ffffffffc0201784:	e84a                	sd	s2,16(sp)
ffffffffc0201786:	e44e                	sd	s3,8(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0201788:	00005417          	auipc	s0,0x5
ffffffffc020178c:	ce040413          	addi	s0,s0,-800 # ffffffffc0206468 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201790:	00001517          	auipc	a0,0x1
ffffffffc0201794:	39850513          	addi	a0,a0,920 # ffffffffc0202b28 <etext+0xbf0>
    pmm_manager = &default_pmm_manager;
ffffffffc0201798:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020179a:	93ffe0ef          	jal	ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc020179e:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017a0:	00005497          	auipc	s1,0x5
ffffffffc02017a4:	ce048493          	addi	s1,s1,-800 # ffffffffc0206480 <va_pa_offset>
    pmm_manager->init();
ffffffffc02017a8:	679c                	ld	a5,8(a5)
ffffffffc02017aa:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017ac:	57f5                	li	a5,-3
ffffffffc02017ae:	07fa                	slli	a5,a5,0x1e
ffffffffc02017b0:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc02017b2:	830ff0ef          	jal	ffffffffc02007e2 <get_memory_base>
ffffffffc02017b6:	8a2a                	mv	s4,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017b8:	834ff0ef          	jal	ffffffffc02007ec <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017bc:	18050363          	beqz	a0,ffffffffc0201942 <pmm_init+0x1d2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017c0:	89aa                	mv	s3,a0
    cprintf("physcial memory map:\n");
ffffffffc02017c2:	00001517          	auipc	a0,0x1
ffffffffc02017c6:	3ae50513          	addi	a0,a0,942 # ffffffffc0202b70 <etext+0xc38>
ffffffffc02017ca:	90ffe0ef          	jal	ffffffffc02000d8 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017ce:	013a0933          	add	s2,s4,s3
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02017d2:	fff90693          	addi	a3,s2,-1
ffffffffc02017d6:	8652                	mv	a2,s4
ffffffffc02017d8:	85ce                	mv	a1,s3
ffffffffc02017da:	00001517          	auipc	a0,0x1
ffffffffc02017de:	3ae50513          	addi	a0,a0,942 # ffffffffc0202b88 <etext+0xc50>
ffffffffc02017e2:	8f7fe0ef          	jal	ffffffffc02000d8 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02017e6:	c8000737          	lui	a4,0xc8000
ffffffffc02017ea:	87ca                	mv	a5,s2
ffffffffc02017ec:	0f276863          	bltu	a4,s2,ffffffffc02018dc <pmm_init+0x16c>
ffffffffc02017f0:	00006697          	auipc	a3,0x6
ffffffffc02017f4:	caf68693          	addi	a3,a3,-849 # ffffffffc020749f <end+0xfff>
ffffffffc02017f8:	777d                	lui	a4,0xfffff
ffffffffc02017fa:	8ef9                	and	a3,a3,a4
    npage = maxpa / PGSIZE;
ffffffffc02017fc:	83b1                	srli	a5,a5,0xc
ffffffffc02017fe:	00005817          	auipc	a6,0x5
ffffffffc0201802:	c8a80813          	addi	a6,a6,-886 # ffffffffc0206488 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201806:	00005597          	auipc	a1,0x5
ffffffffc020180a:	c8a58593          	addi	a1,a1,-886 # ffffffffc0206490 <pages>
    npage = maxpa / PGSIZE;
ffffffffc020180e:	00f83023          	sd	a5,0(a6)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201812:	e194                	sd	a3,0(a1)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201814:	00080637          	lui	a2,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201818:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020181a:	04c78463          	beq	a5,a2,ffffffffc0201862 <pmm_init+0xf2>
ffffffffc020181e:	4785                	li	a5,1
ffffffffc0201820:	00868713          	addi	a4,a3,8
ffffffffc0201824:	40f7302f          	amoor.d	zero,a5,(a4)
ffffffffc0201828:	00083783          	ld	a5,0(a6)
ffffffffc020182c:	4705                	li	a4,1
ffffffffc020182e:	02800693          	li	a3,40
ffffffffc0201832:	40c78633          	sub	a2,a5,a2
ffffffffc0201836:	4885                	li	a7,1
ffffffffc0201838:	fff80537          	lui	a0,0xfff80
ffffffffc020183c:	02c77063          	bgeu	a4,a2,ffffffffc020185c <pmm_init+0xec>
        SetPageReserved(pages + i);
ffffffffc0201840:	619c                	ld	a5,0(a1)
ffffffffc0201842:	97b6                	add	a5,a5,a3
ffffffffc0201844:	07a1                	addi	a5,a5,8
ffffffffc0201846:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020184a:	00083783          	ld	a5,0(a6)
ffffffffc020184e:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0x3fdf8b61>
ffffffffc0201850:	02868693          	addi	a3,a3,40
ffffffffc0201854:	00a78633          	add	a2,a5,a0
ffffffffc0201858:	fec764e3          	bltu	a4,a2,ffffffffc0201840 <pmm_init+0xd0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020185c:	0005b883          	ld	a7,0(a1)
ffffffffc0201860:	86c6                	mv	a3,a7
ffffffffc0201862:	00279713          	slli	a4,a5,0x2
ffffffffc0201866:	973e                	add	a4,a4,a5
ffffffffc0201868:	fec00637          	lui	a2,0xfec00
ffffffffc020186c:	070e                	slli	a4,a4,0x3
ffffffffc020186e:	96b2                	add	a3,a3,a2
ffffffffc0201870:	96ba                	add	a3,a3,a4
ffffffffc0201872:	c0200737          	lui	a4,0xc0200
ffffffffc0201876:	0ae6ea63          	bltu	a3,a4,ffffffffc020192a <pmm_init+0x1ba>
ffffffffc020187a:	6090                	ld	a2,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020187c:	777d                	lui	a4,0xfffff
ffffffffc020187e:	00e97933          	and	s2,s2,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201882:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc0201884:	0526ef63          	bltu	a3,s2,ffffffffc02018e2 <pmm_init+0x172>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201888:	601c                	ld	a5,0(s0)
ffffffffc020188a:	7b9c                	ld	a5,48(a5)
ffffffffc020188c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020188e:	00001517          	auipc	a0,0x1
ffffffffc0201892:	38250513          	addi	a0,a0,898 # ffffffffc0202c10 <etext+0xcd8>
ffffffffc0201896:	843fe0ef          	jal	ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020189a:	00003597          	auipc	a1,0x3
ffffffffc020189e:	76658593          	addi	a1,a1,1894 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018a2:	00005797          	auipc	a5,0x5
ffffffffc02018a6:	bcb7bb23          	sd	a1,-1066(a5) # ffffffffc0206478 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018aa:	c02007b7          	lui	a5,0xc0200
ffffffffc02018ae:	0af5e663          	bltu	a1,a5,ffffffffc020195a <pmm_init+0x1ea>
ffffffffc02018b2:	609c                	ld	a5,0(s1)
}
ffffffffc02018b4:	7402                	ld	s0,32(sp)
ffffffffc02018b6:	70a2                	ld	ra,40(sp)
ffffffffc02018b8:	64e2                	ld	s1,24(sp)
ffffffffc02018ba:	6942                	ld	s2,16(sp)
ffffffffc02018bc:	69a2                	ld	s3,8(sp)
ffffffffc02018be:	6a02                	ld	s4,0(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc02018c0:	40f586b3          	sub	a3,a1,a5
ffffffffc02018c4:	00005797          	auipc	a5,0x5
ffffffffc02018c8:	bad7b623          	sd	a3,-1108(a5) # ffffffffc0206470 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018cc:	00001517          	auipc	a0,0x1
ffffffffc02018d0:	36450513          	addi	a0,a0,868 # ffffffffc0202c30 <etext+0xcf8>
ffffffffc02018d4:	8636                	mv	a2,a3
}
ffffffffc02018d6:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018d8:	801fe06f          	j	ffffffffc02000d8 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02018dc:	c80007b7          	lui	a5,0xc8000
ffffffffc02018e0:	bf01                	j	ffffffffc02017f0 <pmm_init+0x80>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02018e2:	6605                	lui	a2,0x1
ffffffffc02018e4:	167d                	addi	a2,a2,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc02018e6:	96b2                	add	a3,a3,a2
ffffffffc02018e8:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02018ea:	00c6d713          	srli	a4,a3,0xc
ffffffffc02018ee:	02f77263          	bgeu	a4,a5,ffffffffc0201912 <pmm_init+0x1a2>
    pmm_manager->init_memmap(base, n);
ffffffffc02018f2:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02018f4:	fff807b7          	lui	a5,0xfff80
ffffffffc02018f8:	97ba                	add	a5,a5,a4
ffffffffc02018fa:	00279513          	slli	a0,a5,0x2
ffffffffc02018fe:	953e                	add	a0,a0,a5
ffffffffc0201900:	6a1c                	ld	a5,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201902:	40d90933          	sub	s2,s2,a3
ffffffffc0201906:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201908:	00c95593          	srli	a1,s2,0xc
ffffffffc020190c:	9546                	add	a0,a0,a7
ffffffffc020190e:	9782                	jalr	a5
}
ffffffffc0201910:	bfa5                	j	ffffffffc0201888 <pmm_init+0x118>
        panic("pa2page called with invalid pa");
ffffffffc0201912:	00001617          	auipc	a2,0x1
ffffffffc0201916:	2ce60613          	addi	a2,a2,718 # ffffffffc0202be0 <etext+0xca8>
ffffffffc020191a:	06b00593          	li	a1,107
ffffffffc020191e:	00001517          	auipc	a0,0x1
ffffffffc0201922:	2e250513          	addi	a0,a0,738 # ffffffffc0202c00 <etext+0xcc8>
ffffffffc0201926:	aa7fe0ef          	jal	ffffffffc02003cc <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020192a:	00001617          	auipc	a2,0x1
ffffffffc020192e:	28e60613          	addi	a2,a2,654 # ffffffffc0202bb8 <etext+0xc80>
ffffffffc0201932:	07100593          	li	a1,113
ffffffffc0201936:	00001517          	auipc	a0,0x1
ffffffffc020193a:	22a50513          	addi	a0,a0,554 # ffffffffc0202b60 <etext+0xc28>
ffffffffc020193e:	a8ffe0ef          	jal	ffffffffc02003cc <__panic>
        panic("DTB memory info not available");
ffffffffc0201942:	00001617          	auipc	a2,0x1
ffffffffc0201946:	1fe60613          	addi	a2,a2,510 # ffffffffc0202b40 <etext+0xc08>
ffffffffc020194a:	05a00593          	li	a1,90
ffffffffc020194e:	00001517          	auipc	a0,0x1
ffffffffc0201952:	21250513          	addi	a0,a0,530 # ffffffffc0202b60 <etext+0xc28>
ffffffffc0201956:	a77fe0ef          	jal	ffffffffc02003cc <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020195a:	86ae                	mv	a3,a1
ffffffffc020195c:	00001617          	auipc	a2,0x1
ffffffffc0201960:	25c60613          	addi	a2,a2,604 # ffffffffc0202bb8 <etext+0xc80>
ffffffffc0201964:	08c00593          	li	a1,140
ffffffffc0201968:	00001517          	auipc	a0,0x1
ffffffffc020196c:	1f850513          	addi	a0,a0,504 # ffffffffc0202b60 <etext+0xc28>
ffffffffc0201970:	a5dfe0ef          	jal	ffffffffc02003cc <__panic>

ffffffffc0201974 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201974:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201978:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020197a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020197e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201980:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201984:	f022                	sd	s0,32(sp)
ffffffffc0201986:	ec26                	sd	s1,24(sp)
ffffffffc0201988:	e84a                	sd	s2,16(sp)
ffffffffc020198a:	f406                	sd	ra,40(sp)
ffffffffc020198c:	84aa                	mv	s1,a0
ffffffffc020198e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201990:	fff7041b          	addiw	s0,a4,-1 # ffffffffffffefff <end+0x3fdf8b5f>
    unsigned mod = do_div(result, base);
ffffffffc0201994:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201996:	05067063          	bgeu	a2,a6,ffffffffc02019d6 <printnum+0x62>
ffffffffc020199a:	e44e                	sd	s3,8(sp)
ffffffffc020199c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020199e:	4785                	li	a5,1
ffffffffc02019a0:	00e7d763          	bge	a5,a4,ffffffffc02019ae <printnum+0x3a>
            putch(padc, putdat);
ffffffffc02019a4:	85ca                	mv	a1,s2
ffffffffc02019a6:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc02019a8:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019aa:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019ac:	fc65                	bnez	s0,ffffffffc02019a4 <printnum+0x30>
ffffffffc02019ae:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019b0:	1a02                	slli	s4,s4,0x20
ffffffffc02019b2:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019b6:	00001797          	auipc	a5,0x1
ffffffffc02019ba:	2ba78793          	addi	a5,a5,698 # ffffffffc0202c70 <etext+0xd38>
ffffffffc02019be:	97d2                	add	a5,a5,s4
}
ffffffffc02019c0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019c2:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02019c6:	70a2                	ld	ra,40(sp)
ffffffffc02019c8:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019ca:	85ca                	mv	a1,s2
ffffffffc02019cc:	87a6                	mv	a5,s1
}
ffffffffc02019ce:	6942                	ld	s2,16(sp)
ffffffffc02019d0:	64e2                	ld	s1,24(sp)
ffffffffc02019d2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019d4:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019d6:	03065633          	divu	a2,a2,a6
ffffffffc02019da:	8722                	mv	a4,s0
ffffffffc02019dc:	f99ff0ef          	jal	ffffffffc0201974 <printnum>
ffffffffc02019e0:	bfc1                	j	ffffffffc02019b0 <printnum+0x3c>

ffffffffc02019e2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019e2:	7119                	addi	sp,sp,-128
ffffffffc02019e4:	f4a6                	sd	s1,104(sp)
ffffffffc02019e6:	f0ca                	sd	s2,96(sp)
ffffffffc02019e8:	ecce                	sd	s3,88(sp)
ffffffffc02019ea:	e8d2                	sd	s4,80(sp)
ffffffffc02019ec:	e4d6                	sd	s5,72(sp)
ffffffffc02019ee:	e0da                	sd	s6,64(sp)
ffffffffc02019f0:	f862                	sd	s8,48(sp)
ffffffffc02019f2:	fc86                	sd	ra,120(sp)
ffffffffc02019f4:	f8a2                	sd	s0,112(sp)
ffffffffc02019f6:	fc5e                	sd	s7,56(sp)
ffffffffc02019f8:	f466                	sd	s9,40(sp)
ffffffffc02019fa:	f06a                	sd	s10,32(sp)
ffffffffc02019fc:	ec6e                	sd	s11,24(sp)
ffffffffc02019fe:	892a                	mv	s2,a0
ffffffffc0201a00:	84ae                	mv	s1,a1
ffffffffc0201a02:	8c32                	mv	s8,a2
ffffffffc0201a04:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a06:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a0a:	05500b13          	li	s6,85
ffffffffc0201a0e:	00001a97          	auipc	s5,0x1
ffffffffc0201a12:	3caa8a93          	addi	s5,s5,970 # ffffffffc0202dd8 <default_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a16:	000c4503          	lbu	a0,0(s8)
ffffffffc0201a1a:	001c0413          	addi	s0,s8,1
ffffffffc0201a1e:	01350a63          	beq	a0,s3,ffffffffc0201a32 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0201a22:	cd0d                	beqz	a0,ffffffffc0201a5c <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0201a24:	85a6                	mv	a1,s1
ffffffffc0201a26:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a28:	00044503          	lbu	a0,0(s0)
ffffffffc0201a2c:	0405                	addi	s0,s0,1
ffffffffc0201a2e:	ff351ae3          	bne	a0,s3,ffffffffc0201a22 <vprintfmt+0x40>
        char padc = ' ';
ffffffffc0201a32:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc0201a36:	4b81                	li	s7,0
ffffffffc0201a38:	4601                	li	a2,0
        width = precision = -1;
ffffffffc0201a3a:	5d7d                	li	s10,-1
ffffffffc0201a3c:	5cfd                	li	s9,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a3e:	00044683          	lbu	a3,0(s0)
ffffffffc0201a42:	00140c13          	addi	s8,s0,1
ffffffffc0201a46:	fdd6859b          	addiw	a1,a3,-35
ffffffffc0201a4a:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a4e:	02bb6663          	bltu	s6,a1,ffffffffc0201a7a <vprintfmt+0x98>
ffffffffc0201a52:	058a                	slli	a1,a1,0x2
ffffffffc0201a54:	95d6                	add	a1,a1,s5
ffffffffc0201a56:	4198                	lw	a4,0(a1)
ffffffffc0201a58:	9756                	add	a4,a4,s5
ffffffffc0201a5a:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a5c:	70e6                	ld	ra,120(sp)
ffffffffc0201a5e:	7446                	ld	s0,112(sp)
ffffffffc0201a60:	74a6                	ld	s1,104(sp)
ffffffffc0201a62:	7906                	ld	s2,96(sp)
ffffffffc0201a64:	69e6                	ld	s3,88(sp)
ffffffffc0201a66:	6a46                	ld	s4,80(sp)
ffffffffc0201a68:	6aa6                	ld	s5,72(sp)
ffffffffc0201a6a:	6b06                	ld	s6,64(sp)
ffffffffc0201a6c:	7be2                	ld	s7,56(sp)
ffffffffc0201a6e:	7c42                	ld	s8,48(sp)
ffffffffc0201a70:	7ca2                	ld	s9,40(sp)
ffffffffc0201a72:	7d02                	ld	s10,32(sp)
ffffffffc0201a74:	6de2                	ld	s11,24(sp)
ffffffffc0201a76:	6109                	addi	sp,sp,128
ffffffffc0201a78:	8082                	ret
            putch('%', putdat);
ffffffffc0201a7a:	85a6                	mv	a1,s1
ffffffffc0201a7c:	02500513          	li	a0,37
ffffffffc0201a80:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a82:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201a86:	02500793          	li	a5,37
ffffffffc0201a8a:	8c22                	mv	s8,s0
ffffffffc0201a8c:	f8f705e3          	beq	a4,a5,ffffffffc0201a16 <vprintfmt+0x34>
ffffffffc0201a90:	02500713          	li	a4,37
ffffffffc0201a94:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201a98:	1c7d                	addi	s8,s8,-1
ffffffffc0201a9a:	fee79de3          	bne	a5,a4,ffffffffc0201a94 <vprintfmt+0xb2>
ffffffffc0201a9e:	bfa5                	j	ffffffffc0201a16 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc0201aa0:	00144783          	lbu	a5,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201aa4:	4725                	li	a4,9
                precision = precision * 10 + ch - '0';
ffffffffc0201aa6:	fd068d1b          	addiw	s10,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201aaa:	fd07859b          	addiw	a1,a5,-48
                ch = *fmt;
ffffffffc0201aae:	0007869b          	sext.w	a3,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ab2:	8462                	mv	s0,s8
                if (ch < '0' || ch > '9') {
ffffffffc0201ab4:	02b76563          	bltu	a4,a1,ffffffffc0201ade <vprintfmt+0xfc>
ffffffffc0201ab8:	4525                	li	a0,9
                ch = *fmt;
ffffffffc0201aba:	00144783          	lbu	a5,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201abe:	002d171b          	slliw	a4,s10,0x2
ffffffffc0201ac2:	01a7073b          	addw	a4,a4,s10
ffffffffc0201ac6:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201aca:	9f35                	addw	a4,a4,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201acc:	fd07859b          	addiw	a1,a5,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201ad0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201ad2:	fd070d1b          	addiw	s10,a4,-48
                ch = *fmt;
ffffffffc0201ad6:	0007869b          	sext.w	a3,a5
                if (ch < '0' || ch > '9') {
ffffffffc0201ada:	feb570e3          	bgeu	a0,a1,ffffffffc0201aba <vprintfmt+0xd8>
            if (width < 0)
ffffffffc0201ade:	f60cd0e3          	bgez	s9,ffffffffc0201a3e <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc0201ae2:	8cea                	mv	s9,s10
ffffffffc0201ae4:	5d7d                	li	s10,-1
ffffffffc0201ae6:	bfa1                	j	ffffffffc0201a3e <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae8:	8db6                	mv	s11,a3
ffffffffc0201aea:	8462                	mv	s0,s8
ffffffffc0201aec:	bf89                	j	ffffffffc0201a3e <vprintfmt+0x5c>
ffffffffc0201aee:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc0201af0:	4b85                	li	s7,1
            goto reswitch;
ffffffffc0201af2:	b7b1                	j	ffffffffc0201a3e <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc0201af4:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201af6:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201afa:	00c7c463          	blt	a5,a2,ffffffffc0201b02 <vprintfmt+0x120>
    else if (lflag) {
ffffffffc0201afe:	1a060163          	beqz	a2,ffffffffc0201ca0 <vprintfmt+0x2be>
        return va_arg(*ap, unsigned long);
ffffffffc0201b02:	000a3603          	ld	a2,0(s4)
ffffffffc0201b06:	46c1                	li	a3,16
ffffffffc0201b08:	8a3a                	mv	s4,a4
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201b0a:	000d879b          	sext.w	a5,s11
ffffffffc0201b0e:	8766                	mv	a4,s9
ffffffffc0201b10:	85a6                	mv	a1,s1
ffffffffc0201b12:	854a                	mv	a0,s2
ffffffffc0201b14:	e61ff0ef          	jal	ffffffffc0201974 <printnum>
            break;
ffffffffc0201b18:	bdfd                	j	ffffffffc0201a16 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b1a:	000a2503          	lw	a0,0(s4)
ffffffffc0201b1e:	85a6                	mv	a1,s1
ffffffffc0201b20:	0a21                	addi	s4,s4,8
ffffffffc0201b22:	9902                	jalr	s2
            break;
ffffffffc0201b24:	bdcd                	j	ffffffffc0201a16 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201b26:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201b28:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201b2c:	00c7c463          	blt	a5,a2,ffffffffc0201b34 <vprintfmt+0x152>
    else if (lflag) {
ffffffffc0201b30:	16060363          	beqz	a2,ffffffffc0201c96 <vprintfmt+0x2b4>
        return va_arg(*ap, unsigned long);
ffffffffc0201b34:	000a3603          	ld	a2,0(s4)
ffffffffc0201b38:	46a9                	li	a3,10
ffffffffc0201b3a:	8a3a                	mv	s4,a4
ffffffffc0201b3c:	b7f9                	j	ffffffffc0201b0a <vprintfmt+0x128>
            putch('0', putdat);
ffffffffc0201b3e:	85a6                	mv	a1,s1
ffffffffc0201b40:	03000513          	li	a0,48
ffffffffc0201b44:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b46:	85a6                	mv	a1,s1
ffffffffc0201b48:	07800513          	li	a0,120
ffffffffc0201b4c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b4e:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc0201b52:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b54:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b56:	bf55                	j	ffffffffc0201b0a <vprintfmt+0x128>
            putch(ch, putdat);
ffffffffc0201b58:	85a6                	mv	a1,s1
ffffffffc0201b5a:	02500513          	li	a0,37
ffffffffc0201b5e:	9902                	jalr	s2
            break;
ffffffffc0201b60:	bd5d                	j	ffffffffc0201a16 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc0201b62:	000a2d03          	lw	s10,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b66:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0201b68:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0201b6a:	bf95                	j	ffffffffc0201ade <vprintfmt+0xfc>
    if (lflag >= 2) {
ffffffffc0201b6c:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201b6e:	008a0713          	addi	a4,s4,8
    if (lflag >= 2) {
ffffffffc0201b72:	00c7c463          	blt	a5,a2,ffffffffc0201b7a <vprintfmt+0x198>
    else if (lflag) {
ffffffffc0201b76:	10060b63          	beqz	a2,ffffffffc0201c8c <vprintfmt+0x2aa>
        return va_arg(*ap, unsigned long);
ffffffffc0201b7a:	000a3603          	ld	a2,0(s4)
ffffffffc0201b7e:	46a1                	li	a3,8
ffffffffc0201b80:	8a3a                	mv	s4,a4
ffffffffc0201b82:	b761                	j	ffffffffc0201b0a <vprintfmt+0x128>
            if (width < 0)
ffffffffc0201b84:	fffcc793          	not	a5,s9
ffffffffc0201b88:	97fd                	srai	a5,a5,0x3f
ffffffffc0201b8a:	00fcf7b3          	and	a5,s9,a5
ffffffffc0201b8e:	00078c9b          	sext.w	s9,a5
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b92:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201b94:	b56d                	j	ffffffffc0201a3e <vprintfmt+0x5c>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b96:	000a3403          	ld	s0,0(s4)
ffffffffc0201b9a:	008a0793          	addi	a5,s4,8
ffffffffc0201b9e:	e43e                	sd	a5,8(sp)
ffffffffc0201ba0:	12040063          	beqz	s0,ffffffffc0201cc0 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc0201ba4:	0d905963          	blez	s9,ffffffffc0201c76 <vprintfmt+0x294>
ffffffffc0201ba8:	02d00793          	li	a5,45
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bac:	00140a13          	addi	s4,s0,1
            if (width > 0 && padc != '-') {
ffffffffc0201bb0:	12fd9763          	bne	s11,a5,ffffffffc0201cde <vprintfmt+0x2fc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bb4:	00044783          	lbu	a5,0(s0)
ffffffffc0201bb8:	0007851b          	sext.w	a0,a5
ffffffffc0201bbc:	cb9d                	beqz	a5,ffffffffc0201bf2 <vprintfmt+0x210>
ffffffffc0201bbe:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bc0:	05e00d93          	li	s11,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bc4:	000d4563          	bltz	s10,ffffffffc0201bce <vprintfmt+0x1ec>
ffffffffc0201bc8:	3d7d                	addiw	s10,s10,-1
ffffffffc0201bca:	028d0263          	beq	s10,s0,ffffffffc0201bee <vprintfmt+0x20c>
                    putch('?', putdat);
ffffffffc0201bce:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bd0:	0c0b8d63          	beqz	s7,ffffffffc0201caa <vprintfmt+0x2c8>
ffffffffc0201bd4:	3781                	addiw	a5,a5,-32
ffffffffc0201bd6:	0cfdfa63          	bgeu	s11,a5,ffffffffc0201caa <vprintfmt+0x2c8>
                    putch('?', putdat);
ffffffffc0201bda:	03f00513          	li	a0,63
ffffffffc0201bde:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201be0:	000a4783          	lbu	a5,0(s4)
ffffffffc0201be4:	3cfd                	addiw	s9,s9,-1 # feffff <kern_entry-0xffffffffbf210001>
ffffffffc0201be6:	0a05                	addi	s4,s4,1
ffffffffc0201be8:	0007851b          	sext.w	a0,a5
ffffffffc0201bec:	ffe1                	bnez	a5,ffffffffc0201bc4 <vprintfmt+0x1e2>
            for (; width > 0; width --) {
ffffffffc0201bee:	01905963          	blez	s9,ffffffffc0201c00 <vprintfmt+0x21e>
                putch(' ', putdat);
ffffffffc0201bf2:	85a6                	mv	a1,s1
ffffffffc0201bf4:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc0201bf8:	3cfd                	addiw	s9,s9,-1
                putch(' ', putdat);
ffffffffc0201bfa:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bfc:	fe0c9be3          	bnez	s9,ffffffffc0201bf2 <vprintfmt+0x210>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201c00:	6a22                	ld	s4,8(sp)
ffffffffc0201c02:	bd11                	j	ffffffffc0201a16 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0201c04:	4785                	li	a5,1
            precision = va_arg(ap, int);
ffffffffc0201c06:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201c0a:	00c7c363          	blt	a5,a2,ffffffffc0201c10 <vprintfmt+0x22e>
    else if (lflag) {
ffffffffc0201c0e:	ce25                	beqz	a2,ffffffffc0201c86 <vprintfmt+0x2a4>
        return va_arg(*ap, long);
ffffffffc0201c10:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201c14:	08044d63          	bltz	s0,ffffffffc0201cae <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc0201c18:	8622                	mv	a2,s0
ffffffffc0201c1a:	8a5e                	mv	s4,s7
ffffffffc0201c1c:	46a9                	li	a3,10
ffffffffc0201c1e:	b5f5                	j	ffffffffc0201b0a <vprintfmt+0x128>
            if (err < 0) {
ffffffffc0201c20:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c24:	4619                	li	a2,6
            if (err < 0) {
ffffffffc0201c26:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0201c2a:	8fb9                	xor	a5,a5,a4
ffffffffc0201c2c:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c30:	02d64663          	blt	a2,a3,ffffffffc0201c5c <vprintfmt+0x27a>
ffffffffc0201c34:	00369713          	slli	a4,a3,0x3
ffffffffc0201c38:	00001797          	auipc	a5,0x1
ffffffffc0201c3c:	2f878793          	addi	a5,a5,760 # ffffffffc0202f30 <error_string>
ffffffffc0201c40:	97ba                	add	a5,a5,a4
ffffffffc0201c42:	639c                	ld	a5,0(a5)
ffffffffc0201c44:	cf81                	beqz	a5,ffffffffc0201c5c <vprintfmt+0x27a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c46:	86be                	mv	a3,a5
ffffffffc0201c48:	00001617          	auipc	a2,0x1
ffffffffc0201c4c:	05860613          	addi	a2,a2,88 # ffffffffc0202ca0 <etext+0xd68>
ffffffffc0201c50:	85a6                	mv	a1,s1
ffffffffc0201c52:	854a                	mv	a0,s2
ffffffffc0201c54:	0e8000ef          	jal	ffffffffc0201d3c <printfmt>
            err = va_arg(ap, int);
ffffffffc0201c58:	0a21                	addi	s4,s4,8
ffffffffc0201c5a:	bb75                	j	ffffffffc0201a16 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c5c:	00001617          	auipc	a2,0x1
ffffffffc0201c60:	03460613          	addi	a2,a2,52 # ffffffffc0202c90 <etext+0xd58>
ffffffffc0201c64:	85a6                	mv	a1,s1
ffffffffc0201c66:	854a                	mv	a0,s2
ffffffffc0201c68:	0d4000ef          	jal	ffffffffc0201d3c <printfmt>
            err = va_arg(ap, int);
ffffffffc0201c6c:	0a21                	addi	s4,s4,8
ffffffffc0201c6e:	b365                	j	ffffffffc0201a16 <vprintfmt+0x34>
            lflag ++;
ffffffffc0201c70:	2605                	addiw	a2,a2,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c72:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc0201c74:	b3e9                	j	ffffffffc0201a3e <vprintfmt+0x5c>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c76:	00044783          	lbu	a5,0(s0)
ffffffffc0201c7a:	0007851b          	sext.w	a0,a5
ffffffffc0201c7e:	d3c9                	beqz	a5,ffffffffc0201c00 <vprintfmt+0x21e>
ffffffffc0201c80:	00140a13          	addi	s4,s0,1
ffffffffc0201c84:	bf2d                	j	ffffffffc0201bbe <vprintfmt+0x1dc>
        return va_arg(*ap, int);
ffffffffc0201c86:	000a2403          	lw	s0,0(s4)
ffffffffc0201c8a:	b769                	j	ffffffffc0201c14 <vprintfmt+0x232>
        return va_arg(*ap, unsigned int);
ffffffffc0201c8c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c90:	46a1                	li	a3,8
ffffffffc0201c92:	8a3a                	mv	s4,a4
ffffffffc0201c94:	bd9d                	j	ffffffffc0201b0a <vprintfmt+0x128>
ffffffffc0201c96:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c9a:	46a9                	li	a3,10
ffffffffc0201c9c:	8a3a                	mv	s4,a4
ffffffffc0201c9e:	b5b5                	j	ffffffffc0201b0a <vprintfmt+0x128>
ffffffffc0201ca0:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ca4:	46c1                	li	a3,16
ffffffffc0201ca6:	8a3a                	mv	s4,a4
ffffffffc0201ca8:	b58d                	j	ffffffffc0201b0a <vprintfmt+0x128>
                    putch(ch, putdat);
ffffffffc0201caa:	9902                	jalr	s2
ffffffffc0201cac:	bf15                	j	ffffffffc0201be0 <vprintfmt+0x1fe>
                putch('-', putdat);
ffffffffc0201cae:	85a6                	mv	a1,s1
ffffffffc0201cb0:	02d00513          	li	a0,45
ffffffffc0201cb4:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201cb6:	40800633          	neg	a2,s0
ffffffffc0201cba:	8a5e                	mv	s4,s7
ffffffffc0201cbc:	46a9                	li	a3,10
ffffffffc0201cbe:	b5b1                	j	ffffffffc0201b0a <vprintfmt+0x128>
            if (width > 0 && padc != '-') {
ffffffffc0201cc0:	01905663          	blez	s9,ffffffffc0201ccc <vprintfmt+0x2ea>
ffffffffc0201cc4:	02d00793          	li	a5,45
ffffffffc0201cc8:	04fd9263          	bne	s11,a5,ffffffffc0201d0c <vprintfmt+0x32a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ccc:	02800793          	li	a5,40
ffffffffc0201cd0:	00001a17          	auipc	s4,0x1
ffffffffc0201cd4:	fb9a0a13          	addi	s4,s4,-71 # ffffffffc0202c89 <etext+0xd51>
ffffffffc0201cd8:	02800513          	li	a0,40
ffffffffc0201cdc:	b5cd                	j	ffffffffc0201bbe <vprintfmt+0x1dc>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cde:	85ea                	mv	a1,s10
ffffffffc0201ce0:	8522                	mv	a0,s0
ffffffffc0201ce2:	1b2000ef          	jal	ffffffffc0201e94 <strnlen>
ffffffffc0201ce6:	40ac8cbb          	subw	s9,s9,a0
ffffffffc0201cea:	01905963          	blez	s9,ffffffffc0201cfc <vprintfmt+0x31a>
                    putch(padc, putdat);
ffffffffc0201cee:	2d81                	sext.w	s11,s11
ffffffffc0201cf0:	85a6                	mv	a1,s1
ffffffffc0201cf2:	856e                	mv	a0,s11
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf4:	3cfd                	addiw	s9,s9,-1
                    putch(padc, putdat);
ffffffffc0201cf6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf8:	fe0c9ce3          	bnez	s9,ffffffffc0201cf0 <vprintfmt+0x30e>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cfc:	00044783          	lbu	a5,0(s0)
ffffffffc0201d00:	0007851b          	sext.w	a0,a5
ffffffffc0201d04:	ea079de3          	bnez	a5,ffffffffc0201bbe <vprintfmt+0x1dc>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d08:	6a22                	ld	s4,8(sp)
ffffffffc0201d0a:	b331                	j	ffffffffc0201a16 <vprintfmt+0x34>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d0c:	85ea                	mv	a1,s10
ffffffffc0201d0e:	00001517          	auipc	a0,0x1
ffffffffc0201d12:	f7a50513          	addi	a0,a0,-134 # ffffffffc0202c88 <etext+0xd50>
ffffffffc0201d16:	17e000ef          	jal	ffffffffc0201e94 <strnlen>
ffffffffc0201d1a:	40ac8cbb          	subw	s9,s9,a0
                p = "(null)";
ffffffffc0201d1e:	00001417          	auipc	s0,0x1
ffffffffc0201d22:	f6a40413          	addi	s0,s0,-150 # ffffffffc0202c88 <etext+0xd50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d26:	00001a17          	auipc	s4,0x1
ffffffffc0201d2a:	f63a0a13          	addi	s4,s4,-157 # ffffffffc0202c89 <etext+0xd51>
ffffffffc0201d2e:	02800793          	li	a5,40
ffffffffc0201d32:	02800513          	li	a0,40
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d36:	fb904ce3          	bgtz	s9,ffffffffc0201cee <vprintfmt+0x30c>
ffffffffc0201d3a:	b551                	j	ffffffffc0201bbe <vprintfmt+0x1dc>

ffffffffc0201d3c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d3c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d3e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d42:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d44:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d46:	ec06                	sd	ra,24(sp)
ffffffffc0201d48:	f83a                	sd	a4,48(sp)
ffffffffc0201d4a:	fc3e                	sd	a5,56(sp)
ffffffffc0201d4c:	e0c2                	sd	a6,64(sp)
ffffffffc0201d4e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d50:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d52:	c91ff0ef          	jal	ffffffffc02019e2 <vprintfmt>
}
ffffffffc0201d56:	60e2                	ld	ra,24(sp)
ffffffffc0201d58:	6161                	addi	sp,sp,80
ffffffffc0201d5a:	8082                	ret

ffffffffc0201d5c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d5c:	715d                	addi	sp,sp,-80
ffffffffc0201d5e:	e486                	sd	ra,72(sp)
ffffffffc0201d60:	e0a2                	sd	s0,64(sp)
ffffffffc0201d62:	fc26                	sd	s1,56(sp)
ffffffffc0201d64:	f84a                	sd	s2,48(sp)
ffffffffc0201d66:	f44e                	sd	s3,40(sp)
ffffffffc0201d68:	f052                	sd	s4,32(sp)
ffffffffc0201d6a:	ec56                	sd	s5,24(sp)
ffffffffc0201d6c:	e85a                	sd	s6,16(sp)
    if (prompt != NULL) {
ffffffffc0201d6e:	c901                	beqz	a0,ffffffffc0201d7e <readline+0x22>
ffffffffc0201d70:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d72:	00001517          	auipc	a0,0x1
ffffffffc0201d76:	f2e50513          	addi	a0,a0,-210 # ffffffffc0202ca0 <etext+0xd68>
ffffffffc0201d7a:	b5efe0ef          	jal	ffffffffc02000d8 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc0201d7e:	4401                	li	s0,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d80:	44fd                	li	s1,31
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d82:	4921                	li	s2,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d84:	4a29                	li	s4,10
ffffffffc0201d86:	4ab5                	li	s5,13
            buf[i ++] = c;
ffffffffc0201d88:	00004b17          	auipc	s6,0x4
ffffffffc0201d8c:	2b8b0b13          	addi	s6,s6,696 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d90:	3fe00993          	li	s3,1022
        c = getchar();
ffffffffc0201d94:	bc8fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201d98:	00054a63          	bltz	a0,ffffffffc0201dac <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d9c:	00a4da63          	bge	s1,a0,ffffffffc0201db0 <readline+0x54>
ffffffffc0201da0:	0289d263          	bge	s3,s0,ffffffffc0201dc4 <readline+0x68>
        c = getchar();
ffffffffc0201da4:	bb8fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201da8:	fe055ae3          	bgez	a0,ffffffffc0201d9c <readline+0x40>
            return NULL;
ffffffffc0201dac:	4501                	li	a0,0
ffffffffc0201dae:	a091                	j	ffffffffc0201df2 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201db0:	03251463          	bne	a0,s2,ffffffffc0201dd8 <readline+0x7c>
ffffffffc0201db4:	04804963          	bgtz	s0,ffffffffc0201e06 <readline+0xaa>
        c = getchar();
ffffffffc0201db8:	ba4fe0ef          	jal	ffffffffc020015c <getchar>
        if (c < 0) {
ffffffffc0201dbc:	fe0548e3          	bltz	a0,ffffffffc0201dac <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dc0:	fea4d8e3          	bge	s1,a0,ffffffffc0201db0 <readline+0x54>
            cputchar(c);
ffffffffc0201dc4:	e42a                	sd	a0,8(sp)
ffffffffc0201dc6:	b46fe0ef          	jal	ffffffffc020010c <cputchar>
            buf[i ++] = c;
ffffffffc0201dca:	6522                	ld	a0,8(sp)
ffffffffc0201dcc:	008b07b3          	add	a5,s6,s0
ffffffffc0201dd0:	2405                	addiw	s0,s0,1
ffffffffc0201dd2:	00a78023          	sb	a0,0(a5)
ffffffffc0201dd6:	bf7d                	j	ffffffffc0201d94 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201dd8:	01450463          	beq	a0,s4,ffffffffc0201de0 <readline+0x84>
ffffffffc0201ddc:	fb551ce3          	bne	a0,s5,ffffffffc0201d94 <readline+0x38>
            cputchar(c);
ffffffffc0201de0:	b2cfe0ef          	jal	ffffffffc020010c <cputchar>
            buf[i] = '\0';
ffffffffc0201de4:	00004517          	auipc	a0,0x4
ffffffffc0201de8:	25c50513          	addi	a0,a0,604 # ffffffffc0206040 <buf>
ffffffffc0201dec:	942a                	add	s0,s0,a0
ffffffffc0201dee:	00040023          	sb	zero,0(s0)
            return buf;
        }
    }
}
ffffffffc0201df2:	60a6                	ld	ra,72(sp)
ffffffffc0201df4:	6406                	ld	s0,64(sp)
ffffffffc0201df6:	74e2                	ld	s1,56(sp)
ffffffffc0201df8:	7942                	ld	s2,48(sp)
ffffffffc0201dfa:	79a2                	ld	s3,40(sp)
ffffffffc0201dfc:	7a02                	ld	s4,32(sp)
ffffffffc0201dfe:	6ae2                	ld	s5,24(sp)
ffffffffc0201e00:	6b42                	ld	s6,16(sp)
ffffffffc0201e02:	6161                	addi	sp,sp,80
ffffffffc0201e04:	8082                	ret
            cputchar(c);
ffffffffc0201e06:	4521                	li	a0,8
ffffffffc0201e08:	b04fe0ef          	jal	ffffffffc020010c <cputchar>
            i --;
ffffffffc0201e0c:	347d                	addiw	s0,s0,-1
ffffffffc0201e0e:	b759                	j	ffffffffc0201d94 <readline+0x38>

ffffffffc0201e10 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201e10:	4781                	li	a5,0
ffffffffc0201e12:	00004717          	auipc	a4,0x4
ffffffffc0201e16:	20e73703          	ld	a4,526(a4) # ffffffffc0206020 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201e1a:	88ba                	mv	a7,a4
ffffffffc0201e1c:	852a                	mv	a0,a0
ffffffffc0201e1e:	85be                	mv	a1,a5
ffffffffc0201e20:	863e                	mv	a2,a5
ffffffffc0201e22:	00000073          	ecall
ffffffffc0201e26:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201e28:	8082                	ret

ffffffffc0201e2a <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201e2a:	4781                	li	a5,0
ffffffffc0201e2c:	00004717          	auipc	a4,0x4
ffffffffc0201e30:	66c73703          	ld	a4,1644(a4) # ffffffffc0206498 <SBI_SET_TIMER>
ffffffffc0201e34:	88ba                	mv	a7,a4
ffffffffc0201e36:	852a                	mv	a0,a0
ffffffffc0201e38:	85be                	mv	a1,a5
ffffffffc0201e3a:	863e                	mv	a2,a5
ffffffffc0201e3c:	00000073          	ecall
ffffffffc0201e40:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e42:	8082                	ret

ffffffffc0201e44 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e44:	4501                	li	a0,0
ffffffffc0201e46:	00004797          	auipc	a5,0x4
ffffffffc0201e4a:	1d27b783          	ld	a5,466(a5) # ffffffffc0206018 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e4e:	88be                	mv	a7,a5
ffffffffc0201e50:	852a                	mv	a0,a0
ffffffffc0201e52:	85aa                	mv	a1,a0
ffffffffc0201e54:	862a                	mv	a2,a0
ffffffffc0201e56:	00000073          	ecall
ffffffffc0201e5a:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e5c:	2501                	sext.w	a0,a0
ffffffffc0201e5e:	8082                	ret

ffffffffc0201e60 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e60:	4781                	li	a5,0
ffffffffc0201e62:	00004717          	auipc	a4,0x4
ffffffffc0201e66:	1ae73703          	ld	a4,430(a4) # ffffffffc0206010 <SBI_SHUTDOWN>
ffffffffc0201e6a:	88ba                	mv	a7,a4
ffffffffc0201e6c:	853e                	mv	a0,a5
ffffffffc0201e6e:	85be                	mv	a1,a5
ffffffffc0201e70:	863e                	mv	a2,a5
ffffffffc0201e72:	00000073          	ecall
ffffffffc0201e76:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e78:	8082                	ret

ffffffffc0201e7a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e7a:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e7e:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e80:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e82:	cb81                	beqz	a5,ffffffffc0201e92 <strlen+0x18>
        cnt ++;
ffffffffc0201e84:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e86:	00a707b3          	add	a5,a4,a0
ffffffffc0201e8a:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e8e:	fbfd                	bnez	a5,ffffffffc0201e84 <strlen+0xa>
ffffffffc0201e90:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e92:	8082                	ret

ffffffffc0201e94 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e94:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e96:	e589                	bnez	a1,ffffffffc0201ea0 <strnlen+0xc>
ffffffffc0201e98:	a811                	j	ffffffffc0201eac <strnlen+0x18>
        cnt ++;
ffffffffc0201e9a:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e9c:	00f58863          	beq	a1,a5,ffffffffc0201eac <strnlen+0x18>
ffffffffc0201ea0:	00f50733          	add	a4,a0,a5
ffffffffc0201ea4:	00074703          	lbu	a4,0(a4)
ffffffffc0201ea8:	fb6d                	bnez	a4,ffffffffc0201e9a <strnlen+0x6>
ffffffffc0201eaa:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201eac:	852e                	mv	a0,a1
ffffffffc0201eae:	8082                	ret

ffffffffc0201eb0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eb0:	00054783          	lbu	a5,0(a0)
ffffffffc0201eb4:	e791                	bnez	a5,ffffffffc0201ec0 <strcmp+0x10>
ffffffffc0201eb6:	a02d                	j	ffffffffc0201ee0 <strcmp+0x30>
ffffffffc0201eb8:	00054783          	lbu	a5,0(a0)
ffffffffc0201ebc:	cf89                	beqz	a5,ffffffffc0201ed6 <strcmp+0x26>
ffffffffc0201ebe:	85b6                	mv	a1,a3
ffffffffc0201ec0:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0201ec4:	0505                	addi	a0,a0,1
ffffffffc0201ec6:	00158693          	addi	a3,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201eca:	fef707e3          	beq	a4,a5,ffffffffc0201eb8 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ece:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201ed2:	9d19                	subw	a0,a0,a4
ffffffffc0201ed4:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ed6:	0015c703          	lbu	a4,1(a1)
ffffffffc0201eda:	4501                	li	a0,0
}
ffffffffc0201edc:	9d19                	subw	a0,a0,a4
ffffffffc0201ede:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201ee0:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ee4:	4501                	li	a0,0
ffffffffc0201ee6:	b7f5                	j	ffffffffc0201ed2 <strcmp+0x22>

ffffffffc0201ee8 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ee8:	ce01                	beqz	a2,ffffffffc0201f00 <strncmp+0x18>
ffffffffc0201eea:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201eee:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201ef0:	cb91                	beqz	a5,ffffffffc0201f04 <strncmp+0x1c>
ffffffffc0201ef2:	0005c703          	lbu	a4,0(a1)
ffffffffc0201ef6:	00f71763          	bne	a4,a5,ffffffffc0201f04 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc0201efa:	0505                	addi	a0,a0,1
ffffffffc0201efc:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201efe:	f675                	bnez	a2,ffffffffc0201eea <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f00:	4501                	li	a0,0
ffffffffc0201f02:	8082                	ret
ffffffffc0201f04:	00054503          	lbu	a0,0(a0)
ffffffffc0201f08:	0005c783          	lbu	a5,0(a1)
ffffffffc0201f0c:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201f0e:	8082                	ret

ffffffffc0201f10 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f10:	00054783          	lbu	a5,0(a0)
ffffffffc0201f14:	c799                	beqz	a5,ffffffffc0201f22 <strchr+0x12>
        if (*s == c) {
ffffffffc0201f16:	00f58763          	beq	a1,a5,ffffffffc0201f24 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201f1a:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201f1e:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f20:	fbfd                	bnez	a5,ffffffffc0201f16 <strchr+0x6>
    }
    return NULL;
ffffffffc0201f22:	4501                	li	a0,0
}
ffffffffc0201f24:	8082                	ret

ffffffffc0201f26 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f26:	ca01                	beqz	a2,ffffffffc0201f36 <memset+0x10>
ffffffffc0201f28:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f2a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f2c:	0785                	addi	a5,a5,1
ffffffffc0201f2e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f32:	fef61de3          	bne	a2,a5,ffffffffc0201f2c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f36:	8082                	ret
