# 伙伴系统内存分配器设计文档

## 1. 概述

### 1.1 设计目标
实现了一个基于伙伴系统（Buddy System）的内存分配器，用于操作系统内核的物理内存管理。伙伴系统通过将内存划分为2的幂次方大小的块，实现了高效的内存分配和碎片整理。


## 2. 数据结构设计

### 2.1 主要数据结构

```c
#define MAX_ORDER       12    // 最大阶数，支持最大块大小为 2^12 = 4096 页
#define BUDDY_NR_FREE   (MAX_ORDER + 1)  // 空闲链表数量

typedef struct {
    list_entry_t free_list[BUDDY_NR_FREE];  // 不同阶的空闲链表
    unsigned int nr_free[BUDDY_NR_FREE];    // 各阶空闲块数量
} buddy_free_area_t;
```

### 2.2 页结构属性
- `property`：记录当前内存块包含的连续页数（必须是2的幂）
- `flags`：使用`PageProperty`标志位标记块是否空闲

## 3. 核心算法设计

### 3.1 内存初始化 (`buddy_init_memmap`)

初始化所有页面的状态标志,将可用内存按最大可能的2的幂次方块进行划分.考虑地址对齐约束，确保每个块的起始地址对齐其大小.将划分的块加入到对应阶数的空闲链表中


支持非2的幂次方的初始内存大小,自动处理地址对齐要求，并且最大化初始内存块的尺寸。

### 3.2 内存分配 (`buddy_alloc_pages`)

**算法流程**：
1. 计算所需内存的最小阶数 `min_order`
2. 从 `min_order` 到 `MAX_ORDER` 搜索第一个足够大的空闲块
3. 采用**最佳适配**策略选择地址最小的合适块
4. 如果找到的块大于需求，将剩余部分重新释放回系统
5. 清理分配区间的所有页属性

**搜索策略**：
```c
// 在所有足够大的链表中查找地址最小的块
for (int i = min_order; i <= MAX_ORDER; i++) {
    list_entry_t *le = &free_array[i];
    for (list_entry_t *it = list_next(le); it != le; it = list_next(it)) {
        struct Page *p = le2page(it, page_link);
        if (p->property >= n) {
            if (best == NULL || p < best) best = p;  // 选择地址最小的块
        }
    }
}
```

### 3.3 内存释放 (`buddy_free_pages`)

**算法流程**：
1. 将释放的内存按2的幂次方大小进行分块
2. 对每个块尝试与伙伴块合并
3. 递归合并直到无法继续合并或达到最大块大小
4. 将最终合并的块插入对应阶数的空闲链表

**伙伴查找与合并**：
```c
static struct Page *find_buddy(struct Page *block, size_t size) {
    uintptr_t block_addr = (uintptr_t)block;
    uintptr_t buddy_addr = block_addr ^ (size * sizeof(struct Page));
    return (struct Page *)buddy_addr;
}

static bool is_buddy_free(struct Page *buddy, size_t size) {
    return PageProperty(buddy) && buddy->property == size;
}
```

## 4. 关键辅助函数

### 4.1 阶数计算
```c
static unsigned int get_order(size_t n) {
    unsigned int order = 0;
    size_t size = 1;
    while (size < n) {
        size <<= 1;
        order++;
    }
    return order > MAX_ORDER ? MAX_ORDER : order;
}
```

### 4.2 伙伴块定位
基于异或运算快速计算伙伴块地址，充分利用二进制地址特性。



## 5.伙伴系统检查函数


```
buddy_check()
├── 基础统计验证
├── buddy_basic_check() [基础功能测试]
└── 复杂场景测试 [综合压力测试]
```

### 5.1 基础检查函数 (buddy_basic_check)



#### 阶段1: 基础分配验证
```c
// 步骤1: 单页分配基础测试
assert((p0 = alloc_page()) != NULL);
assert((p1 = alloc_page()) != NULL);
assert((p2 = alloc_page()) != NULL);

// 验证分配的唯一性
assert(p0 != p1 && p0 != p2 && p1 != p2);

// 验证页面状态正确性
assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
assert(page2pa(p0) < npage * PGSIZE);  // 地址范围验证
```

**测试目标**：分配功能基本可用，分配页面不重叠，页面初始状态正确。

#### 阶段2: 隔离环境测试
```c
// 保存当前内存状态
list_entry_t free_array_store[BUDDY_NR_FREE];
unsigned int nr_free_store[BUDDY_NR_FREE];
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    free_array_store[i] = free_array[i];
    nr_free_store[i] = nr_free_array[i];
    list_init(&free_array[i]);  // 清空空闲链表
    nr_free_array[i] = 0;
}

// 验证在空系统中无法分配
assert(alloc_page() == NULL);
```


