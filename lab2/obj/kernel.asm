
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
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d628293          	addi	t0,t0,214 # ffffffffc02000d6 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16 # ffffffffc0204ff0 <bootstack+0x1ff0>
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00001517          	auipc	a0,0x1
ffffffffc0200050:	64c50513          	addi	a0,a0,1612 # ffffffffc0201698 <etext+0x2>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0f2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07c58593          	addi	a1,a1,124 # ffffffffc02000d6 <kern_init>
ffffffffc0200062:	00001517          	auipc	a0,0x1
ffffffffc0200066:	65650513          	addi	a0,a0,1622 # ffffffffc02016b8 <etext+0x22>
ffffffffc020006a:	0de000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00001597          	auipc	a1,0x1
ffffffffc0200072:	62858593          	addi	a1,a1,1576 # ffffffffc0201696 <etext>
ffffffffc0200076:	00001517          	auipc	a0,0x1
ffffffffc020007a:	66250513          	addi	a0,a0,1634 # ffffffffc02016d8 <etext+0x42>
ffffffffc020007e:	0ca000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00006597          	auipc	a1,0x6
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0206018 <free_area>
ffffffffc020008a:	00001517          	auipc	a0,0x1
ffffffffc020008e:	66e50513          	addi	a0,a0,1646 # ffffffffc02016f8 <etext+0x62>
ffffffffc0200092:	0b6000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00006597          	auipc	a1,0x6
ffffffffc020009a:	fe258593          	addi	a1,a1,-30 # ffffffffc0206078 <end>
ffffffffc020009e:	00001517          	auipc	a0,0x1
ffffffffc02000a2:	67a50513          	addi	a0,a0,1658 # ffffffffc0201718 <etext+0x82>
ffffffffc02000a6:	0a2000ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00000717          	auipc	a4,0x0
ffffffffc02000ae:	02c70713          	addi	a4,a4,44 # ffffffffc02000d6 <kern_init>
ffffffffc02000b2:	00006797          	auipc	a5,0x6
ffffffffc02000b6:	3c578793          	addi	a5,a5,965 # ffffffffc0206477 <end+0x3ff>
ffffffffc02000ba:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000bc:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c0:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c6:	95be                	add	a1,a1,a5
ffffffffc02000c8:	85a9                	srai	a1,a1,0xa
ffffffffc02000ca:	00001517          	auipc	a0,0x1
ffffffffc02000ce:	66e50513          	addi	a0,a0,1646 # ffffffffc0201738 <etext+0xa2>
}
ffffffffc02000d2:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d4:	a895                	j	ffffffffc0200148 <cprintf>

ffffffffc02000d6 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d6:	00006517          	auipc	a0,0x6
ffffffffc02000da:	f4250513          	addi	a0,a0,-190 # ffffffffc0206018 <free_area>
ffffffffc02000de:	00006617          	auipc	a2,0x6
ffffffffc02000e2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000e6:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000e8:	8e09                	sub	a2,a2,a0
ffffffffc02000ea:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ec:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000ee:	596010ef          	jal	ffffffffc0201684 <memset>
    dtb_init();
ffffffffc02000f2:	136000ef          	jal	ffffffffc0200228 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f6:	128000ef          	jal	ffffffffc020021e <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fa:	00002517          	auipc	a0,0x2
ffffffffc02000fe:	da650513          	addi	a0,a0,-602 # ffffffffc0201ea0 <etext+0x80a>
ffffffffc0200102:	07a000ef          	jal	ffffffffc020017c <cputs>

    print_kerninfo();
ffffffffc0200106:	f45ff0ef          	jal	ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010a:	731000ef          	jal	ffffffffc020103a <pmm_init>

    /* do nothing */
    while (1)
ffffffffc020010e:	a001                	j	ffffffffc020010e <kern_init+0x38>

ffffffffc0200110 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	ec06                	sd	ra,24(sp)
ffffffffc0200114:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200116:	10a000ef          	jal	ffffffffc0200220 <cons_putc>
    (*cnt) ++;
ffffffffc020011a:	65a2                	ld	a1,8(sp)
}
ffffffffc020011c:	60e2                	ld	ra,24(sp)
    (*cnt) ++;
ffffffffc020011e:	419c                	lw	a5,0(a1)
ffffffffc0200120:	2785                	addiw	a5,a5,1
ffffffffc0200122:	c19c                	sw	a5,0(a1)
}
ffffffffc0200124:	6105                	addi	sp,sp,32
ffffffffc0200126:	8082                	ret

ffffffffc0200128 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200128:	1101                	addi	sp,sp,-32
ffffffffc020012a:	862a                	mv	a2,a0
ffffffffc020012c:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020012e:	00000517          	auipc	a0,0x0
ffffffffc0200132:	fe250513          	addi	a0,a0,-30 # ffffffffc0200110 <cputch>
ffffffffc0200136:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200138:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc020013a:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013c:	138010ef          	jal	ffffffffc0201274 <vprintfmt>
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	4532                	lw	a0,12(sp)
ffffffffc0200144:	6105                	addi	sp,sp,32
ffffffffc0200146:	8082                	ret