#### 阶段3: 释放与合并验证
```c
// 释放之前分配的页面
free_page(p0);
free_page(p1);
free_page(p2);

// 调试输出当前内存状态
cprintf("当前状态\n");
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    list_entry_t *le = &free_array[i];
    while ((le = list_next(le)) != &free_array[i]) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));  // 验证空闲标志
        cprintf("i =%d, p->property =%d\n", i, p->property);
    }
}

// 验证释放后总空闲页数
assert(buddy_nr_free_pages() == 3);
```

**关键验证点**：释放操作正确性，伙伴合并功能，空闲链表维护，计数器同步。

#### 阶段4: 重分配与地址验证
```c
// 重新分配页面
assert((p0 = alloc_page()) != NULL);
assert((p1 = alloc_page()) != NULL);
assert((p2 = alloc_page()) != NULL);

// 验证分配器行为一致性
assert(alloc_page() == NULL);  // 应无法分配第四页

// 特殊测试：释放后立即重分配
free_page(p0);
assert(!list_empty(&free_array[get_order(1)]) || buddy_nr_free_pages() > 0);

// 验证地址重用
struct Page *p;
assert((p = alloc_page()) == p0);  // 应重用刚刚释放的页面
```

**测试**：分配器确定性，地址重用策略，碎片整理效果。

#### 阶段5: 环境恢复
```c
// 恢复原始内存状态
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    free_array[i] = free_array_store[i];
    nr_free_array[i] = nr_free_store[i];
}

// 清理测试页面
free_page(p);
free_page(p1);
free_page(p2);
```

## 6. 综合检查函数 (buddy_check)

### 6.1 统计一致性验证

```c
// 遍历统计所有空闲块
int count = 0, total = 0;
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    list_entry_t *le = &free_array[i];
    while ((le = list_next(le)) != &free_array[i]) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));  // 确保所有块都标记为空闲
        count++;
        total += p->property;     // 累加所有空闲页数
    }
}

// 验证统计一致性
assert(total == buddy_nr_free_pages());
```

**验证**：链表遍历正确性，计数器同步性，数据结构一致性。

### 6.2 复杂分配模式测试

#### 场景1: 大块分配与部分释放
```c
struct Page *p0 = alloc_pages(8), *p1, *p2;
assert(p0 != NULL);
assert(!PageProperty(p0));  // 分配后应标记为非空闲

// 创建隔离测试环境
list_entry_t free_array_store[BUDDY_NR_FREE];
unsigned int nr_free_store[BUDDY_NR_FREE];
// ... 保存和清空现有状态

// 部分释放测试
free_pages(p0 + 2, 4);           // 释放中间4页
assert(alloc_pages(8) == NULL);  // 应无法分配8页连续空间
assert(PageProperty(p0 + 2));    // 释放区域应标记为空闲
```

**测试**：部分释放功能，碎片化场景处理，大块分配边界条件。

#### 场景2: 复杂合并验证
```c
// 分配4页应重用之前释放的区域
assert((p1 = alloc_pages(4)) != NULL);
assert(alloc_page() == NULL);     // 应无额外空间
assert(p0 + 2 == p1);            // 地址重用验证

// 交错释放测试
p2 = p0 + 1;
free_page(p0);                   // 释放首页
free_pages(p1, 4);               // 释放中间块
assert(PageProperty(p0) && p0->property == 1);  // 应正确合并

// 验证合并后的分配行为
assert((p0 = alloc_page()) == p2 - 1);  // 合并后地址变化
free_page(p0);
assert((p0 = alloc_pages(2)) == p2 + 1); // 不同大小分配测试
```

**合并逻辑测试**：
- 前后伙伴合并
- 不同大小块合并
- 合并后分配策略

### 6.3 资源回收验证

```c
// 恢复原始内存状态
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    free_array[i] = free_array_store[i];
    nr_free_array[i] = nr_free_store[i];
}

// 最终资源清理
free_pages(p0, 2);
free_page(p2);

// 验证资源完全回收
int remaining_total = total;
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    list_entry_t *le = &free_array[i];
    while ((le = list_next(le)) != &free_array[i]) {
        struct Page *p = le2page(le, page_link);
        remaining_total -= p->property;
    }
}
assert(remaining_total == 6);  // 验证测试前后状态一致性
```


```c
// 详细的状态输出用于调试
cprintf("当前状态\n");
for (int i = 0; i < BUDDY_NR_FREE; i++) {
    list_entry_t *le = &free_array[i];
    while ((le = list_next(le)) != &free_array[i]) {
        struct Page *p = le2page(le, page_link);
        cprintf("阶数%d: 地址%p, 大小%d\n", i, p, p->property);
    }
}
```


这个检查框架验证了实现的buddy_system内存分配器的各项功能，确保其在各种场景下的正确性。


## 9. 总结

本伙伴系统内存分配器提供了一个高效、可靠的物理内存管理解决方案。通过精心设计的数据结构和算法，在分配速度、碎片整理和实现复杂度之间取得了良好平衡，适合作为操作系统内核的核心内存管理器使用。