ffffffffc0200148 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200148:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc020014a:	02810313          	addi	t1,sp,40
cprintf(const char *fmt, ...) {
ffffffffc020014e:	f42e                	sd	a1,40(sp)
ffffffffc0200150:	f832                	sd	a2,48(sp)
ffffffffc0200152:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200154:	862a                	mv	a2,a0
ffffffffc0200156:	004c                	addi	a1,sp,4
ffffffffc0200158:	00000517          	auipc	a0,0x0
ffffffffc020015c:	fb850513          	addi	a0,a0,-72 # ffffffffc0200110 <cputch>
ffffffffc0200160:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc0200162:	ec06                	sd	ra,24(sp)
ffffffffc0200164:	e0ba                	sd	a4,64(sp)
ffffffffc0200166:	e4be                	sd	a5,72(sp)
ffffffffc0200168:	e8c2                	sd	a6,80(sp)
ffffffffc020016a:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc020016c:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc020016e:	e41a                	sd	t1,8(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	104010ef          	jal	ffffffffc0201274 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200174:	60e2                	ld	ra,24(sp)
ffffffffc0200176:	4512                	lw	a0,4(sp)
ffffffffc0200178:	6125                	addi	sp,sp,96
ffffffffc020017a:	8082                	ret

ffffffffc020017c <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc020017c:	1101                	addi	sp,sp,-32
ffffffffc020017e:	e822                	sd	s0,16(sp)
ffffffffc0200180:	ec06                	sd	ra,24(sp)
ffffffffc0200182:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200184:	00054503          	lbu	a0,0(a0)
ffffffffc0200188:	c51d                	beqz	a0,ffffffffc02001b6 <cputs+0x3a>
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc020018e:	4481                	li	s1,0
    cons_putc(c);
ffffffffc0200190:	090000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200194:	00044503          	lbu	a0,0(s0)
ffffffffc0200198:	0405                	addi	s0,s0,1
ffffffffc020019a:	87a6                	mv	a5,s1
    (*cnt) ++;
ffffffffc020019c:	2485                	addiw	s1,s1,1
    while ((c = *str ++) != '\0') {
ffffffffc020019e:	f96d                	bnez	a0,ffffffffc0200190 <cputs+0x14>
    cons_putc(c);
ffffffffc02001a0:	4529                	li	a0,10
    (*cnt) ++;
ffffffffc02001a2:	0027841b          	addiw	s0,a5,2
ffffffffc02001a6:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001a8:	078000ef          	jal	ffffffffc0200220 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001ac:	60e2                	ld	ra,24(sp)
ffffffffc02001ae:	8522                	mv	a0,s0
ffffffffc02001b0:	6442                	ld	s0,16(sp)
ffffffffc02001b2:	6105                	addi	sp,sp,32
ffffffffc02001b4:	8082                	ret
    cons_putc(c);
ffffffffc02001b6:	4529                	li	a0,10
ffffffffc02001b8:	068000ef          	jal	ffffffffc0200220 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001bc:	4405                	li	s0,1
}
ffffffffc02001be:	60e2                	ld	ra,24(sp)
ffffffffc02001c0:	8522                	mv	a0,s0
ffffffffc02001c2:	6442                	ld	s0,16(sp)
ffffffffc02001c4:	6105                	addi	sp,sp,32
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00006317          	auipc	t1,0x6
ffffffffc02001cc:	e6832303          	lw	t1,-408(t1) # ffffffffc0206030 <is_panic>
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	f436                	sd	a3,40(sp)
ffffffffc02001d6:	f83a                	sd	a4,48(sp)
ffffffffc02001d8:	fc3e                	sd	a5,56(sp)
ffffffffc02001da:	e0c2                	sd	a6,64(sp)
ffffffffc02001dc:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001de:	00030363          	beqz	t1,ffffffffc02001e4 <__panic+0x1c>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e2:	a001                	j	ffffffffc02001e2 <__panic+0x1a>
    is_panic = 1;
ffffffffc02001e4:	4705                	li	a4,1
    va_start(ap, fmt);
ffffffffc02001e6:	103c                	addi	a5,sp,40
ffffffffc02001e8:	e822                	sd	s0,16(sp)
ffffffffc02001ea:	8432                	mv	s0,a2
ffffffffc02001ec:	862e                	mv	a2,a1
ffffffffc02001ee:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f0:	00001517          	auipc	a0,0x1
ffffffffc02001f4:	57850513          	addi	a0,a0,1400 # ffffffffc0201768 <etext+0xd2>
    is_panic = 1;
ffffffffc02001f8:	00006697          	auipc	a3,0x6
ffffffffc02001fc:	e2e6ac23          	sw	a4,-456(a3) # ffffffffc0206030 <is_panic>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f47ff0ef          	jal	ffffffffc0200148 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f1fff0ef          	jal	ffffffffc0200128 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	57a50513          	addi	a0,a0,1402 # ffffffffc0201788 <etext+0xf2>
ffffffffc0200216:	f33ff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc020021a:	6442                	ld	s0,16(sp)
ffffffffc020021c:	b7d9                	j	ffffffffc02001e2 <__panic+0x1a>

ffffffffc020021e <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200220:	0ff57513          	zext.b	a0,a0
ffffffffc0200224:	3b60106f          	j	ffffffffc02015da <sbi_console_putchar>

ffffffffc0200228 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200228:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc020022a:	00001517          	auipc	a0,0x1
ffffffffc020022e:	56650513          	addi	a0,a0,1382 # ffffffffc0201790 <etext+0xfa>
void dtb_init(void) {
ffffffffc0200232:	f406                	sd	ra,40(sp)
ffffffffc0200234:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc0200236:	f13ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	dc65b583          	ld	a1,-570(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200242:	00001517          	auipc	a0,0x1
ffffffffc0200246:	55e50513          	addi	a0,a0,1374 # ffffffffc02017a0 <etext+0x10a>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020024a:	00006417          	auipc	s0,0x6
ffffffffc020024e:	dbe40413          	addi	s0,s0,-578 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200252:	ef7ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200256:	600c                	ld	a1,0(s0)
ffffffffc0200258:	00001517          	auipc	a0,0x1
ffffffffc020025c:	55850513          	addi	a0,a0,1368 # ffffffffc02017b0 <etext+0x11a>
ffffffffc0200260:	ee9ff0ef          	jal	ffffffffc0200148 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200264:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc0200266:	00001517          	auipc	a0,0x1
ffffffffc020026a:	56250513          	addi	a0,a0,1378 # ffffffffc02017c8 <etext+0x132>
    if (boot_dtb == 0) {
ffffffffc020026e:	10070163          	beqz	a4,ffffffffc0200370 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200272:	57f5                	li	a5,-3
ffffffffc0200274:	07fa                	slli	a5,a5,0x1e
ffffffffc0200276:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200278:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020027a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020027e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfed9e75>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200282:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200286:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020028a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020028e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200292:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200298:	8e49                	or	a2,a2,a0
ffffffffc020029a:	0ff7f793          	zext.b	a5,a5
ffffffffc020029e:	8dd1                	or	a1,a1,a2
ffffffffc02002a0:	07a2                	slli	a5,a5,0x8
ffffffffc02002a2:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a4:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc02002a8:	0cd59863          	bne	a1,a3,ffffffffc0200378 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ac:	4710                	lw	a2,8(a4)
ffffffffc02002ae:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02002b0:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002b2:	0086541b          	srliw	s0,a2,0x8
ffffffffc02002b6:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ba:	01865e1b          	srliw	t3,a2,0x18
ffffffffc02002be:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002c2:	0186151b          	slliw	a0,a2,0x18
ffffffffc02002c6:	0186959b          	slliw	a1,a3,0x18
ffffffffc02002ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ce:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002d6:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02002da:	01c56533          	or	a0,a0,t3
ffffffffc02002de:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e2:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e6:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002ea:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ee:	0ff6f693          	zext.b	a3,a3
ffffffffc02002f2:	8c49                	or	s0,s0,a0
ffffffffc02002f4:	0622                	slli	a2,a2,0x8
ffffffffc02002f6:	8fcd                	or	a5,a5,a1
ffffffffc02002f8:	06a2                	slli	a3,a3,0x8
ffffffffc02002fa:	8c51                	or	s0,s0,a2
ffffffffc02002fc:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02002fe:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200300:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200302:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200304:	9381                	srli	a5,a5,0x20
ffffffffc0200306:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200308:	4301                	li	t1,0
        switch (token) {
ffffffffc020030a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020030c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020030e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc0200312:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200314:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	0087579b          	srliw	a5,a4,0x8
ffffffffc020031a:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020031e:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200322:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200326:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020032e:	8ed1                	or	a3,a3,a2
ffffffffc0200330:	0ff77713          	zext.b	a4,a4
ffffffffc0200334:	8fd5                	or	a5,a5,a3
ffffffffc0200336:	0722                	slli	a4,a4,0x8
ffffffffc0200338:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc020033a:	05178763          	beq	a5,a7,ffffffffc0200388 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020033e:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc0200340:	00f8e963          	bltu	a7,a5,ffffffffc0200352 <dtb_init+0x12a>
ffffffffc0200344:	07c78d63          	beq	a5,t3,ffffffffc02003be <dtb_init+0x196>
ffffffffc0200348:	4709                	li	a4,2
ffffffffc020034a:	00e79763          	bne	a5,a4,ffffffffc0200358 <dtb_init+0x130>
ffffffffc020034e:	4301                	li	t1,0
ffffffffc0200350:	b7d1                	j	ffffffffc0200314 <dtb_init+0xec>
ffffffffc0200352:	4711                	li	a4,4
ffffffffc0200354:	fce780e3          	beq	a5,a4,ffffffffc0200314 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200358:	00001517          	auipc	a0,0x1
ffffffffc020035c:	53850513          	addi	a0,a0,1336 # ffffffffc0201890 <etext+0x1fa>
ffffffffc0200360:	de9ff0ef          	jal	ffffffffc0200148 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200364:	64e2                	ld	s1,24(sp)
ffffffffc0200366:	6942                	ld	s2,16(sp)
ffffffffc0200368:	00001517          	auipc	a0,0x1
ffffffffc020036c:	56050513          	addi	a0,a0,1376 # ffffffffc02018c8 <etext+0x232>
}
ffffffffc0200370:	7402                	ld	s0,32(sp)
ffffffffc0200372:	70a2                	ld	ra,40(sp)
ffffffffc0200374:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200376:	bbc9                	j	ffffffffc0200148 <cprintf>
}
ffffffffc0200378:	7402                	ld	s0,32(sp)
ffffffffc020037a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020037c:	00001517          	auipc	a0,0x1
ffffffffc0200380:	46c50513          	addi	a0,a0,1132 # ffffffffc02017e8 <etext+0x152>
}
ffffffffc0200384:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200386:	b3c9                	j	ffffffffc0200148 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200388:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020038a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020038e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200392:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200396:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020039e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003a2:	8ed1                	or	a3,a3,a2
ffffffffc02003a4:	0ff77713          	zext.b	a4,a4
ffffffffc02003a8:	8fd5                	or	a5,a5,a3
ffffffffc02003aa:	0722                	slli	a4,a4,0x8
ffffffffc02003ac:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003ae:	04031463          	bnez	t1,ffffffffc02003f6 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02003b2:	1782                	slli	a5,a5,0x20
ffffffffc02003b4:	9381                	srli	a5,a5,0x20
ffffffffc02003b6:	043d                	addi	s0,s0,15
ffffffffc02003b8:	943e                	add	s0,s0,a5
ffffffffc02003ba:	9871                	andi	s0,s0,-4
                break;
ffffffffc02003bc:	bfa1                	j	ffffffffc0200314 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc02003be:	8522                	mv	a0,s0
ffffffffc02003c0:	e01a                	sd	t1,0(sp)
ffffffffc02003c2:	232010ef          	jal	ffffffffc02015f4 <strlen>
ffffffffc02003c6:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003c8:	4619                	li	a2,6
ffffffffc02003ca:	8522                	mv	a0,s0
ffffffffc02003cc:	00001597          	auipc	a1,0x1
ffffffffc02003d0:	44458593          	addi	a1,a1,1092 # ffffffffc0201810 <etext+0x17a>
ffffffffc02003d4:	288010ef          	jal	ffffffffc020165c <strncmp>
ffffffffc02003d8:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003da:	0411                	addi	s0,s0,4
ffffffffc02003dc:	0004879b          	sext.w	a5,s1
ffffffffc02003e0:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e2:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02003e6:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003e8:	00a36333          	or	t1,t1,a0
                break;
ffffffffc02003ec:	00ff0837          	lui	a6,0xff0
ffffffffc02003f0:	488d                	li	a7,3
ffffffffc02003f2:	4e05                	li	t3,1
ffffffffc02003f4:	b705                	j	ffffffffc0200314 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003f6:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003f8:	00001597          	auipc	a1,0x1
ffffffffc02003fc:	42058593          	addi	a1,a1,1056 # ffffffffc0201818 <etext+0x182>
ffffffffc0200400:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200402:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200406:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020040a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020040e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200412:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200416:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020041a:	8ed1                	or	a3,a3,a2
ffffffffc020041c:	0ff77713          	zext.b	a4,a4
ffffffffc0200420:	0722                	slli	a4,a4,0x8
ffffffffc0200422:	8d55                	or	a0,a0,a3
ffffffffc0200424:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc0200426:	1502                	slli	a0,a0,0x20
ffffffffc0200428:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020042a:	954a                	add	a0,a0,s2
ffffffffc020042c:	e01a                	sd	t1,0(sp)
ffffffffc020042e:	1fa010ef          	jal	ffffffffc0201628 <strcmp>
ffffffffc0200432:	67a2                	ld	a5,8(sp)
ffffffffc0200434:	473d                	li	a4,15
ffffffffc0200436:	6302                	ld	t1,0(sp)
ffffffffc0200438:	00ff0837          	lui	a6,0xff0
ffffffffc020043c:	488d                	li	a7,3
ffffffffc020043e:	4e05                	li	t3,1
ffffffffc0200440:	f6f779e3          	bgeu	a4,a5,ffffffffc02003b2 <dtb_init+0x18a>
ffffffffc0200444:	f53d                	bnez	a0,ffffffffc02003b2 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200446:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc020044a:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc020044e:	00001517          	auipc	a0,0x1
ffffffffc0200452:	3d250513          	addi	a0,a0,978 # ffffffffc0201820 <etext+0x18a>
           fdt32_to_cpu(x >> 32);
ffffffffc0200456:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020045a:	0087d31b          	srliw	t1,a5,0x8
ffffffffc020045e:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200462:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200466:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020046a:	0187959b          	slliw	a1,a5,0x18
ffffffffc020046e:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200472:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200476:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020047a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01037333          	and	t1,t1,a6
ffffffffc0200482:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200486:	01e5e5b3          	or	a1,a1,t5
ffffffffc020048a:	0ff7f793          	zext.b	a5,a5
ffffffffc020048e:	01de6e33          	or	t3,t3,t4
ffffffffc0200492:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200496:	01067633          	and	a2,a2,a6
ffffffffc020049a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020049e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004a2:	07a2                	slli	a5,a5,0x8
ffffffffc02004a4:	0108d89b          	srliw	a7,a7,0x10
ffffffffc02004a8:	0186df1b          	srliw	t5,a3,0x18
ffffffffc02004ac:	01875e9b          	srliw	t4,a4,0x18
ffffffffc02004b0:	8ddd                	or	a1,a1,a5
ffffffffc02004b2:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b6:	0186979b          	slliw	a5,a3,0x18
ffffffffc02004ba:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004be:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c2:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c6:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ca:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ce:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004d2:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	08a2                	slli	a7,a7,0x8
ffffffffc02004d8:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004dc:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e0:	0ff6f693          	zext.b	a3,a3
ffffffffc02004e4:	01de6833          	or	a6,t3,t4
ffffffffc02004e8:	0ff77713          	zext.b	a4,a4
ffffffffc02004ec:	01166633          	or	a2,a2,a7
ffffffffc02004f0:	0067e7b3          	or	a5,a5,t1
ffffffffc02004f4:	06a2                	slli	a3,a3,0x8
ffffffffc02004f6:	01046433          	or	s0,s0,a6
ffffffffc02004fa:	0722                	slli	a4,a4,0x8
ffffffffc02004fc:	8fd5                	or	a5,a5,a3
ffffffffc02004fe:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200500:	1582                	slli	a1,a1,0x20
ffffffffc0200502:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200504:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200506:	9201                	srli	a2,a2,0x20
ffffffffc0200508:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020050a:	1402                	slli	s0,s0,0x20
ffffffffc020050c:	00b7e4b3          	or	s1,a5,a1
ffffffffc0200510:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200512:	c37ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200516:	85a6                	mv	a1,s1
ffffffffc0200518:	00001517          	auipc	a0,0x1
ffffffffc020051c:	32850513          	addi	a0,a0,808 # ffffffffc0201840 <etext+0x1aa>
ffffffffc0200520:	c29ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200524:	01445613          	srli	a2,s0,0x14
ffffffffc0200528:	85a2                	mv	a1,s0
ffffffffc020052a:	00001517          	auipc	a0,0x1
ffffffffc020052e:	32e50513          	addi	a0,a0,814 # ffffffffc0201858 <etext+0x1c2>
ffffffffc0200532:	c17ff0ef          	jal	ffffffffc0200148 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200536:	009405b3          	add	a1,s0,s1
ffffffffc020053a:	15fd                	addi	a1,a1,-1
ffffffffc020053c:	00001517          	auipc	a0,0x1
ffffffffc0200540:	33c50513          	addi	a0,a0,828 # ffffffffc0201878 <etext+0x1e2>
ffffffffc0200544:	c05ff0ef          	jal	ffffffffc0200148 <cprintf>
        memory_base = mem_base;
ffffffffc0200548:	00006797          	auipc	a5,0x6
ffffffffc020054c:	ae97bc23          	sd	s1,-1288(a5) # ffffffffc0206040 <memory_base>
        memory_size = mem_size;
ffffffffc0200550:	00006797          	auipc	a5,0x6
ffffffffc0200554:	ae87b423          	sd	s0,-1304(a5) # ffffffffc0206038 <memory_size>
ffffffffc0200558:	b531                	j	ffffffffc0200364 <dtb_init+0x13c>

ffffffffc020055a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020055a:	00006517          	auipc	a0,0x6
ffffffffc020055e:	ae653503          	ld	a0,-1306(a0) # ffffffffc0206040 <memory_base>
ffffffffc0200562:	8082                	ret

ffffffffc0200564 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc0200564:	00006517          	auipc	a0,0x6
ffffffffc0200568:	ad453503          	ld	a0,-1324(a0) # ffffffffc0206038 <memory_size>
ffffffffc020056c:	8082                	ret

ffffffffc020056e <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020056e:	00006797          	auipc	a5,0x6
ffffffffc0200572:	aaa78793          	addi	a5,a5,-1366 # ffffffffc0206018 <free_area>
ffffffffc0200576:	e79c                	sd	a5,8(a5)
ffffffffc0200578:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc020057a:	0007a823          	sw	zero,16(a5)
}
ffffffffc020057e:	8082                	ret

ffffffffc0200580 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200580:	00006517          	auipc	a0,0x6
ffffffffc0200584:	aa856503          	lwu	a0,-1368(a0) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200588:	8082                	ret

ffffffffc020058a <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc020058a:	711d                	addi	sp,sp,-96
ffffffffc020058c:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020058e:	00006917          	auipc	s2,0x6
ffffffffc0200592:	a8a90913          	addi	s2,s2,-1398 # ffffffffc0206018 <free_area>
ffffffffc0200596:	00893783          	ld	a5,8(s2)
ffffffffc020059a:	ec86                	sd	ra,88(sp)
ffffffffc020059c:	e8a2                	sd	s0,80(sp)
ffffffffc020059e:	e4a6                	sd	s1,72(sp)
ffffffffc02005a0:	fc4e                	sd	s3,56(sp)
ffffffffc02005a2:	f852                	sd	s4,48(sp)
ffffffffc02005a4:	f456                	sd	s5,40(sp)
ffffffffc02005a6:	f05a                	sd	s6,32(sp)
ffffffffc02005a8:	ec5e                	sd	s7,24(sp)
ffffffffc02005aa:	e862                	sd	s8,16(sp)
ffffffffc02005ac:	e466                	sd	s9,8(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ae:	2b278f63          	beq	a5,s2,ffffffffc020086c <best_fit_check+0x2e2>
    int count = 0, total = 0;
ffffffffc02005b2:	4401                	li	s0,0
ffffffffc02005b4:	4481                	li	s1,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02005b6:	ff07b703          	ld	a4,-16(a5)
ffffffffc02005ba:	8b09                	andi	a4,a4,2
ffffffffc02005bc:	2a070c63          	beqz	a4,ffffffffc0200874 <best_fit_check+0x2ea>
        count ++, total += p->property;
ffffffffc02005c0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02005c4:	679c                	ld	a5,8(a5)
ffffffffc02005c6:	2485                	addiw	s1,s1,1
ffffffffc02005c8:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ca:	ff2796e3          	bne	a5,s2,ffffffffc02005b6 <best_fit_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc02005ce:	89a2                	mv	s3,s0
ffffffffc02005d0:	25f000ef          	jal	ffffffffc020102e <nr_free_pages>
ffffffffc02005d4:	39351063          	bne	a0,s3,ffffffffc0200954 <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02005d8:	4505                	li	a0,1
ffffffffc02005da:	23d000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02005de:	8aaa                	mv	s5,a0
ffffffffc02005e0:	3a050a63          	beqz	a0,ffffffffc0200994 <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02005e4:	4505                	li	a0,1
ffffffffc02005e6:	231000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02005ea:	89aa                	mv	s3,a0
ffffffffc02005ec:	38050463          	beqz	a0,ffffffffc0200974 <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02005f0:	4505                	li	a0,1
ffffffffc02005f2:	225000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02005f6:	8a2a                	mv	s4,a0
ffffffffc02005f8:	30050e63          	beqz	a0,ffffffffc0200914 <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02005fc:	40aa87b3          	sub	a5,s5,a0
ffffffffc0200600:	40a98733          	sub	a4,s3,a0
ffffffffc0200604:	0017b793          	seqz	a5,a5
ffffffffc0200608:	00173713          	seqz	a4,a4
ffffffffc020060c:	8fd9                	or	a5,a5,a4
ffffffffc020060e:	2e079363          	bnez	a5,ffffffffc02008f4 <best_fit_check+0x36a>
ffffffffc0200612:	2f3a8163          	beq	s5,s3,ffffffffc02008f4 <best_fit_check+0x36a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200616:	000aa783          	lw	a5,0(s5)
ffffffffc020061a:	26079d63          	bnez	a5,ffffffffc0200894 <best_fit_check+0x30a>
ffffffffc020061e:	0009a783          	lw	a5,0(s3)
ffffffffc0200622:	26079963          	bnez	a5,ffffffffc0200894 <best_fit_check+0x30a>
ffffffffc0200626:	411c                	lw	a5,0(a0)
ffffffffc0200628:	26079663          	bnez	a5,ffffffffc0200894 <best_fit_check+0x30a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020062c:	00006797          	auipc	a5,0x6
ffffffffc0200630:	a447b783          	ld	a5,-1468(a5) # ffffffffc0206070 <pages>
ffffffffc0200634:	ccccd737          	lui	a4,0xccccd
ffffffffc0200638:	ccd70713          	addi	a4,a4,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc020063c:	02071693          	slli	a3,a4,0x20
ffffffffc0200640:	96ba                	add	a3,a3,a4
ffffffffc0200642:	40fa8733          	sub	a4,s5,a5
ffffffffc0200646:	870d                	srai	a4,a4,0x3
ffffffffc0200648:	02d70733          	mul	a4,a4,a3
ffffffffc020064c:	00002517          	auipc	a0,0x2
ffffffffc0200650:	a3c53503          	ld	a0,-1476(a0) # ffffffffc0202088 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200654:	00006697          	auipc	a3,0x6
ffffffffc0200658:	a146b683          	ld	a3,-1516(a3) # ffffffffc0206068 <npage>
ffffffffc020065c:	06b2                	slli	a3,a3,0xc
ffffffffc020065e:	972a                	add	a4,a4,a0

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200660:	0732                	slli	a4,a4,0xc
ffffffffc0200662:	26d77963          	bgeu	a4,a3,ffffffffc02008d4 <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200666:	ccccd5b7          	lui	a1,0xccccd
ffffffffc020066a:	ccd58593          	addi	a1,a1,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc020066e:	02059613          	slli	a2,a1,0x20
ffffffffc0200672:	40f98733          	sub	a4,s3,a5
ffffffffc0200676:	962e                	add	a2,a2,a1
ffffffffc0200678:	870d                	srai	a4,a4,0x3
ffffffffc020067a:	02c70733          	mul	a4,a4,a2
ffffffffc020067e:	972a                	add	a4,a4,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200680:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200682:	40d77963          	bgeu	a4,a3,ffffffffc0200a94 <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200686:	40fa07b3          	sub	a5,s4,a5
ffffffffc020068a:	878d                	srai	a5,a5,0x3
ffffffffc020068c:	02c787b3          	mul	a5,a5,a2
ffffffffc0200690:	97aa                	add	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0200692:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200694:	3ed7f063          	bgeu	a5,a3,ffffffffc0200a74 <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc0200698:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020069a:	00093c03          	ld	s8,0(s2)
ffffffffc020069e:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc02006a2:	00006b17          	auipc	s6,0x6
ffffffffc02006a6:	986b2b03          	lw	s6,-1658(s6) # ffffffffc0206028 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc02006aa:	01293023          	sd	s2,0(s2)
ffffffffc02006ae:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc02006b2:	00006797          	auipc	a5,0x6
ffffffffc02006b6:	9607ab23          	sw	zero,-1674(a5) # ffffffffc0206028 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02006ba:	15d000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02006be:	38051b63          	bnez	a0,ffffffffc0200a54 <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc02006c2:	8556                	mv	a0,s5
ffffffffc02006c4:	4585                	li	a1,1
ffffffffc02006c6:	15d000ef          	jal	ffffffffc0201022 <free_pages>
    free_page(p1);
ffffffffc02006ca:	854e                	mv	a0,s3
ffffffffc02006cc:	4585                	li	a1,1
ffffffffc02006ce:	155000ef          	jal	ffffffffc0201022 <free_pages>
    free_page(p2);
ffffffffc02006d2:	8552                	mv	a0,s4
ffffffffc02006d4:	4585                	li	a1,1
ffffffffc02006d6:	14d000ef          	jal	ffffffffc0201022 <free_pages>
    assert(nr_free == 3);
ffffffffc02006da:	00006717          	auipc	a4,0x6
ffffffffc02006de:	94e72703          	lw	a4,-1714(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc02006e2:	478d                	li	a5,3
ffffffffc02006e4:	34f71863          	bne	a4,a5,ffffffffc0200a34 <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006e8:	4505                	li	a0,1
ffffffffc02006ea:	12d000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02006ee:	89aa                	mv	s3,a0
ffffffffc02006f0:	32050263          	beqz	a0,ffffffffc0200a14 <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006f4:	4505                	li	a0,1
ffffffffc02006f6:	121000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02006fa:	8aaa                	mv	s5,a0
ffffffffc02006fc:	2e050c63          	beqz	a0,ffffffffc02009f4 <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200700:	4505                	li	a0,1
ffffffffc0200702:	115000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200706:	8a2a                	mv	s4,a0
ffffffffc0200708:	2c050663          	beqz	a0,ffffffffc02009d4 <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc020070c:	4505                	li	a0,1
ffffffffc020070e:	109000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200712:	2a051163          	bnez	a0,ffffffffc02009b4 <best_fit_check+0x42a>
    free_page(p0);
ffffffffc0200716:	4585                	li	a1,1
ffffffffc0200718:	854e                	mv	a0,s3
ffffffffc020071a:	109000ef          	jal	ffffffffc0201022 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020071e:	00893783          	ld	a5,8(s2)
ffffffffc0200722:	19278963          	beq	a5,s2,ffffffffc02008b4 <best_fit_check+0x32a>
    assert((p = alloc_page()) == p0);
ffffffffc0200726:	4505                	li	a0,1
ffffffffc0200728:	0ef000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc020072c:	8caa                	mv	s9,a0
ffffffffc020072e:	54a99363          	bne	s3,a0,ffffffffc0200c74 <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc0200732:	4505                	li	a0,1
ffffffffc0200734:	0e3000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200738:	50051e63          	bnez	a0,ffffffffc0200c54 <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc020073c:	00006797          	auipc	a5,0x6
ffffffffc0200740:	8ec7a783          	lw	a5,-1812(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200744:	4e079863          	bnez	a5,ffffffffc0200c34 <best_fit_check+0x6aa>
    free_page(p);
ffffffffc0200748:	8566                	mv	a0,s9
ffffffffc020074a:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020074c:	01893023          	sd	s8,0(s2)
ffffffffc0200750:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0200754:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc0200758:	0cb000ef          	jal	ffffffffc0201022 <free_pages>
    free_page(p1);
ffffffffc020075c:	8556                	mv	a0,s5
ffffffffc020075e:	4585                	li	a1,1
ffffffffc0200760:	0c3000ef          	jal	ffffffffc0201022 <free_pages>
    free_page(p2);
ffffffffc0200764:	8552                	mv	a0,s4
ffffffffc0200766:	4585                	li	a1,1
ffffffffc0200768:	0bb000ef          	jal	ffffffffc0201022 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020076c:	4515                	li	a0,5
ffffffffc020076e:	0a9000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200772:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200774:	4a050063          	beqz	a0,ffffffffc0200c14 <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc0200778:	651c                	ld	a5,8(a0)
ffffffffc020077a:	8b89                	andi	a5,a5,2
ffffffffc020077c:	46079c63          	bnez	a5,ffffffffc0200bf4 <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200780:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200782:	00093b83          	ld	s7,0(s2)
ffffffffc0200786:	00893b03          	ld	s6,8(s2)
ffffffffc020078a:	01293023          	sd	s2,0(s2)
ffffffffc020078e:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0200792:	085000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200796:	42051f63          	bnez	a0,ffffffffc0200bd4 <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc020079a:	4589                	li	a1,2
ffffffffc020079c:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc02007a0:	00006c17          	auipc	s8,0x6
ffffffffc02007a4:	888c2c03          	lw	s8,-1912(s8) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 4, 1);
ffffffffc02007a8:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc02007ac:	00006797          	auipc	a5,0x6
ffffffffc02007b0:	8607ae23          	sw	zero,-1924(a5) # ffffffffc0206028 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02007b4:	06f000ef          	jal	ffffffffc0201022 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02007b8:	8556                	mv	a0,s5
ffffffffc02007ba:	4585                	li	a1,1
ffffffffc02007bc:	067000ef          	jal	ffffffffc0201022 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02007c0:	4511                	li	a0,4
ffffffffc02007c2:	055000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02007c6:	3e051763          	bnez	a0,ffffffffc0200bb4 <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02007ca:	0309b783          	ld	a5,48(s3)
ffffffffc02007ce:	8b89                	andi	a5,a5,2
ffffffffc02007d0:	3c078263          	beqz	a5,ffffffffc0200b94 <best_fit_check+0x60a>
ffffffffc02007d4:	0389ac83          	lw	s9,56(s3)
ffffffffc02007d8:	4789                	li	a5,2
ffffffffc02007da:	3afc9d63          	bne	s9,a5,ffffffffc0200b94 <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02007de:	4505                	li	a0,1
ffffffffc02007e0:	037000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02007e4:	8a2a                	mv	s4,a0
ffffffffc02007e6:	38050763          	beqz	a0,ffffffffc0200b74 <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02007ea:	8566                	mv	a0,s9
ffffffffc02007ec:	02b000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc02007f0:	36050263          	beqz	a0,ffffffffc0200b54 <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc02007f4:	354a9063          	bne	s5,s4,ffffffffc0200b34 <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02007f8:	854e                	mv	a0,s3
ffffffffc02007fa:	4595                	li	a1,5
ffffffffc02007fc:	027000ef          	jal	ffffffffc0201022 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200800:	4515                	li	a0,5
ffffffffc0200802:	015000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200806:	89aa                	mv	s3,a0
ffffffffc0200808:	30050663          	beqz	a0,ffffffffc0200b14 <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc020080c:	4505                	li	a0,1
ffffffffc020080e:	009000ef          	jal	ffffffffc0201016 <alloc_pages>
ffffffffc0200812:	2e051163          	bnez	a0,ffffffffc0200af4 <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200816:	00006797          	auipc	a5,0x6
ffffffffc020081a:	8127a783          	lw	a5,-2030(a5) # ffffffffc0206028 <free_area+0x10>
ffffffffc020081e:	2a079b63          	bnez	a5,ffffffffc0200ad4 <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200822:	854e                	mv	a0,s3
ffffffffc0200824:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0200826:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc020082a:	01793023          	sd	s7,0(s2)
ffffffffc020082e:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0200832:	7f0000ef          	jal	ffffffffc0201022 <free_pages>
    return listelm->next;
ffffffffc0200836:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020083a:	01278963          	beq	a5,s2,ffffffffc020084c <best_fit_check+0x2c2>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020083e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200842:	679c                	ld	a5,8(a5)
ffffffffc0200844:	34fd                	addiw	s1,s1,-1
ffffffffc0200846:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200848:	ff279be3          	bne	a5,s2,ffffffffc020083e <best_fit_check+0x2b4>
    }
    assert(count == 0);
ffffffffc020084c:	26049463          	bnez	s1,ffffffffc0200ab4 <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc0200850:	e075                	bnez	s0,ffffffffc0200934 <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200852:	60e6                	ld	ra,88(sp)
ffffffffc0200854:	6446                	ld	s0,80(sp)
ffffffffc0200856:	64a6                	ld	s1,72(sp)
ffffffffc0200858:	6906                	ld	s2,64(sp)
ffffffffc020085a:	79e2                	ld	s3,56(sp)
ffffffffc020085c:	7a42                	ld	s4,48(sp)
ffffffffc020085e:	7aa2                	ld	s5,40(sp)
ffffffffc0200860:	7b02                	ld	s6,32(sp)
ffffffffc0200862:	6be2                	ld	s7,24(sp)
ffffffffc0200864:	6c42                	ld	s8,16(sp)
ffffffffc0200866:	6ca2                	ld	s9,8(sp)
ffffffffc0200868:	6125                	addi	sp,sp,96
ffffffffc020086a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020086c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020086e:	4401                	li	s0,0
ffffffffc0200870:	4481                	li	s1,0
ffffffffc0200872:	bbb9                	j	ffffffffc02005d0 <best_fit_check+0x46>
        assert(PageProperty(p));
ffffffffc0200874:	00001697          	auipc	a3,0x1
ffffffffc0200878:	06c68693          	addi	a3,a3,108 # ffffffffc02018e0 <etext+0x24a>
ffffffffc020087c:	00001617          	auipc	a2,0x1
ffffffffc0200880:	07460613          	addi	a2,a2,116 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200884:	11600593          	li	a1,278
ffffffffc0200888:	00001517          	auipc	a0,0x1
ffffffffc020088c:	08050513          	addi	a0,a0,128 # ffffffffc0201908 <etext+0x272>
ffffffffc0200890:	939ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200894:	00001697          	auipc	a3,0x1
ffffffffc0200898:	13468693          	addi	a3,a3,308 # ffffffffc02019c8 <etext+0x332>
ffffffffc020089c:	00001617          	auipc	a2,0x1
ffffffffc02008a0:	05460613          	addi	a2,a2,84 # ffffffffc02018f0 <etext+0x25a>
ffffffffc02008a4:	0e300593          	li	a1,227
ffffffffc02008a8:	00001517          	auipc	a0,0x1
ffffffffc02008ac:	06050513          	addi	a0,a0,96 # ffffffffc0201908 <etext+0x272>
ffffffffc02008b0:	919ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02008b4:	00001697          	auipc	a3,0x1
ffffffffc02008b8:	1dc68693          	addi	a3,a3,476 # ffffffffc0201a90 <etext+0x3fa>
ffffffffc02008bc:	00001617          	auipc	a2,0x1
ffffffffc02008c0:	03460613          	addi	a2,a2,52 # ffffffffc02018f0 <etext+0x25a>
ffffffffc02008c4:	0fe00593          	li	a1,254
ffffffffc02008c8:	00001517          	auipc	a0,0x1
ffffffffc02008cc:	04050513          	addi	a0,a0,64 # ffffffffc0201908 <etext+0x272>
ffffffffc02008d0:	8f9ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02008d4:	00001697          	auipc	a3,0x1
ffffffffc02008d8:	13468693          	addi	a3,a3,308 # ffffffffc0201a08 <etext+0x372>
ffffffffc02008dc:	00001617          	auipc	a2,0x1
ffffffffc02008e0:	01460613          	addi	a2,a2,20 # ffffffffc02018f0 <etext+0x25a>
ffffffffc02008e4:	0e500593          	li	a1,229
ffffffffc02008e8:	00001517          	auipc	a0,0x1
ffffffffc02008ec:	02050513          	addi	a0,a0,32 # ffffffffc0201908 <etext+0x272>
ffffffffc02008f0:	8d9ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02008f4:	00001697          	auipc	a3,0x1
ffffffffc02008f8:	0ac68693          	addi	a3,a3,172 # ffffffffc02019a0 <etext+0x30a>
ffffffffc02008fc:	00001617          	auipc	a2,0x1
ffffffffc0200900:	ff460613          	addi	a2,a2,-12 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200904:	0e200593          	li	a1,226
ffffffffc0200908:	00001517          	auipc	a0,0x1
ffffffffc020090c:	00050513          	mv	a0,a0
ffffffffc0200910:	8b9ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200914:	00001697          	auipc	a3,0x1
ffffffffc0200918:	06c68693          	addi	a3,a3,108 # ffffffffc0201980 <etext+0x2ea>
ffffffffc020091c:	00001617          	auipc	a2,0x1
ffffffffc0200920:	fd460613          	addi	a2,a2,-44 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200924:	0e000593          	li	a1,224
ffffffffc0200928:	00001517          	auipc	a0,0x1
ffffffffc020092c:	fe050513          	addi	a0,a0,-32 # ffffffffc0201908 <etext+0x272>
ffffffffc0200930:	899ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc0200934:	00001697          	auipc	a3,0x1
ffffffffc0200938:	28c68693          	addi	a3,a3,652 # ffffffffc0201bc0 <etext+0x52a>
ffffffffc020093c:	00001617          	auipc	a2,0x1
ffffffffc0200940:	fb460613          	addi	a2,a2,-76 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200944:	15800593          	li	a1,344
ffffffffc0200948:	00001517          	auipc	a0,0x1
ffffffffc020094c:	fc050513          	addi	a0,a0,-64 # ffffffffc0201908 <etext+0x272>
ffffffffc0200950:	879ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200954:	00001697          	auipc	a3,0x1
ffffffffc0200958:	fcc68693          	addi	a3,a3,-52 # ffffffffc0201920 <etext+0x28a>
ffffffffc020095c:	00001617          	auipc	a2,0x1
ffffffffc0200960:	f9460613          	addi	a2,a2,-108 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200964:	11900593          	li	a1,281
ffffffffc0200968:	00001517          	auipc	a0,0x1
ffffffffc020096c:	fa050513          	addi	a0,a0,-96 # ffffffffc0201908 <etext+0x272>
ffffffffc0200970:	859ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200974:	00001697          	auipc	a3,0x1
ffffffffc0200978:	fec68693          	addi	a3,a3,-20 # ffffffffc0201960 <etext+0x2ca>
ffffffffc020097c:	00001617          	auipc	a2,0x1
ffffffffc0200980:	f7460613          	addi	a2,a2,-140 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200984:	0df00593          	li	a1,223
ffffffffc0200988:	00001517          	auipc	a0,0x1
ffffffffc020098c:	f8050513          	addi	a0,a0,-128 # ffffffffc0201908 <etext+0x272>
ffffffffc0200990:	839ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200994:	00001697          	auipc	a3,0x1
ffffffffc0200998:	fac68693          	addi	a3,a3,-84 # ffffffffc0201940 <etext+0x2aa>
ffffffffc020099c:	00001617          	auipc	a2,0x1
ffffffffc02009a0:	f5460613          	addi	a2,a2,-172 # ffffffffc02018f0 <etext+0x25a>
ffffffffc02009a4:	0de00593          	li	a1,222
ffffffffc02009a8:	00001517          	auipc	a0,0x1
ffffffffc02009ac:	f6050513          	addi	a0,a0,-160 # ffffffffc0201908 <etext+0x272>
ffffffffc02009b0:	819ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02009b4:	00001697          	auipc	a3,0x1
ffffffffc02009b8:	0b468693          	addi	a3,a3,180 # ffffffffc0201a68 <etext+0x3d2>
ffffffffc02009bc:	00001617          	auipc	a2,0x1
ffffffffc02009c0:	f3460613          	addi	a2,a2,-204 # ffffffffc02018f0 <etext+0x25a>
ffffffffc02009c4:	0fb00593          	li	a1,251
ffffffffc02009c8:	00001517          	auipc	a0,0x1
ffffffffc02009cc:	f4050513          	addi	a0,a0,-192 # ffffffffc0201908 <etext+0x272>
ffffffffc02009d0:	ff8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009d4:	00001697          	auipc	a3,0x1
ffffffffc02009d8:	fac68693          	addi	a3,a3,-84 # ffffffffc0201980 <etext+0x2ea>
ffffffffc02009dc:	00001617          	auipc	a2,0x1
ffffffffc02009e0:	f1460613          	addi	a2,a2,-236 # ffffffffc02018f0 <etext+0x25a>
ffffffffc02009e4:	0f900593          	li	a1,249
ffffffffc02009e8:	00001517          	auipc	a0,0x1
ffffffffc02009ec:	f2050513          	addi	a0,a0,-224 # ffffffffc0201908 <etext+0x272>
ffffffffc02009f0:	fd8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009f4:	00001697          	auipc	a3,0x1
ffffffffc02009f8:	f6c68693          	addi	a3,a3,-148 # ffffffffc0201960 <etext+0x2ca>
ffffffffc02009fc:	00001617          	auipc	a2,0x1
ffffffffc0200a00:	ef460613          	addi	a2,a2,-268 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200a04:	0f800593          	li	a1,248
ffffffffc0200a08:	00001517          	auipc	a0,0x1
ffffffffc0200a0c:	f0050513          	addi	a0,a0,-256 # ffffffffc0201908 <etext+0x272>
ffffffffc0200a10:	fb8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a14:	00001697          	auipc	a3,0x1
ffffffffc0200a18:	f2c68693          	addi	a3,a3,-212 # ffffffffc0201940 <etext+0x2aa>
ffffffffc0200a1c:	00001617          	auipc	a2,0x1
ffffffffc0200a20:	ed460613          	addi	a2,a2,-300 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200a24:	0f700593          	li	a1,247
ffffffffc0200a28:	00001517          	auipc	a0,0x1
ffffffffc0200a2c:	ee050513          	addi	a0,a0,-288 # ffffffffc0201908 <etext+0x272>
ffffffffc0200a30:	f98ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc0200a34:	00001697          	auipc	a3,0x1
ffffffffc0200a38:	04c68693          	addi	a3,a3,76 # ffffffffc0201a80 <etext+0x3ea>
ffffffffc0200a3c:	00001617          	auipc	a2,0x1
ffffffffc0200a40:	eb460613          	addi	a2,a2,-332 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200a44:	0f500593          	li	a1,245
ffffffffc0200a48:	00001517          	auipc	a0,0x1
ffffffffc0200a4c:	ec050513          	addi	a0,a0,-320 # ffffffffc0201908 <etext+0x272>
ffffffffc0200a50:	f78ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a54:	00001697          	auipc	a3,0x1
ffffffffc0200a58:	01468693          	addi	a3,a3,20 # ffffffffc0201a68 <etext+0x3d2>
ffffffffc0200a5c:	00001617          	auipc	a2,0x1
ffffffffc0200a60:	e9460613          	addi	a2,a2,-364 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200a64:	0f000593          	li	a1,240
ffffffffc0200a68:	00001517          	auipc	a0,0x1
ffffffffc0200a6c:	ea050513          	addi	a0,a0,-352 # ffffffffc0201908 <etext+0x272>
ffffffffc0200a70:	f58ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a74:	00001697          	auipc	a3,0x1
ffffffffc0200a78:	fd468693          	addi	a3,a3,-44 # ffffffffc0201a48 <etext+0x3b2>
ffffffffc0200a7c:	00001617          	auipc	a2,0x1
ffffffffc0200a80:	e7460613          	addi	a2,a2,-396 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200a84:	0e700593          	li	a1,231
ffffffffc0200a88:	00001517          	auipc	a0,0x1
ffffffffc0200a8c:	e8050513          	addi	a0,a0,-384 # ffffffffc0201908 <etext+0x272>
ffffffffc0200a90:	f38ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a94:	00001697          	auipc	a3,0x1
ffffffffc0200a98:	f9468693          	addi	a3,a3,-108 # ffffffffc0201a28 <etext+0x392>
ffffffffc0200a9c:	00001617          	auipc	a2,0x1
ffffffffc0200aa0:	e5460613          	addi	a2,a2,-428 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200aa4:	0e600593          	li	a1,230
ffffffffc0200aa8:	00001517          	auipc	a0,0x1
ffffffffc0200aac:	e6050513          	addi	a0,a0,-416 # ffffffffc0201908 <etext+0x272>
ffffffffc0200ab0:	f18ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0200ab4:	00001697          	auipc	a3,0x1
ffffffffc0200ab8:	0fc68693          	addi	a3,a3,252 # ffffffffc0201bb0 <etext+0x51a>
ffffffffc0200abc:	00001617          	auipc	a2,0x1
ffffffffc0200ac0:	e3460613          	addi	a2,a2,-460 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200ac4:	15700593          	li	a1,343
ffffffffc0200ac8:	00001517          	auipc	a0,0x1
ffffffffc0200acc:	e4050513          	addi	a0,a0,-448 # ffffffffc0201908 <etext+0x272>
ffffffffc0200ad0:	ef8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200ad4:	00001697          	auipc	a3,0x1
ffffffffc0200ad8:	ff468693          	addi	a3,a3,-12 # ffffffffc0201ac8 <etext+0x432>
ffffffffc0200adc:	00001617          	auipc	a2,0x1
ffffffffc0200ae0:	e1460613          	addi	a2,a2,-492 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200ae4:	14c00593          	li	a1,332
ffffffffc0200ae8:	00001517          	auipc	a0,0x1
ffffffffc0200aec:	e2050513          	addi	a0,a0,-480 # ffffffffc0201908 <etext+0x272>
ffffffffc0200af0:	ed8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200af4:	00001697          	auipc	a3,0x1
ffffffffc0200af8:	f7468693          	addi	a3,a3,-140 # ffffffffc0201a68 <etext+0x3d2>
ffffffffc0200afc:	00001617          	auipc	a2,0x1
ffffffffc0200b00:	df460613          	addi	a2,a2,-524 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200b04:	14600593          	li	a1,326
ffffffffc0200b08:	00001517          	auipc	a0,0x1
ffffffffc0200b0c:	e0050513          	addi	a0,a0,-512 # ffffffffc0201908 <etext+0x272>
ffffffffc0200b10:	eb8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b14:	00001697          	auipc	a3,0x1
ffffffffc0200b18:	07c68693          	addi	a3,a3,124 # ffffffffc0201b90 <etext+0x4fa>
ffffffffc0200b1c:	00001617          	auipc	a2,0x1
ffffffffc0200b20:	dd460613          	addi	a2,a2,-556 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200b24:	14500593          	li	a1,325
ffffffffc0200b28:	00001517          	auipc	a0,0x1
ffffffffc0200b2c:	de050513          	addi	a0,a0,-544 # ffffffffc0201908 <etext+0x272>
ffffffffc0200b30:	e98ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200b34:	00001697          	auipc	a3,0x1
ffffffffc0200b38:	04c68693          	addi	a3,a3,76 # ffffffffc0201b80 <etext+0x4ea>
ffffffffc0200b3c:	00001617          	auipc	a2,0x1
ffffffffc0200b40:	db460613          	addi	a2,a2,-588 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200b44:	13d00593          	li	a1,317
ffffffffc0200b48:	00001517          	auipc	a0,0x1
ffffffffc0200b4c:	dc050513          	addi	a0,a0,-576 # ffffffffc0201908 <etext+0x272>
ffffffffc0200b50:	e78ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b54:	00001697          	auipc	a3,0x1
ffffffffc0200b58:	01468693          	addi	a3,a3,20 # ffffffffc0201b68 <etext+0x4d2>
ffffffffc0200b5c:	00001617          	auipc	a2,0x1
ffffffffc0200b60:	d9460613          	addi	a2,a2,-620 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200b64:	13c00593          	li	a1,316
ffffffffc0200b68:	00001517          	auipc	a0,0x1
ffffffffc0200b6c:	da050513          	addi	a0,a0,-608 # ffffffffc0201908 <etext+0x272>
ffffffffc0200b70:	e58ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200b74:	00001697          	auipc	a3,0x1
ffffffffc0200b78:	fd468693          	addi	a3,a3,-44 # ffffffffc0201b48 <etext+0x4b2>
ffffffffc0200b7c:	00001617          	auipc	a2,0x1
ffffffffc0200b80:	d7460613          	addi	a2,a2,-652 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200b84:	13b00593          	li	a1,315
ffffffffc0200b88:	00001517          	auipc	a0,0x1
ffffffffc0200b8c:	d8050513          	addi	a0,a0,-640 # ffffffffc0201908 <etext+0x272>
ffffffffc0200b90:	e38ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200b94:	00001697          	auipc	a3,0x1
ffffffffc0200b98:	f8468693          	addi	a3,a3,-124 # ffffffffc0201b18 <etext+0x482>
ffffffffc0200b9c:	00001617          	auipc	a2,0x1
ffffffffc0200ba0:	d5460613          	addi	a2,a2,-684 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200ba4:	13900593          	li	a1,313
ffffffffc0200ba8:	00001517          	auipc	a0,0x1
ffffffffc0200bac:	d6050513          	addi	a0,a0,-672 # ffffffffc0201908 <etext+0x272>
ffffffffc0200bb0:	e18ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200bb4:	00001697          	auipc	a3,0x1
ffffffffc0200bb8:	f4c68693          	addi	a3,a3,-180 # ffffffffc0201b00 <etext+0x46a>
ffffffffc0200bbc:	00001617          	auipc	a2,0x1
ffffffffc0200bc0:	d3460613          	addi	a2,a2,-716 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200bc4:	13800593          	li	a1,312
ffffffffc0200bc8:	00001517          	auipc	a0,0x1
ffffffffc0200bcc:	d4050513          	addi	a0,a0,-704 # ffffffffc0201908 <etext+0x272>
ffffffffc0200bd0:	df8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bd4:	00001697          	auipc	a3,0x1
ffffffffc0200bd8:	e9468693          	addi	a3,a3,-364 # ffffffffc0201a68 <etext+0x3d2>
ffffffffc0200bdc:	00001617          	auipc	a2,0x1
ffffffffc0200be0:	d1460613          	addi	a2,a2,-748 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200be4:	12c00593          	li	a1,300
ffffffffc0200be8:	00001517          	auipc	a0,0x1
ffffffffc0200bec:	d2050513          	addi	a0,a0,-736 # ffffffffc0201908 <etext+0x272>
ffffffffc0200bf0:	dd8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200bf4:	00001697          	auipc	a3,0x1
ffffffffc0200bf8:	ef468693          	addi	a3,a3,-268 # ffffffffc0201ae8 <etext+0x452>
ffffffffc0200bfc:	00001617          	auipc	a2,0x1
ffffffffc0200c00:	cf460613          	addi	a2,a2,-780 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200c04:	12300593          	li	a1,291
ffffffffc0200c08:	00001517          	auipc	a0,0x1
ffffffffc0200c0c:	d0050513          	addi	a0,a0,-768 # ffffffffc0201908 <etext+0x272>
ffffffffc0200c10:	db8ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc0200c14:	00001697          	auipc	a3,0x1
ffffffffc0200c18:	ec468693          	addi	a3,a3,-316 # ffffffffc0201ad8 <etext+0x442>
ffffffffc0200c1c:	00001617          	auipc	a2,0x1
ffffffffc0200c20:	cd460613          	addi	a2,a2,-812 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200c24:	12200593          	li	a1,290
ffffffffc0200c28:	00001517          	auipc	a0,0x1
ffffffffc0200c2c:	ce050513          	addi	a0,a0,-800 # ffffffffc0201908 <etext+0x272>
ffffffffc0200c30:	d98ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0200c34:	00001697          	auipc	a3,0x1
ffffffffc0200c38:	e9468693          	addi	a3,a3,-364 # ffffffffc0201ac8 <etext+0x432>
ffffffffc0200c3c:	00001617          	auipc	a2,0x1
ffffffffc0200c40:	cb460613          	addi	a2,a2,-844 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200c44:	10400593          	li	a1,260
ffffffffc0200c48:	00001517          	auipc	a0,0x1
ffffffffc0200c4c:	cc050513          	addi	a0,a0,-832 # ffffffffc0201908 <etext+0x272>
ffffffffc0200c50:	d78ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200c54:	00001697          	auipc	a3,0x1
ffffffffc0200c58:	e1468693          	addi	a3,a3,-492 # ffffffffc0201a68 <etext+0x3d2>
ffffffffc0200c5c:	00001617          	auipc	a2,0x1
ffffffffc0200c60:	c9460613          	addi	a2,a2,-876 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200c64:	10200593          	li	a1,258
ffffffffc0200c68:	00001517          	auipc	a0,0x1
ffffffffc0200c6c:	ca050513          	addi	a0,a0,-864 # ffffffffc0201908 <etext+0x272>
ffffffffc0200c70:	d58ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200c74:	00001697          	auipc	a3,0x1
ffffffffc0200c78:	e3468693          	addi	a3,a3,-460 # ffffffffc0201aa8 <etext+0x412>
ffffffffc0200c7c:	00001617          	auipc	a2,0x1
ffffffffc0200c80:	c7460613          	addi	a2,a2,-908 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200c84:	10100593          	li	a1,257
ffffffffc0200c88:	00001517          	auipc	a0,0x1
ffffffffc0200c8c:	c8050513          	addi	a0,a0,-896 # ffffffffc0201908 <etext+0x272>
ffffffffc0200c90:	d38ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200c94 <best_fit_alloc_pages>:
best_fit_alloc_pages(size_t n) {
ffffffffc0200c94:	1101                	addi	sp,sp,-32
ffffffffc0200c96:	ec06                	sd	ra,24(sp)
ffffffffc0200c98:	e822                	sd	s0,16(sp)
    assert(n > 0);
ffffffffc0200c9a:	c17d                	beqz	a0,ffffffffc0200d80 <best_fit_alloc_pages+0xec>
    if (n > nr_free) {
ffffffffc0200c9c:	00005697          	auipc	a3,0x5
ffffffffc0200ca0:	38c6a683          	lw	a3,908(a3) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200ca4:	85aa                	mv	a1,a0
        return NULL;
ffffffffc0200ca6:	4401                	li	s0,0
    if (n > nr_free) {
ffffffffc0200ca8:	02069793          	slli	a5,a3,0x20
ffffffffc0200cac:	9381                	srli	a5,a5,0x20
ffffffffc0200cae:	0ca7e463          	bltu	a5,a0,ffffffffc0200d76 <best_fit_alloc_pages+0xe2>
    cprintf("[Best-Fit] === Trying to allocate %lu pages ===\n", n);
ffffffffc0200cb2:	e02a                	sd	a0,0(sp)
ffffffffc0200cb4:	00001517          	auipc	a0,0x1
ffffffffc0200cb8:	f2450513          	addi	a0,a0,-220 # ffffffffc0201bd8 <etext+0x542>
ffffffffc0200cbc:	e436                	sd	a3,8(sp)
ffffffffc0200cbe:	c8aff0ef          	jal	ffffffffc0200148 <cprintf>
ffffffffc0200cc2:	00005617          	auipc	a2,0x5
ffffffffc0200cc6:	35660613          	addi	a2,a2,854 # ffffffffc0206018 <free_area>
ffffffffc0200cca:	661c                	ld	a5,8(a2)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ccc:	6582                	ld	a1,0(sp)
ffffffffc0200cce:	06c78863          	beq	a5,a2,ffffffffc0200d3e <best_fit_alloc_pages+0xaa>
    size_t min_size = nr_free + 1;
ffffffffc0200cd2:	66a2                	ld	a3,8(sp)
ffffffffc0200cd4:	2685                	addiw	a3,a3,1
ffffffffc0200cd6:	1682                	slli	a3,a3,0x20
ffffffffc0200cd8:	9281                	srli	a3,a3,0x20
        if (p->property >= n && p->property < min_size) {
ffffffffc0200cda:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200cde:	00b76763          	bltu	a4,a1,ffffffffc0200cec <best_fit_alloc_pages+0x58>
ffffffffc0200ce2:	00d77563          	bgeu	a4,a3,ffffffffc0200cec <best_fit_alloc_pages+0x58>
            min_size = p->property;
ffffffffc0200ce6:	86ba                	mv	a3,a4
        struct Page *p = le2page(le, page_link);
ffffffffc0200ce8:	fe878413          	addi	s0,a5,-24
ffffffffc0200cec:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cee:	fec796e3          	bne	a5,a2,ffffffffc0200cda <best_fit_alloc_pages+0x46>
    if (page != NULL) {
ffffffffc0200cf2:	c431                	beqz	s0,ffffffffc0200d3e <best_fit_alloc_pages+0xaa>
        if (page->property > n) {
ffffffffc0200cf4:	4808                	lw	a0,16(s0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200cf6:	6c18                	ld	a4,24(s0)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200cf8:	7014                	ld	a3,32(s0)
ffffffffc0200cfa:	02051793          	slli	a5,a0,0x20
ffffffffc0200cfe:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d00:	e714                	sd	a3,8(a4)
    next->prev = prev;
ffffffffc0200d02:	e298                	sd	a4,0(a3)
ffffffffc0200d04:	02f5f463          	bgeu	a1,a5,ffffffffc0200d2c <best_fit_alloc_pages+0x98>
            struct Page *p = page + n;
ffffffffc0200d08:	00259793          	slli	a5,a1,0x2
ffffffffc0200d0c:	97ae                	add	a5,a5,a1
ffffffffc0200d0e:	078e                	slli	a5,a5,0x3
ffffffffc0200d10:	97a2                	add	a5,a5,s0
            SetPageProperty(p);
ffffffffc0200d12:	0087b803          	ld	a6,8(a5)
            p->property = page->property - n;
ffffffffc0200d16:	9d0d                	subw	a0,a0,a1
ffffffffc0200d18:	cb88                	sw	a0,16(a5)
            SetPageProperty(p);
ffffffffc0200d1a:	00286513          	ori	a0,a6,2
ffffffffc0200d1e:	e788                	sd	a0,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200d20:	01878513          	addi	a0,a5,24
    prev->next = next->prev = elm;
ffffffffc0200d24:	e288                	sd	a0,0(a3)
ffffffffc0200d26:	e708                	sd	a0,8(a4)
    elm->next = next;
ffffffffc0200d28:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200d2a:	ef98                	sd	a4,24(a5)
        nr_free -= n;
ffffffffc0200d2c:	00005717          	auipc	a4,0x5
ffffffffc0200d30:	2fc72703          	lw	a4,764(a4) # ffffffffc0206028 <free_area+0x10>
        ClearPageProperty(page);
ffffffffc0200d34:	641c                	ld	a5,8(s0)
        nr_free -= n;
ffffffffc0200d36:	9f0d                	subw	a4,a4,a1
ffffffffc0200d38:	ca18                	sw	a4,16(a2)
        ClearPageProperty(page);
ffffffffc0200d3a:	9bf5                	andi	a5,a5,-3
ffffffffc0200d3c:	e41c                	sd	a5,8(s0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d3e:	00005617          	auipc	a2,0x5
ffffffffc0200d42:	33263603          	ld	a2,818(a2) # ffffffffc0206070 <pages>
ffffffffc0200d46:	ccccd7b7          	lui	a5,0xccccd
ffffffffc0200d4a:	ccd78793          	addi	a5,a5,-819 # ffffffffcccccccd <end+0xcac6c55>
ffffffffc0200d4e:	02079713          	slli	a4,a5,0x20
ffffffffc0200d52:	40c40633          	sub	a2,s0,a2
ffffffffc0200d56:	97ba                	add	a5,a5,a4
ffffffffc0200d58:	860d                	srai	a2,a2,0x3
ffffffffc0200d5a:	02f60633          	mul	a2,a2,a5
ffffffffc0200d5e:	00001797          	auipc	a5,0x1
ffffffffc0200d62:	32a7b783          	ld	a5,810(a5) # ffffffffc0202088 <nbase>
    cprintf("[Best-Fit] Allocated %lu pages at physical address: 0x%lx\n", n, page2pa(page));
ffffffffc0200d66:	00001517          	auipc	a0,0x1
ffffffffc0200d6a:	eaa50513          	addi	a0,a0,-342 # ffffffffc0201c10 <etext+0x57a>
ffffffffc0200d6e:	963e                	add	a2,a2,a5
ffffffffc0200d70:	0632                	slli	a2,a2,0xc
ffffffffc0200d72:	bd6ff0ef          	jal	ffffffffc0200148 <cprintf>
}
ffffffffc0200d76:	60e2                	ld	ra,24(sp)
ffffffffc0200d78:	8522                	mv	a0,s0
ffffffffc0200d7a:	6442                	ld	s0,16(sp)
ffffffffc0200d7c:	6105                	addi	sp,sp,32
ffffffffc0200d7e:	8082                	ret
    assert(n > 0);
ffffffffc0200d80:	00001697          	auipc	a3,0x1
ffffffffc0200d84:	e5068693          	addi	a3,a3,-432 # ffffffffc0201bd0 <etext+0x53a>
ffffffffc0200d88:	00001617          	auipc	a2,0x1
ffffffffc0200d8c:	b6860613          	addi	a2,a2,-1176 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200d90:	07000593          	li	a1,112
ffffffffc0200d94:	00001517          	auipc	a0,0x1
ffffffffc0200d98:	b7450513          	addi	a0,a0,-1164 # ffffffffc0201908 <etext+0x272>
ffffffffc0200d9c:	c2cff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200da0 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200da0:	1141                	addi	sp,sp,-16
ffffffffc0200da2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200da4:	14058e63          	beqz	a1,ffffffffc0200f00 <best_fit_free_pages+0x160>
    for (; p != base + n; p ++) {
ffffffffc0200da8:	00259713          	slli	a4,a1,0x2
ffffffffc0200dac:	972e                	add	a4,a4,a1
ffffffffc0200dae:	070e                	slli	a4,a4,0x3
ffffffffc0200db0:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200db4:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200db6:	cf09                	beqz	a4,ffffffffc0200dd0 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200db8:	6798                	ld	a4,8(a5)
ffffffffc0200dba:	8b0d                	andi	a4,a4,3
ffffffffc0200dbc:	12071263          	bnez	a4,ffffffffc0200ee0 <best_fit_free_pages+0x140>
        p->flags = 0;
ffffffffc0200dc0:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200dc4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200dc8:	02878793          	addi	a5,a5,40
ffffffffc0200dcc:	fed796e3          	bne	a5,a3,ffffffffc0200db8 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc0200dd0:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc0200dd4:	00005717          	auipc	a4,0x5
ffffffffc0200dd8:	25472703          	lw	a4,596(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200ddc:	00005697          	auipc	a3,0x5
ffffffffc0200de0:	23c68693          	addi	a3,a3,572 # ffffffffc0206018 <free_area>
    return list->next == list;
ffffffffc0200de4:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200de6:	0028e613          	ori	a2,a7,2
    base->property = n;
ffffffffc0200dea:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dec:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200dee:	9f2d                	addw	a4,a4,a1
ffffffffc0200df0:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200df2:	0ad78763          	beq	a5,a3,ffffffffc0200ea0 <best_fit_free_pages+0x100>
            struct Page* page = le2page(le, page_link);
ffffffffc0200df6:	fe878713          	addi	a4,a5,-24
ffffffffc0200dfa:	4801                	li	a6,0
ffffffffc0200dfc:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200e00:	00e56a63          	bltu	a0,a4,ffffffffc0200e14 <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc0200e04:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200e06:	06d70563          	beq	a4,a3,ffffffffc0200e70 <best_fit_free_pages+0xd0>
    struct Page *p = base;
ffffffffc0200e0a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200e0c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200e10:	fee57ae3          	bgeu	a0,a4,ffffffffc0200e04 <best_fit_free_pages+0x64>
ffffffffc0200e14:	00080463          	beqz	a6,ffffffffc0200e1c <best_fit_free_pages+0x7c>
ffffffffc0200e18:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200e1c:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200e20:	e390                	sd	a2,0(a5)
ffffffffc0200e22:	00c83423          	sd	a2,8(a6) # ff0008 <kern_entry-0xffffffffbf20fff8>
    elm->prev = prev;
ffffffffc0200e26:	01053c23          	sd	a6,24(a0)
    elm->next = next;
ffffffffc0200e2a:	f11c                	sd	a5,32(a0)
    if (le != &free_list) {
ffffffffc0200e2c:	02d80063          	beq	a6,a3,ffffffffc0200e4c <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0200e30:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200e34:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200e38:	020e1613          	slli	a2,t3,0x20
ffffffffc0200e3c:	9201                	srli	a2,a2,0x20
ffffffffc0200e3e:	00261713          	slli	a4,a2,0x2
ffffffffc0200e42:	9732                	add	a4,a4,a2
ffffffffc0200e44:	070e                	slli	a4,a4,0x3
ffffffffc0200e46:	971a                	add	a4,a4,t1
ffffffffc0200e48:	02e50e63          	beq	a0,a4,ffffffffc0200e84 <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200e4c:	00d78f63          	beq	a5,a3,ffffffffc0200e6a <best_fit_free_pages+0xca>
        if (base + base->property == p) {
ffffffffc0200e50:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc0200e52:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0200e56:	02059613          	slli	a2,a1,0x20
ffffffffc0200e5a:	9201                	srli	a2,a2,0x20
ffffffffc0200e5c:	00261713          	slli	a4,a2,0x2
ffffffffc0200e60:	9732                	add	a4,a4,a2
ffffffffc0200e62:	070e                	slli	a4,a4,0x3
ffffffffc0200e64:	972a                	add	a4,a4,a0
ffffffffc0200e66:	04e68a63          	beq	a3,a4,ffffffffc0200eba <best_fit_free_pages+0x11a>
}
ffffffffc0200e6a:	60a2                	ld	ra,8(sp)
ffffffffc0200e6c:	0141                	addi	sp,sp,16
ffffffffc0200e6e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200e70:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200e72:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200e74:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e76:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e78:	8332                	mv	t1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e7a:	02d70c63          	beq	a4,a3,ffffffffc0200eb2 <best_fit_free_pages+0x112>
ffffffffc0200e7e:	4805                	li	a6,1
    struct Page *p = base;
ffffffffc0200e80:	87ba                	mv	a5,a4
ffffffffc0200e82:	b769                	j	ffffffffc0200e0c <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200e84:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e88:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200e8c:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200e90:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200e94:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200e98:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200e9c:	851a                	mv	a0,t1
ffffffffc0200e9e:	b77d                	j	ffffffffc0200e4c <best_fit_free_pages+0xac>
}
ffffffffc0200ea0:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200ea2:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200ea6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200ea8:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200eaa:	e398                	sd	a4,0(a5)
ffffffffc0200eac:	e798                	sd	a4,8(a5)
}
ffffffffc0200eae:	0141                	addi	sp,sp,16
ffffffffc0200eb0:	8082                	ret
    return listelm->prev;
ffffffffc0200eb2:	883e                	mv	a6,a5
ffffffffc0200eb4:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200eb6:	87b6                	mv	a5,a3
ffffffffc0200eb8:	bf95                	j	ffffffffc0200e2c <best_fit_free_pages+0x8c>
            base->property += p->property;
ffffffffc0200eba:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200ebe:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200ec2:	0007b803          	ld	a6,0(a5)
ffffffffc0200ec6:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200ec8:	9ead                	addw	a3,a3,a1
ffffffffc0200eca:	c914                	sw	a3,16(a0)
            ClearPageProperty(p);
ffffffffc0200ecc:	9b75                	andi	a4,a4,-3
ffffffffc0200ece:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200ed2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200ed4:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200ed8:	01063023          	sd	a6,0(a2)
ffffffffc0200edc:	0141                	addi	sp,sp,16
ffffffffc0200ede:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ee0:	00001697          	auipc	a3,0x1
ffffffffc0200ee4:	d7068693          	addi	a3,a3,-656 # ffffffffc0201c50 <etext+0x5ba>
ffffffffc0200ee8:	00001617          	auipc	a2,0x1
ffffffffc0200eec:	a0860613          	addi	a2,a2,-1528 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200ef0:	09b00593          	li	a1,155
ffffffffc0200ef4:	00001517          	auipc	a0,0x1
ffffffffc0200ef8:	a1450513          	addi	a0,a0,-1516 # ffffffffc0201908 <etext+0x272>
ffffffffc0200efc:	accff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200f00:	00001697          	auipc	a3,0x1
ffffffffc0200f04:	cd068693          	addi	a3,a3,-816 # ffffffffc0201bd0 <etext+0x53a>
ffffffffc0200f08:	00001617          	auipc	a2,0x1
ffffffffc0200f0c:	9e860613          	addi	a2,a2,-1560 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200f10:	09800593          	li	a1,152
ffffffffc0200f14:	00001517          	auipc	a0,0x1
ffffffffc0200f18:	9f450513          	addi	a0,a0,-1548 # ffffffffc0201908 <etext+0x272>
ffffffffc0200f1c:	aacff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0200f20 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200f20:	1141                	addi	sp,sp,-16
ffffffffc0200f22:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f24:	c9e9                	beqz	a1,ffffffffc0200ff6 <best_fit_init_memmap+0xd6>
    for (; p != base + n; p ++) {
ffffffffc0200f26:	00259713          	slli	a4,a1,0x2
ffffffffc0200f2a:	972e                	add	a4,a4,a1
ffffffffc0200f2c:	070e                	slli	a4,a4,0x3
ffffffffc0200f2e:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0200f32:	87aa                	mv	a5,a0
    for (; p != base + n; p ++) {
ffffffffc0200f34:	cf11                	beqz	a4,ffffffffc0200f50 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200f36:	6798                	ld	a4,8(a5)
ffffffffc0200f38:	8b05                	andi	a4,a4,1
ffffffffc0200f3a:	cf51                	beqz	a4,ffffffffc0200fd6 <best_fit_init_memmap+0xb6>
        p->flags = p->property = 0;
ffffffffc0200f3c:	0007a823          	sw	zero,16(a5)
ffffffffc0200f40:	0007b423          	sd	zero,8(a5)
ffffffffc0200f44:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f48:	02878793          	addi	a5,a5,40
ffffffffc0200f4c:	fed795e3          	bne	a5,a3,ffffffffc0200f36 <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200f50:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200f52:	00005717          	auipc	a4,0x5
ffffffffc0200f56:	0d672703          	lw	a4,214(a4) # ffffffffc0206028 <free_area+0x10>
ffffffffc0200f5a:	00005697          	auipc	a3,0x5
ffffffffc0200f5e:	0be68693          	addi	a3,a3,190 # ffffffffc0206018 <free_area>
    return list->next == list;
ffffffffc0200f62:	669c                	ld	a5,8(a3)
    SetPageProperty(base);
ffffffffc0200f64:	00266613          	ori	a2,a2,2
    base->property = n;
ffffffffc0200f68:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f6a:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200f6c:	9f2d                	addw	a4,a4,a1
ffffffffc0200f6e:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f70:	04d78663          	beq	a5,a3,ffffffffc0200fbc <best_fit_init_memmap+0x9c>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f74:	fe878713          	addi	a4,a5,-24
ffffffffc0200f78:	4581                	li	a1,0
ffffffffc0200f7a:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200f7e:	00e56a63          	bltu	a0,a4,ffffffffc0200f92 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200f82:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list) {
ffffffffc0200f84:	02d70263          	beq	a4,a3,ffffffffc0200fa8 <best_fit_init_memmap+0x88>
    struct Page *p = base;
ffffffffc0200f88:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f8a:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f8e:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f82 <best_fit_init_memmap+0x62>
ffffffffc0200f92:	c199                	beqz	a1,ffffffffc0200f98 <best_fit_init_memmap+0x78>
ffffffffc0200f94:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f98:	6398                	ld	a4,0(a5)
}
ffffffffc0200f9a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f9c:	e390                	sd	a2,0(a5)
ffffffffc0200f9e:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc0200fa0:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc0200fa2:	f11c                	sd	a5,32(a0)
ffffffffc0200fa4:	0141                	addi	sp,sp,16
ffffffffc0200fa6:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200fa8:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200faa:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200fac:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200fae:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200fb0:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200fb2:	00d70e63          	beq	a4,a3,ffffffffc0200fce <best_fit_init_memmap+0xae>
ffffffffc0200fb6:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc0200fb8:	87ba                	mv	a5,a4
ffffffffc0200fba:	bfc1                	j	ffffffffc0200f8a <best_fit_init_memmap+0x6a>
}
ffffffffc0200fbc:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200fbe:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0200fc2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fc4:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc0200fc6:	e398                	sd	a4,0(a5)
ffffffffc0200fc8:	e798                	sd	a4,8(a5)
}
ffffffffc0200fca:	0141                	addi	sp,sp,16
ffffffffc0200fcc:	8082                	ret
ffffffffc0200fce:	60a2                	ld	ra,8(sp)
ffffffffc0200fd0:	e290                	sd	a2,0(a3)
ffffffffc0200fd2:	0141                	addi	sp,sp,16
ffffffffc0200fd4:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200fd6:	00001697          	auipc	a3,0x1
ffffffffc0200fda:	ca268693          	addi	a3,a3,-862 # ffffffffc0201c78 <etext+0x5e2>
ffffffffc0200fde:	00001617          	auipc	a2,0x1
ffffffffc0200fe2:	91260613          	addi	a2,a2,-1774 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0200fe6:	04a00593          	li	a1,74
ffffffffc0200fea:	00001517          	auipc	a0,0x1
ffffffffc0200fee:	91e50513          	addi	a0,a0,-1762 # ffffffffc0201908 <etext+0x272>
ffffffffc0200ff2:	9d6ff0ef          	jal	ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0200ff6:	00001697          	auipc	a3,0x1
ffffffffc0200ffa:	bda68693          	addi	a3,a3,-1062 # ffffffffc0201bd0 <etext+0x53a>
ffffffffc0200ffe:	00001617          	auipc	a2,0x1
ffffffffc0201002:	8f260613          	addi	a2,a2,-1806 # ffffffffc02018f0 <etext+0x25a>
ffffffffc0201006:	04700593          	li	a1,71
ffffffffc020100a:	00001517          	auipc	a0,0x1
ffffffffc020100e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0201908 <etext+0x272>
ffffffffc0201012:	9b6ff0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc0201016 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201016:	00005797          	auipc	a5,0x5
ffffffffc020101a:	0327b783          	ld	a5,50(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc020101e:	6f9c                	ld	a5,24(a5)
ffffffffc0201020:	8782                	jr	a5

ffffffffc0201022 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201022:	00005797          	auipc	a5,0x5
ffffffffc0201026:	0267b783          	ld	a5,38(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc020102a:	739c                	ld	a5,32(a5)
ffffffffc020102c:	8782                	jr	a5

ffffffffc020102e <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc020102e:	00005797          	auipc	a5,0x5
ffffffffc0201032:	01a7b783          	ld	a5,26(a5) # ffffffffc0206048 <pmm_manager>
ffffffffc0201036:	779c                	ld	a5,40(a5)
ffffffffc0201038:	8782                	jr	a5

ffffffffc020103a <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020103a:	00001797          	auipc	a5,0x1
ffffffffc020103e:	e8678793          	addi	a5,a5,-378 # ffffffffc0201ec0 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201042:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201044:	7139                	addi	sp,sp,-64
ffffffffc0201046:	fc06                	sd	ra,56(sp)
ffffffffc0201048:	f822                	sd	s0,48(sp)
ffffffffc020104a:	f426                	sd	s1,40(sp)
ffffffffc020104c:	ec4e                	sd	s3,24(sp)
ffffffffc020104e:	f04a                	sd	s2,32(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201050:	00005417          	auipc	s0,0x5
ffffffffc0201054:	ff840413          	addi	s0,s0,-8 # ffffffffc0206048 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201058:	00001517          	auipc	a0,0x1
ffffffffc020105c:	c4850513          	addi	a0,a0,-952 # ffffffffc0201ca0 <etext+0x60a>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201060:	e01c                	sd	a5,0(s0)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201062:	8e6ff0ef          	jal	ffffffffc0200148 <cprintf>
    pmm_manager->init();
ffffffffc0201066:	601c                	ld	a5,0(s0)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201068:	00005497          	auipc	s1,0x5
ffffffffc020106c:	ff848493          	addi	s1,s1,-8 # ffffffffc0206060 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201070:	679c                	ld	a5,8(a5)
ffffffffc0201072:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201074:	57f5                	li	a5,-3
ffffffffc0201076:	07fa                	slli	a5,a5,0x1e
ffffffffc0201078:	e09c                	sd	a5,0(s1)
    uint64_t mem_begin = get_memory_base();
ffffffffc020107a:	ce0ff0ef          	jal	ffffffffc020055a <get_memory_base>
ffffffffc020107e:	89aa                	mv	s3,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201080:	ce4ff0ef          	jal	ffffffffc0200564 <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201084:	14050c63          	beqz	a0,ffffffffc02011dc <pmm_init+0x1a2>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201088:	00a98933          	add	s2,s3,a0
ffffffffc020108c:	e42a                	sd	a0,8(sp)
    cprintf("physcial memory map:\n");
ffffffffc020108e:	00001517          	auipc	a0,0x1
ffffffffc0201092:	c5a50513          	addi	a0,a0,-934 # ffffffffc0201ce8 <etext+0x652>
ffffffffc0201096:	8b2ff0ef          	jal	ffffffffc0200148 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020109a:	65a2                	ld	a1,8(sp)
ffffffffc020109c:	864e                	mv	a2,s3
ffffffffc020109e:	fff90693          	addi	a3,s2,-1
ffffffffc02010a2:	00001517          	auipc	a0,0x1
ffffffffc02010a6:	c5e50513          	addi	a0,a0,-930 # ffffffffc0201d00 <etext+0x66a>
ffffffffc02010aa:	89eff0ef          	jal	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc02010ae:	c80007b7          	lui	a5,0xc8000
ffffffffc02010b2:	85ca                	mv	a1,s2
ffffffffc02010b4:	0d27e263          	bltu	a5,s2,ffffffffc0201178 <pmm_init+0x13e>
ffffffffc02010b8:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010ba:	00006697          	auipc	a3,0x6
ffffffffc02010be:	fbd68693          	addi	a3,a3,-67 # ffffffffc0207077 <end+0xfff>
ffffffffc02010c2:	8efd                	and	a3,a3,a5
    npage = maxpa / PGSIZE;
ffffffffc02010c4:	81b1                	srli	a1,a1,0xc
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010c6:	fff80837          	lui	a6,0xfff80
    npage = maxpa / PGSIZE;
ffffffffc02010ca:	00005797          	auipc	a5,0x5
ffffffffc02010ce:	f8b7bf23          	sd	a1,-98(a5) # ffffffffc0206068 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010d2:	00005797          	auipc	a5,0x5
ffffffffc02010d6:	f8d7bf23          	sd	a3,-98(a5) # ffffffffc0206070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010da:	982e                	add	a6,a6,a1
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010dc:	88b6                	mv	a7,a3
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010de:	02080963          	beqz	a6,ffffffffc0201110 <pmm_init+0xd6>
ffffffffc02010e2:	00259613          	slli	a2,a1,0x2
ffffffffc02010e6:	962e                	add	a2,a2,a1
ffffffffc02010e8:	fec007b7          	lui	a5,0xfec00
ffffffffc02010ec:	97b6                	add	a5,a5,a3
ffffffffc02010ee:	060e                	slli	a2,a2,0x3
ffffffffc02010f0:	963e                	add	a2,a2,a5
ffffffffc02010f2:	87b6                	mv	a5,a3
        SetPageReserved(pages + i);
ffffffffc02010f4:	6798                	ld	a4,8(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010f6:	02878793          	addi	a5,a5,40 # fffffffffec00028 <end+0x3e9f9fb0>
        SetPageReserved(pages + i);
ffffffffc02010fa:	00176713          	ori	a4,a4,1
ffffffffc02010fe:	fee7b023          	sd	a4,-32(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201102:	fec799e3          	bne	a5,a2,ffffffffc02010f4 <pmm_init+0xba>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201106:	00281793          	slli	a5,a6,0x2
ffffffffc020110a:	97c2                	add	a5,a5,a6
ffffffffc020110c:	078e                	slli	a5,a5,0x3
ffffffffc020110e:	96be                	add	a3,a3,a5
ffffffffc0201110:	c02007b7          	lui	a5,0xc0200
ffffffffc0201114:	0af6e863          	bltu	a3,a5,ffffffffc02011c4 <pmm_init+0x18a>
ffffffffc0201118:	6098                	ld	a4,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020111a:	77fd                	lui	a5,0xfffff
ffffffffc020111c:	00f97933          	and	s2,s2,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201120:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc0201122:	0526ed63          	bltu	a3,s2,ffffffffc020117c <pmm_init+0x142>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201126:	601c                	ld	a5,0(s0)
ffffffffc0201128:	7b9c                	ld	a5,48(a5)
ffffffffc020112a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020112c:	00001517          	auipc	a0,0x1
ffffffffc0201130:	c5c50513          	addi	a0,a0,-932 # ffffffffc0201d88 <etext+0x6f2>
ffffffffc0201134:	814ff0ef          	jal	ffffffffc0200148 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201138:	00004597          	auipc	a1,0x4
ffffffffc020113c:	ec858593          	addi	a1,a1,-312 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201140:	00005797          	auipc	a5,0x5
ffffffffc0201144:	f0b7bc23          	sd	a1,-232(a5) # ffffffffc0206058 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201148:	c02007b7          	lui	a5,0xc0200
ffffffffc020114c:	0af5e463          	bltu	a1,a5,ffffffffc02011f4 <pmm_init+0x1ba>
ffffffffc0201150:	609c                	ld	a5,0(s1)
}
ffffffffc0201152:	7442                	ld	s0,48(sp)
ffffffffc0201154:	70e2                	ld	ra,56(sp)
ffffffffc0201156:	74a2                	ld	s1,40(sp)
ffffffffc0201158:	7902                	ld	s2,32(sp)
ffffffffc020115a:	69e2                	ld	s3,24(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020115c:	40f586b3          	sub	a3,a1,a5
ffffffffc0201160:	00005797          	auipc	a5,0x5
ffffffffc0201164:	eed7b823          	sd	a3,-272(a5) # ffffffffc0206050 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201168:	00001517          	auipc	a0,0x1
ffffffffc020116c:	c4050513          	addi	a0,a0,-960 # ffffffffc0201da8 <etext+0x712>
ffffffffc0201170:	8636                	mv	a2,a3
}
ffffffffc0201172:	6121                	addi	sp,sp,64
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201174:	fd5fe06f          	j	ffffffffc0200148 <cprintf>
    if (maxpa > KERNTOP) {
ffffffffc0201178:	85be                	mv	a1,a5
ffffffffc020117a:	bf3d                	j	ffffffffc02010b8 <pmm_init+0x7e>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020117c:	6705                	lui	a4,0x1
ffffffffc020117e:	177d                	addi	a4,a4,-1 # fff <kern_entry-0xffffffffc01ff001>
ffffffffc0201180:	96ba                	add	a3,a3,a4
ffffffffc0201182:	8efd                	and	a3,a3,a5
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201184:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201188:	02b7f263          	bgeu	a5,a1,ffffffffc02011ac <pmm_init+0x172>
    pmm_manager->init_memmap(base, n);
ffffffffc020118c:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc020118e:	fff80637          	lui	a2,0xfff80
ffffffffc0201192:	97b2                	add	a5,a5,a2
ffffffffc0201194:	00279513          	slli	a0,a5,0x2
ffffffffc0201198:	953e                	add	a0,a0,a5
ffffffffc020119a:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020119c:	40d90933          	sub	s2,s2,a3
ffffffffc02011a0:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02011a2:	00c95593          	srli	a1,s2,0xc
ffffffffc02011a6:	9546                	add	a0,a0,a7
ffffffffc02011a8:	9782                	jalr	a5
}
ffffffffc02011aa:	bfb5                	j	ffffffffc0201126 <pmm_init+0xec>
        panic("pa2page called with invalid pa");
ffffffffc02011ac:	00001617          	auipc	a2,0x1
ffffffffc02011b0:	bac60613          	addi	a2,a2,-1108 # ffffffffc0201d58 <etext+0x6c2>
ffffffffc02011b4:	06a00593          	li	a1,106
ffffffffc02011b8:	00001517          	auipc	a0,0x1
ffffffffc02011bc:	bc050513          	addi	a0,a0,-1088 # ffffffffc0201d78 <etext+0x6e2>
ffffffffc02011c0:	808ff0ef          	jal	ffffffffc02001c8 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011c4:	00001617          	auipc	a2,0x1
ffffffffc02011c8:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0201d30 <etext+0x69a>
ffffffffc02011cc:	05e00593          	li	a1,94
ffffffffc02011d0:	00001517          	auipc	a0,0x1
ffffffffc02011d4:	b0850513          	addi	a0,a0,-1272 # ffffffffc0201cd8 <etext+0x642>
ffffffffc02011d8:	ff1fe0ef          	jal	ffffffffc02001c8 <__panic>
        panic("DTB memory info not available");
ffffffffc02011dc:	00001617          	auipc	a2,0x1
ffffffffc02011e0:	adc60613          	addi	a2,a2,-1316 # ffffffffc0201cb8 <etext+0x622>
ffffffffc02011e4:	04600593          	li	a1,70
ffffffffc02011e8:	00001517          	auipc	a0,0x1
ffffffffc02011ec:	af050513          	addi	a0,a0,-1296 # ffffffffc0201cd8 <etext+0x642>
ffffffffc02011f0:	fd9fe0ef          	jal	ffffffffc02001c8 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011f4:	86ae                	mv	a3,a1
ffffffffc02011f6:	00001617          	auipc	a2,0x1
ffffffffc02011fa:	b3a60613          	addi	a2,a2,-1222 # ffffffffc0201d30 <etext+0x69a>
ffffffffc02011fe:	07900593          	li	a1,121
ffffffffc0201202:	00001517          	auipc	a0,0x1
ffffffffc0201206:	ad650513          	addi	a0,a0,-1322 # ffffffffc0201cd8 <etext+0x642>
ffffffffc020120a:	fbffe0ef          	jal	ffffffffc02001c8 <__panic>

ffffffffc020120e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020120e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201210:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201214:	f022                	sd	s0,32(sp)
ffffffffc0201216:	ec26                	sd	s1,24(sp)
ffffffffc0201218:	e84a                	sd	s2,16(sp)
ffffffffc020121a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020121c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201220:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201222:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201226:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020122a:	84aa                	mv	s1,a0
ffffffffc020122c:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc020122e:	03067d63          	bgeu	a2,a6,ffffffffc0201268 <printnum+0x5a>
ffffffffc0201232:	e44e                	sd	s3,8(sp)
ffffffffc0201234:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201236:	4785                	li	a5,1
ffffffffc0201238:	00e7d763          	bge	a5,a4,ffffffffc0201246 <printnum+0x38>
            putch(padc, putdat);
ffffffffc020123c:	85ca                	mv	a1,s2
ffffffffc020123e:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0201240:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201242:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201244:	fc65                	bnez	s0,ffffffffc020123c <printnum+0x2e>
ffffffffc0201246:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201248:	00001797          	auipc	a5,0x1
ffffffffc020124c:	ba078793          	addi	a5,a5,-1120 # ffffffffc0201de8 <etext+0x752>
ffffffffc0201250:	97d2                	add	a5,a5,s4
}
ffffffffc0201252:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201254:	0007c503          	lbu	a0,0(a5)
}
ffffffffc0201258:	70a2                	ld	ra,40(sp)
ffffffffc020125a:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020125c:	85ca                	mv	a1,s2
ffffffffc020125e:	87a6                	mv	a5,s1
}
ffffffffc0201260:	6942                	ld	s2,16(sp)
ffffffffc0201262:	64e2                	ld	s1,24(sp)
ffffffffc0201264:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201266:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201268:	03065633          	divu	a2,a2,a6
ffffffffc020126c:	8722                	mv	a4,s0
ffffffffc020126e:	fa1ff0ef          	jal	ffffffffc020120e <printnum>
ffffffffc0201272:	bfd9                	j	ffffffffc0201248 <printnum+0x3a>

ffffffffc0201274 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201274:	7119                	addi	sp,sp,-128
ffffffffc0201276:	f4a6                	sd	s1,104(sp)
ffffffffc0201278:	f0ca                	sd	s2,96(sp)
ffffffffc020127a:	ecce                	sd	s3,88(sp)
ffffffffc020127c:	e8d2                	sd	s4,80(sp)
ffffffffc020127e:	e4d6                	sd	s5,72(sp)
ffffffffc0201280:	e0da                	sd	s6,64(sp)
ffffffffc0201282:	f862                	sd	s8,48(sp)
ffffffffc0201284:	fc86                	sd	ra,120(sp)
ffffffffc0201286:	f8a2                	sd	s0,112(sp)
ffffffffc0201288:	fc5e                	sd	s7,56(sp)
ffffffffc020128a:	f466                	sd	s9,40(sp)
ffffffffc020128c:	f06a                	sd	s10,32(sp)
ffffffffc020128e:	ec6e                	sd	s11,24(sp)
ffffffffc0201290:	84aa                	mv	s1,a0
ffffffffc0201292:	8c32                	mv	s8,a2
ffffffffc0201294:	8a36                	mv	s4,a3
ffffffffc0201296:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201298:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020129c:	05500b13          	li	s6,85
ffffffffc02012a0:	00001a97          	auipc	s5,0x1
ffffffffc02012a4:	c58a8a93          	addi	s5,s5,-936 # ffffffffc0201ef8 <best_fit_pmm_manager+0x38>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012a8:	000c4503          	lbu	a0,0(s8)
ffffffffc02012ac:	001c0413          	addi	s0,s8,1
ffffffffc02012b0:	01350a63          	beq	a0,s3,ffffffffc02012c4 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc02012b4:	cd0d                	beqz	a0,ffffffffc02012ee <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc02012b6:	85ca                	mv	a1,s2
ffffffffc02012b8:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ba:	00044503          	lbu	a0,0(s0)
ffffffffc02012be:	0405                	addi	s0,s0,1
ffffffffc02012c0:	ff351ae3          	bne	a0,s3,ffffffffc02012b4 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc02012c4:	5cfd                	li	s9,-1
ffffffffc02012c6:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc02012c8:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc02012cc:	4b81                	li	s7,0
ffffffffc02012ce:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012d0:	00044683          	lbu	a3,0(s0)
ffffffffc02012d4:	00140c13          	addi	s8,s0,1
ffffffffc02012d8:	fdd6859b          	addiw	a1,a3,-35
ffffffffc02012dc:	0ff5f593          	zext.b	a1,a1
ffffffffc02012e0:	02bb6663          	bltu	s6,a1,ffffffffc020130c <vprintfmt+0x98>
ffffffffc02012e4:	058a                	slli	a1,a1,0x2
ffffffffc02012e6:	95d6                	add	a1,a1,s5
ffffffffc02012e8:	4198                	lw	a4,0(a1)
ffffffffc02012ea:	9756                	add	a4,a4,s5
ffffffffc02012ec:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02012ee:	70e6                	ld	ra,120(sp)
ffffffffc02012f0:	7446                	ld	s0,112(sp)
ffffffffc02012f2:	74a6                	ld	s1,104(sp)
ffffffffc02012f4:	7906                	ld	s2,96(sp)
ffffffffc02012f6:	69e6                	ld	s3,88(sp)
ffffffffc02012f8:	6a46                	ld	s4,80(sp)
ffffffffc02012fa:	6aa6                	ld	s5,72(sp)
ffffffffc02012fc:	6b06                	ld	s6,64(sp)
ffffffffc02012fe:	7be2                	ld	s7,56(sp)
ffffffffc0201300:	7c42                	ld	s8,48(sp)
ffffffffc0201302:	7ca2                	ld	s9,40(sp)
ffffffffc0201304:	7d02                	ld	s10,32(sp)
ffffffffc0201306:	6de2                	ld	s11,24(sp)
ffffffffc0201308:	6109                	addi	sp,sp,128
ffffffffc020130a:	8082                	ret
            putch('%', putdat);
ffffffffc020130c:	85ca                	mv	a1,s2
ffffffffc020130e:	02500513          	li	a0,37
ffffffffc0201312:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201314:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201318:	02500713          	li	a4,37
ffffffffc020131c:	8c22                	mv	s8,s0
ffffffffc020131e:	f8e785e3          	beq	a5,a4,ffffffffc02012a8 <vprintfmt+0x34>
ffffffffc0201322:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0201326:	1c7d                	addi	s8,s8,-1
ffffffffc0201328:	fee79de3          	bne	a5,a4,ffffffffc0201322 <vprintfmt+0xae>
ffffffffc020132c:	bfb5                	j	ffffffffc02012a8 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020132e:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0201332:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0201334:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0201338:	fd06071b          	addiw	a4,a2,-48
ffffffffc020133c:	24e56a63          	bltu	a0,a4,ffffffffc0201590 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0201340:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201342:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0201344:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0201348:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020134c:	0197073b          	addw	a4,a4,s9
ffffffffc0201350:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201354:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201356:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020135a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020135c:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201360:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc0201364:	feb570e3          	bgeu	a0,a1,ffffffffc0201344 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc0201368:	f60d54e3          	bgez	s10,ffffffffc02012d0 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc020136c:	8d66                	mv	s10,s9
ffffffffc020136e:	5cfd                	li	s9,-1
ffffffffc0201370:	b785                	j	ffffffffc02012d0 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201372:	8db6                	mv	s11,a3
ffffffffc0201374:	8462                	mv	s0,s8
ffffffffc0201376:	bfa9                	j	ffffffffc02012d0 <vprintfmt+0x5c>
ffffffffc0201378:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc020137a:	4b85                	li	s7,1
            goto reswitch;
ffffffffc020137c:	bf91                	j	ffffffffc02012d0 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc020137e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201380:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201384:	00f74463          	blt	a4,a5,ffffffffc020138c <vprintfmt+0x118>
    else if (lflag) {
ffffffffc0201388:	1a078763          	beqz	a5,ffffffffc0201536 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc020138c:	000a3603          	ld	a2,0(s4)
ffffffffc0201390:	46c1                	li	a3,16
ffffffffc0201392:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201394:	000d879b          	sext.w	a5,s11
ffffffffc0201398:	876a                	mv	a4,s10
ffffffffc020139a:	85ca                	mv	a1,s2
ffffffffc020139c:	8526                	mv	a0,s1
ffffffffc020139e:	e71ff0ef          	jal	ffffffffc020120e <printnum>
            break;
ffffffffc02013a2:	b719                	j	ffffffffc02012a8 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02013a4:	000a2503          	lw	a0,0(s4)
ffffffffc02013a8:	85ca                	mv	a1,s2
ffffffffc02013aa:	0a21                	addi	s4,s4,8
ffffffffc02013ac:	9482                	jalr	s1
            break;
ffffffffc02013ae:	bded                	j	ffffffffc02012a8 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02013b0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013b2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013b6:	00f74463          	blt	a4,a5,ffffffffc02013be <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc02013ba:	16078963          	beqz	a5,ffffffffc020152c <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc02013be:	000a3603          	ld	a2,0(s4)
ffffffffc02013c2:	46a9                	li	a3,10
ffffffffc02013c4:	8a2e                	mv	s4,a1
ffffffffc02013c6:	b7f9                	j	ffffffffc0201394 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc02013c8:	85ca                	mv	a1,s2
ffffffffc02013ca:	03000513          	li	a0,48
ffffffffc02013ce:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc02013d0:	85ca                	mv	a1,s2
ffffffffc02013d2:	07800513          	li	a0,120
ffffffffc02013d6:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02013d8:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc02013dc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02013de:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc02013e0:	bf55                	j	ffffffffc0201394 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc02013e2:	85ca                	mv	a1,s2
ffffffffc02013e4:	02500513          	li	a0,37
ffffffffc02013e8:	9482                	jalr	s1
            break;
ffffffffc02013ea:	bd7d                	j	ffffffffc02012a8 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc02013ec:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02013f0:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc02013f2:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc02013f4:	bf95                	j	ffffffffc0201368 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc02013f6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02013f8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02013fc:	00f74463          	blt	a4,a5,ffffffffc0201404 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0201400:	12078163          	beqz	a5,ffffffffc0201522 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0201404:	000a3603          	ld	a2,0(s4)
ffffffffc0201408:	46a1                	li	a3,8
ffffffffc020140a:	8a2e                	mv	s4,a1
ffffffffc020140c:	b761                	j	ffffffffc0201394 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020140e:	876a                	mv	a4,s10
ffffffffc0201410:	000d5363          	bgez	s10,ffffffffc0201416 <vprintfmt+0x1a2>
ffffffffc0201414:	4701                	li	a4,0
ffffffffc0201416:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020141a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020141c:	bd55                	j	ffffffffc02012d0 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020141e:	000d841b          	sext.w	s0,s11
ffffffffc0201422:	fd340793          	addi	a5,s0,-45
ffffffffc0201426:	00f037b3          	snez	a5,a5
ffffffffc020142a:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020142e:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0201432:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201434:	008a0793          	addi	a5,s4,8
ffffffffc0201438:	e43e                	sd	a5,8(sp)
ffffffffc020143a:	100d8c63          	beqz	s11,ffffffffc0201552 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020143e:	12071363          	bnez	a4,ffffffffc0201564 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201442:	000dc783          	lbu	a5,0(s11)
ffffffffc0201446:	0007851b          	sext.w	a0,a5
ffffffffc020144a:	c78d                	beqz	a5,ffffffffc0201474 <vprintfmt+0x200>
ffffffffc020144c:	0d85                	addi	s11,s11,1
ffffffffc020144e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201450:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201454:	000cc563          	bltz	s9,ffffffffc020145e <vprintfmt+0x1ea>
ffffffffc0201458:	3cfd                	addiw	s9,s9,-1
ffffffffc020145a:	008c8d63          	beq	s9,s0,ffffffffc0201474 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020145e:	020b9663          	bnez	s7,ffffffffc020148a <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc0201462:	85ca                	mv	a1,s2
ffffffffc0201464:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201466:	000dc783          	lbu	a5,0(s11)
ffffffffc020146a:	0d85                	addi	s11,s11,1
ffffffffc020146c:	3d7d                	addiw	s10,s10,-1
ffffffffc020146e:	0007851b          	sext.w	a0,a5
ffffffffc0201472:	f3ed                	bnez	a5,ffffffffc0201454 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc0201474:	01a05963          	blez	s10,ffffffffc0201486 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc0201478:	85ca                	mv	a1,s2
ffffffffc020147a:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc020147e:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc0201480:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc0201482:	fe0d1be3          	bnez	s10,ffffffffc0201478 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201486:	6a22                	ld	s4,8(sp)
ffffffffc0201488:	b505                	j	ffffffffc02012a8 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020148a:	3781                	addiw	a5,a5,-32
ffffffffc020148c:	fcfa7be3          	bgeu	s4,a5,ffffffffc0201462 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc0201490:	03f00513          	li	a0,63
ffffffffc0201494:	85ca                	mv	a1,s2
ffffffffc0201496:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201498:	000dc783          	lbu	a5,0(s11)
ffffffffc020149c:	0d85                	addi	s11,s11,1
ffffffffc020149e:	3d7d                	addiw	s10,s10,-1
ffffffffc02014a0:	0007851b          	sext.w	a0,a5
ffffffffc02014a4:	dbe1                	beqz	a5,ffffffffc0201474 <vprintfmt+0x200>
ffffffffc02014a6:	fa0cd9e3          	bgez	s9,ffffffffc0201458 <vprintfmt+0x1e4>
ffffffffc02014aa:	b7c5                	j	ffffffffc020148a <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02014ac:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014b0:	4619                	li	a2,6
            err = va_arg(ap, int);
ffffffffc02014b2:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02014b4:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc02014b8:	8fb9                	xor	a5,a5,a4
ffffffffc02014ba:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02014be:	02d64563          	blt	a2,a3,ffffffffc02014e8 <vprintfmt+0x274>
ffffffffc02014c2:	00001797          	auipc	a5,0x1
ffffffffc02014c6:	b8e78793          	addi	a5,a5,-1138 # ffffffffc0202050 <error_string>
ffffffffc02014ca:	00369713          	slli	a4,a3,0x3
ffffffffc02014ce:	97ba                	add	a5,a5,a4
ffffffffc02014d0:	639c                	ld	a5,0(a5)
ffffffffc02014d2:	cb99                	beqz	a5,ffffffffc02014e8 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc02014d4:	86be                	mv	a3,a5
ffffffffc02014d6:	00001617          	auipc	a2,0x1
ffffffffc02014da:	94260613          	addi	a2,a2,-1726 # ffffffffc0201e18 <etext+0x782>
ffffffffc02014de:	85ca                	mv	a1,s2
ffffffffc02014e0:	8526                	mv	a0,s1
ffffffffc02014e2:	0d8000ef          	jal	ffffffffc02015ba <printfmt>
ffffffffc02014e6:	b3c9                	j	ffffffffc02012a8 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02014e8:	00001617          	auipc	a2,0x1
ffffffffc02014ec:	92060613          	addi	a2,a2,-1760 # ffffffffc0201e08 <etext+0x772>
ffffffffc02014f0:	85ca                	mv	a1,s2
ffffffffc02014f2:	8526                	mv	a0,s1
ffffffffc02014f4:	0c6000ef          	jal	ffffffffc02015ba <printfmt>
ffffffffc02014f8:	bb45                	j	ffffffffc02012a8 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc02014fa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02014fc:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0201500:	00f74363          	blt	a4,a5,ffffffffc0201506 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0201504:	cf81                	beqz	a5,ffffffffc020151c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0201506:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020150a:	02044b63          	bltz	s0,ffffffffc0201540 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020150e:	8622                	mv	a2,s0
ffffffffc0201510:	8a5e                	mv	s4,s7
ffffffffc0201512:	46a9                	li	a3,10
ffffffffc0201514:	b541                	j	ffffffffc0201394 <vprintfmt+0x120>
            lflag ++;
ffffffffc0201516:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201518:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020151a:	bb5d                	j	ffffffffc02012d0 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020151c:	000a2403          	lw	s0,0(s4)
ffffffffc0201520:	b7ed                	j	ffffffffc020150a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0201522:	000a6603          	lwu	a2,0(s4)
ffffffffc0201526:	46a1                	li	a3,8
ffffffffc0201528:	8a2e                	mv	s4,a1
ffffffffc020152a:	b5ad                	j	ffffffffc0201394 <vprintfmt+0x120>
ffffffffc020152c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201530:	46a9                	li	a3,10
ffffffffc0201532:	8a2e                	mv	s4,a1
ffffffffc0201534:	b585                	j	ffffffffc0201394 <vprintfmt+0x120>
ffffffffc0201536:	000a6603          	lwu	a2,0(s4)
ffffffffc020153a:	46c1                	li	a3,16
ffffffffc020153c:	8a2e                	mv	s4,a1
ffffffffc020153e:	bd99                	j	ffffffffc0201394 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0201540:	85ca                	mv	a1,s2
ffffffffc0201542:	02d00513          	li	a0,45
ffffffffc0201546:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0201548:	40800633          	neg	a2,s0
ffffffffc020154c:	8a5e                	mv	s4,s7
ffffffffc020154e:	46a9                	li	a3,10
ffffffffc0201550:	b591                	j	ffffffffc0201394 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc0201552:	e329                	bnez	a4,ffffffffc0201594 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201554:	02800793          	li	a5,40
ffffffffc0201558:	853e                	mv	a0,a5
ffffffffc020155a:	00001d97          	auipc	s11,0x1
ffffffffc020155e:	8a7d8d93          	addi	s11,s11,-1881 # ffffffffc0201e01 <etext+0x76b>
ffffffffc0201562:	b5f5                	j	ffffffffc020144e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201564:	85e6                	mv	a1,s9
ffffffffc0201566:	856e                	mv	a0,s11
ffffffffc0201568:	0a4000ef          	jal	ffffffffc020160c <strnlen>
ffffffffc020156c:	40ad0d3b          	subw	s10,s10,a0
ffffffffc0201570:	01a05863          	blez	s10,ffffffffc0201580 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc0201574:	85ca                	mv	a1,s2
ffffffffc0201576:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201578:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc020157a:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020157c:	fe0d1ce3          	bnez	s10,ffffffffc0201574 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201580:	000dc783          	lbu	a5,0(s11)
ffffffffc0201584:	0007851b          	sext.w	a0,a5
ffffffffc0201588:	ec0792e3          	bnez	a5,ffffffffc020144c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020158c:	6a22                	ld	s4,8(sp)
ffffffffc020158e:	bb29                	j	ffffffffc02012a8 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201590:	8462                	mv	s0,s8
ffffffffc0201592:	bbd9                	j	ffffffffc0201368 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201594:	85e6                	mv	a1,s9
ffffffffc0201596:	00001517          	auipc	a0,0x1
ffffffffc020159a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0201e00 <etext+0x76a>
ffffffffc020159e:	06e000ef          	jal	ffffffffc020160c <strnlen>
ffffffffc02015a2:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015a6:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02015aa:	00001d97          	auipc	s11,0x1
ffffffffc02015ae:	856d8d93          	addi	s11,s11,-1962 # ffffffffc0201e00 <etext+0x76a>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015b2:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02015b4:	fda040e3          	bgtz	s10,ffffffffc0201574 <vprintfmt+0x300>
ffffffffc02015b8:	bd51                	j	ffffffffc020144c <vprintfmt+0x1d8>

ffffffffc02015ba <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015ba:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02015bc:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015c0:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015c2:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015c4:	ec06                	sd	ra,24(sp)
ffffffffc02015c6:	f83a                	sd	a4,48(sp)
ffffffffc02015c8:	fc3e                	sd	a5,56(sp)
ffffffffc02015ca:	e0c2                	sd	a6,64(sp)
ffffffffc02015cc:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02015ce:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015d0:	ca5ff0ef          	jal	ffffffffc0201274 <vprintfmt>
}
ffffffffc02015d4:	60e2                	ld	ra,24(sp)
ffffffffc02015d6:	6161                	addi	sp,sp,80
ffffffffc02015d8:	8082                	ret

ffffffffc02015da <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02015da:	00005717          	auipc	a4,0x5
ffffffffc02015de:	a3673703          	ld	a4,-1482(a4) # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02015e2:	4781                	li	a5,0
ffffffffc02015e4:	88ba                	mv	a7,a4
ffffffffc02015e6:	852a                	mv	a0,a0
ffffffffc02015e8:	85be                	mv	a1,a5
ffffffffc02015ea:	863e                	mv	a2,a5
ffffffffc02015ec:	00000073          	ecall
ffffffffc02015f0:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02015f2:	8082                	ret

ffffffffc02015f4 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02015f4:	00054783          	lbu	a5,0(a0)
ffffffffc02015f8:	cb81                	beqz	a5,ffffffffc0201608 <strlen+0x14>
    size_t cnt = 0;
ffffffffc02015fa:	4781                	li	a5,0
        cnt ++;
ffffffffc02015fc:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02015fe:	00f50733          	add	a4,a0,a5
ffffffffc0201602:	00074703          	lbu	a4,0(a4)
ffffffffc0201606:	fb7d                	bnez	a4,ffffffffc02015fc <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201608:	853e                	mv	a0,a5
ffffffffc020160a:	8082                	ret

ffffffffc020160c <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020160c:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020160e:	e589                	bnez	a1,ffffffffc0201618 <strnlen+0xc>
ffffffffc0201610:	a811                	j	ffffffffc0201624 <strnlen+0x18>
        cnt ++;
ffffffffc0201612:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201614:	00f58863          	beq	a1,a5,ffffffffc0201624 <strnlen+0x18>
ffffffffc0201618:	00f50733          	add	a4,a0,a5
ffffffffc020161c:	00074703          	lbu	a4,0(a4)
ffffffffc0201620:	fb6d                	bnez	a4,ffffffffc0201612 <strnlen+0x6>
ffffffffc0201622:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201624:	852e                	mv	a0,a1
ffffffffc0201626:	8082                	ret

ffffffffc0201628 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201628:	00054783          	lbu	a5,0(a0)
ffffffffc020162c:	e791                	bnez	a5,ffffffffc0201638 <strcmp+0x10>
ffffffffc020162e:	a01d                	j	ffffffffc0201654 <strcmp+0x2c>
ffffffffc0201630:	00054783          	lbu	a5,0(a0)
ffffffffc0201634:	cb99                	beqz	a5,ffffffffc020164a <strcmp+0x22>
ffffffffc0201636:	0585                	addi	a1,a1,1
ffffffffc0201638:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc020163c:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020163e:	fef709e3          	beq	a4,a5,ffffffffc0201630 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201642:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201646:	9d19                	subw	a0,a0,a4
ffffffffc0201648:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020164a:	0015c703          	lbu	a4,1(a1)
ffffffffc020164e:	4501                	li	a0,0
}
ffffffffc0201650:	9d19                	subw	a0,a0,a4
ffffffffc0201652:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201654:	0005c703          	lbu	a4,0(a1)
ffffffffc0201658:	4501                	li	a0,0
ffffffffc020165a:	b7f5                	j	ffffffffc0201646 <strcmp+0x1e>

ffffffffc020165c <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020165c:	ce01                	beqz	a2,ffffffffc0201674 <strncmp+0x18>
ffffffffc020165e:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201662:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201664:	cb91                	beqz	a5,ffffffffc0201678 <strncmp+0x1c>
ffffffffc0201666:	0005c703          	lbu	a4,0(a1)
ffffffffc020166a:	00f71763          	bne	a4,a5,ffffffffc0201678 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc020166e:	0505                	addi	a0,a0,1
ffffffffc0201670:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201672:	f675                	bnez	a2,ffffffffc020165e <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201674:	4501                	li	a0,0
ffffffffc0201676:	8082                	ret
ffffffffc0201678:	00054503          	lbu	a0,0(a0)
ffffffffc020167c:	0005c783          	lbu	a5,0(a1)
ffffffffc0201680:	9d1d                	subw	a0,a0,a5
}
ffffffffc0201682:	8082                	ret

ffffffffc0201684 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201684:	ca01                	beqz	a2,ffffffffc0201694 <memset+0x10>
ffffffffc0201686:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201688:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020168a:	0785                	addi	a5,a5,1
ffffffffc020168c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201690:	fef61de3          	bne	a2,a5,ffffffffc020168a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201694:	8082                	ret
