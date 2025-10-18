#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>


/* Buddy System constants */
#define MAX_ORDER       12    // 最大阶数
#define BUDDY_NR_FREE   (MAX_ORDER + 1)



/* Buddy System data structure */
typedef struct {
    list_entry_t free_list[BUDDY_NR_FREE];  // 不同阶的空闲链表
    unsigned int nr_free[BUDDY_NR_FREE];    // 各阶空闲块数量
} buddy_free_area_t;

static buddy_free_area_t buddy_free_area;

#define free_array (buddy_free_area.free_list)
#define nr_free_array (buddy_free_area.nr_free)


/* Helper: 从所有 free_array 列表中找到地址小于 key 的最大块（前驱），若无返回 NULL */
static struct Page *
find_prev_free_block(struct Page *key) {
	size_t best_idx = (size_t)-1;
	struct Page *best = NULL;
	for (int i = 0; i <= MAX_ORDER; i++) {
		list_entry_t *le = &free_array[i];
		for (list_entry_t *it = list_next(le); it != le; it = list_next(it)) {
			struct Page *p = le2page(it, page_link);
			if (p < key) {
				if (best == NULL || p > best) best = p;
			}
		}
	}
	return best;
}

/* Helper: 从所有 free_array 列表中找到地址大于 key 的最小块（后继），若无返回 NULL */
static struct Page *
find_next_free_block(struct Page *key) {
	struct Page *best = NULL;
	for (int i = 0; i <= MAX_ORDER; i++) {
		list_entry_t *le = &free_array[i];
		for (list_entry_t *it = list_next(le); it != le; it = list_next(it)) {
			struct Page *p = le2page(it, page_link);
			if (p > key) {
				if (best == NULL || p < best) best = p;
			}
		}
	}
	return best;
}

/* Helper functions */
/* 获取页的阶数 */
static unsigned int get_order(size_t n) {
    unsigned int order = 0;
    size_t size = 1;
    while (size < n) {
        size <<= 1;
        order++;
    }
    return order > MAX_ORDER ? MAX_ORDER : order;
}

/* 判断是否为2的幂次方 */
static bool is_power_of_two(size_t n) {
    return (n & (n - 1)) == 0;
}

/* 获取伙伴页的编号 */
static size_t get_buddy_number(struct Page *page, unsigned int order) {
    return (page - pages) / (1 << order);
}

static struct Page *get_buddy(struct Page *page, unsigned int order) {
    size_t buddy_num = get_buddy_number(page, order) ^ 1;
    return &pages[buddy_num << order];
}

static void
buddy_init(void) {
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        list_init(&free_array[i]);
        nr_free_array[i] = 0;
    }
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    /* 先初始化 base..base+n 的页面状态 */
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }

    /* 按对齐的 2 的幂分块加入 free_list（每个块头必须对其块大小对齐） */
    size_t rem = n;
    struct Page *cur = base;
    const size_t max_block = 1UL << MAX_ORDER;
    while (rem > 0) {
        size_t idx = cur - pages;
        size_t unit = 1;
        /* 扩大 unit 的前提：下一个更大块既不超过剩余页数，也满足对齐条件，并且不超过 max_block */
        while ((unit << 1) <= rem && ((idx & ((unit << 1) - 1)) == 0) && (unit << 1) <= max_block) {
            unit <<= 1;
        }
        unsigned int order = get_order(unit);
        cur->property = unit;
        SetPageProperty(cur);
        list_add(&free_array[order], &(cur->page_link));
        nr_free_array[order] ++;
        cur += unit;
        rem -= unit;
    }
}

// static struct Page *
// buddy_alloc_pages(size_t n) {
// 	assert(n > 0);

// 	/* 在所有 free_list 中查找地址最小的满足 p->property >= n 的块（first-fit by address） */
// 	struct Page *best = NULL;
// 	for (int i = 0; i <= MAX_ORDER; i++) {
// 		list_entry_t *le = &free_array[i];
// 		for (list_entry_t *it = list_next(le); it != le; it = list_next(it)) {
// 			struct Page *p = le2page(it, page_link);
// 			if (p->property >= n) {
// 				if (best == NULL || p < best) best = p;
// 			}
// 		}
// 	}
// 	if (!best) return NULL;

// 	/* 从所在链表中移除 best 并更新计数（使用 best->property 的 order 作为索引） */
// 	unsigned int bucket = get_order(best->property);
// 	size_t orig_size = best->property;
// 	list_del(&(best->page_link));
// 	if (nr_free_array[bucket] > 0) nr_free_array[bucket]--;

// 	/* 若块大于 n，则把尾部剩余部分变为新的空闲块插入 */
// 	if (orig_size > n) {
// 		struct Page *rem = best + n;
// 		size_t rem_sz = orig_size - n;
// 		rem->property = rem_sz;
// 		SetPageProperty(rem);
// 		unsigned int rem_bucket = get_order(rem_sz);
// 		list_add(&free_array[rem_bucket], &(rem->page_link));
// 		nr_free_array[rem_bucket] ++;
// 	}

// 	/* 删除所有位于 [best, best + n) 区间内的 free-list 头（它们可能来自 init 分解），并更新 nr_free_array */
// 	for (int i = 0; i <= MAX_ORDER; i++) {
// 		list_entry_t *le = &free_array[i];
// 		list_entry_t *it = list_next(le);
// 		while (it != le) {
// 			list_entry_t *next = list_next(it);
// 			struct Page *p = le2page(it, page_link);
// 			if (p >= best && p < best + n) {
// 				/* 从链表移除并更新计数，清除其 PageProperty */
// 				list_del(it);
// 				if (nr_free_array[i] > 0) nr_free_array[i]--;
// 				ClearPageProperty(p);
// 				p->property = 0;
// 			}
// 			it = next;
// 		}
// 	}

// 	/* 对分配区间的每一页清理 PageProperty 并确保引用计数/flags 合理（分配后这些页不应被标记为 PageProperty） */
// 	struct Page *pp;
// 	for (pp = best; pp < best + n; pp++) {
// 		ClearPageProperty(pp);
// 		pp->property = 0; /* 属性值仅在需要时由管理函数设置 */
// 		set_page_ref(pp, 0);
// 		/* 保持 flags 的其余位为0（已在 init/其它路径保证），这里不额外设置 PG_reserved */
// 	}

// 	/* 标记并返回分配块头 */
// 	best->property = n;
// 	/* 分配块头不应具有 PageProperty 标志（表示已分配） */
// 	ClearPageProperty(best);

// 	return best;
// }

// static void
// buddy_free_pages(struct Page *base, size_t n) {
// 	assert(n > 0);

// 	/* 基本清理与断言 */
// 	struct Page *pp = base;
// 	for (; pp != base + n; pp++) {
// 		assert(!PageReserved(pp) && !PageProperty(pp));
// 		pp->flags = 0;
// 		set_page_ref(pp, 0);
// 	}

// 	/* 将要释放的块先设为一个整体 */
// 	base->property = n;
// 	SetPageProperty(base);

// 	/* 尝试与前驱合并（可能多次） */
// 	while (1) {
// 		struct Page *pred = find_prev_free_block(base);
// 		if (!pred) break;
// 		/* 若 pred 与 base 连续，则合并 */
// 		if (pred + pred->property == base) {
// 			/* 从 pred 所在链表移除并更新计数 */
// 			unsigned int pred_bucket = get_order(pred->property);
// 			list_del(&(pred->page_link));
// 			if (nr_free_array[pred_bucket] > 0) nr_free_array[pred_bucket]--;
// 			/* 清除 pred 的 PageProperty（合并后用新的 base 保存属性） */
// 			ClearPageProperty(pred);
// 			/* 构造新的 base 为 pred（低地址）并合并大小 */
// 			base = pred;
// 			base->property += n; /* 注意：n 是第一次设定的大小，之后的合并会累加到 base->property */
// 			SetPageProperty(base);
// 			/* 更新 n 为合并后大小以便下一轮使用 */
// 			n = base->property;
// 			continue;
// 		}
// 		break;
// 	}

// 	/* 尝试与后继合并（可能多次） */
// 	while (1) {
// 		struct Page *succ = find_next_free_block(base);
// 		if (!succ) break;
// 		if (base + base->property == succ) {
// 			unsigned int succ_bucket = get_order(succ->property);
// 			list_del(&(succ->page_link));
// 			if (nr_free_array[succ_bucket] > 0) nr_free_array[succ_bucket]--;
// 			ClearPageProperty(succ);
// 			base->property += succ->property;
// 			SetPageProperty(base);
// 			n = base->property;
// 			continue;
// 		}
// 		break;
// 	}

// 	/* 最终把合并后的块加入对应 bucket 并更新计数 */
// 	unsigned int final_bucket = get_order(base->property);
// 	list_add(&free_array[final_bucket], &(base->page_link));
// 	nr_free_array[final_bucket] ++;
// }

/* 辅助函数：检查伙伴块是否空闲且大小匹配 */

static struct Page *
find_buddy(struct Page *block, size_t size) {
    if (size == 0) return NULL;
    
    /* 计算块的对齐地址 */
    uintptr_t block_addr = (uintptr_t)block;
    uintptr_t buddy_addr = block_addr ^ (size * sizeof(struct Page));
    
    /* 确保伙伴地址在有效范围内 */
    if (buddy_addr < (uintptr_t)pages || 
        buddy_addr >= (uintptr_t)(pages + npage * sizeof(struct Page))) {
        return NULL;
    }
    
    return (struct Page *)buddy_addr;
}

/* 辅助函数：检查伙伴块是否空闲且大小匹配 */
static bool
is_buddy_free(struct Page *buddy, size_t size) {
    return PageProperty(buddy) && buddy->property == size;
}
static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    /* 基本清理与断言 */
    struct Page *pp = base;
    for (; pp != base + n; pp++) {
        assert(!PageReserved(pp));
        assert(!PageProperty(pp));
        pp->flags = 0;
        set_page_ref(pp, 0);
    }

    /* 将要释放的块分解为2的幂次方大小的块 */
    size_t remaining = n;
    struct Page *current = base;
    
    while (remaining > 0) {
        /* 找到当前剩余部分能容纳的最大2的幂次方大小 */
        size_t chunk_size = 1;
        unsigned int order = 0;
        
        while (chunk_size * 2 <= remaining) {
            chunk_size <<= 1;
            order++;
            if (order >= MAX_ORDER) break;
        }
        
        /* 设置当前块的属性 */
        current->property = chunk_size;
        SetPageProperty(current);
        
        /* 尝试与相邻块合并 */
        struct Page *merged_block = current;
        size_t merged_size = chunk_size;
        bool merged;
        
        do {
            merged = 0;
            struct Page *buddy = find_buddy(merged_block, merged_size);
            if (buddy && is_buddy_free(buddy, merged_size)) {
                /* 从链表中移除buddy */
                unsigned int buddy_order = get_order(merged_size);
                list_del(&(buddy->page_link));
                if (nr_free_array[buddy_order] > 0) nr_free_array[buddy_order]--;
                ClearPageProperty(buddy);
                
                /* 合并到低地址的块 */
                if (buddy < merged_block) {
                    merged_block = buddy;
                }
                merged_size <<= 1;  /* 大小翻倍 */
                
                /* 更新合并后块的属性 */
                merged_block->property = merged_size;
                SetPageProperty(merged_block);
                merged = 1;
            }
        } while (merged && merged_size < (1 << MAX_ORDER));  /* 限制最大合并大小 */
        
        /* 将合并后的块插入对应链表 */
        unsigned int final_order = get_order(merged_size);
        list_add(&free_array[final_order], &(merged_block->page_link));
        nr_free_array[final_order]++;
        
        /* 移动到下一个块 - 关键修复：使用chunk_size而不是merged_size */
        current += chunk_size;
        remaining -= chunk_size;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);

    /* 计算最小需要的order，从该order开始搜索 */
    unsigned int min_order = get_order(n);
    struct Page *best = NULL;
    
    /* 在所有足够大的free_list中查找地址最小的满足条件的块 */
    for (int i = min_order; i <= MAX_ORDER; i++) {
        list_entry_t *le = &free_array[i];
        for (list_entry_t *it = list_next(le); it != le; it = list_next(it)) {
            struct Page *p = le2page(it, page_link);
            if (p->property >= n) {
                if (best == NULL || p < best) best = p;
            }
        }
    }
    if (!best) return NULL;

    /* 从所在链表中移除best并更新计数 */
    unsigned int bucket = get_order(best->property);
    size_t orig_size = best->property;
    list_del(&(best->page_link));
    if (nr_free_array[bucket] > 0) nr_free_array[bucket]--;

    /* 若块大于n，则把尾部剩余部分用buddy_free_pages释放 */
    if (orig_size > n) {
        struct Page *rem = best + n;
        size_t rem_sz = orig_size - n;
        /* 使用buddy_free_pages来释放剩余部分 */
        ClearPageProperty(rem);
        buddy_free_pages(rem, rem_sz);
    }

    /* 删除所有位于[best, best + n)区间内的free-list头 */
    for (int i = 0; i <= MAX_ORDER; i++) {
        list_entry_t *le = &free_array[i];
        list_entry_t *it = list_next(le);
        while (it != le) {
            list_entry_t *next = list_next(it);
            struct Page *p = le2page(it, page_link);
            if (p >= best && p < best + n) {
                list_del(it);
                if (nr_free_array[i] > 0) nr_free_array[i]--;
                ClearPageProperty(p);
                p->property = 0;
            }
            it = next;
        }
    }

    /* 对分配区间的每一页清理属性 */
    struct Page *pp;
    for (pp = best; pp < best + n; pp++) {
        ClearPageProperty(pp);
        pp->property = 0;
        set_page_ref(pp, 0);
    }

    /* 标记并返回分配块头 */
    best->property = n;
    ClearPageProperty(best);

    return best;
}



static size_t
buddy_nr_free_pages(void) {
	size_t total = 0;
	for (int i = 0; i <= MAX_ORDER; i++) {
		list_entry_t *le = &free_array[i];
		for (list_entry_t *it = list_next(le); it != le; it = list_next(it)) {
			struct Page *p = le2page(it, page_link);
			total += p->property;
		}
	}
	return total;
}

static void
buddy_basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    cprintf("1");
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 保存并清空当前 free lists
    list_entry_t free_array_store[BUDDY_NR_FREE];
    unsigned int nr_free_store[BUDDY_NR_FREE];
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        free_array_store[i] = free_array[i];
        nr_free_store[i] = nr_free_array[i];
        list_init(&free_array[i]);
        nr_free_array[i] = 0;
    }
    cprintf("2");
    assert(alloc_page() == NULL);
    cprintf("3");
    free_page(p0);
    free_page(p1);
    free_page(p2);
    cprintf("3");
    cprintf("当前状态\n");
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        list_entry_t *le = &free_array[i];
        while ((le = list_next(le)) != &free_array[i]) {
            cprintf("i =%d   ",i );
            
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            cprintf("p->property =%d  \n ",p->property );
            assert(PageProperty(p));
           
            
            
        }
    }
    // 释放后应有3页空闲
    assert(buddy_nr_free_pages() == 3);
    cprintf("4");
    assert((p0 = alloc_page()) != NULL);
    cprintf("分配p0状态\n");
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        list_entry_t *le = &free_array[i];
        while ((le = list_next(le)) != &free_array[i]) {
            cprintf("i =%d   ",i );
            
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            cprintf("p->property =%d  \n ",p->property );
            assert(PageProperty(p));
           
            
            
        }
    }
    cprintf("5");
    assert((p1 = alloc_page()) != NULL);
    cprintf("6");
    assert((p2 = alloc_page()) != NULL);
    cprintf("4");
    assert(alloc_page() == NULL);
    cprintf("3");
    free_page(p0);
    cprintf("3");
    assert(!list_empty(&free_array[get_order(1)]) || buddy_nr_free_pages() > 0);
    cprintf("3");
    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL);
    cprintf("3");
    // 恢复 free lists
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        free_array[i] = free_array_store[i];
        nr_free_array[i] = nr_free_store[i];
    }

    free_page(p);
    free_page(p1);
    free_page(p2);
    cprintf("3");
}

//综合检查，参考 default_pmm 的 default_check 结构
static void
buddy_check(void) {
    cprintf("check begin");
    int count = 0, total = 0;
    // 统计所有 free list 中的 property 总和
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        list_entry_t *le = &free_array[i];
        while ((le = list_next(le)) != &free_array[i]) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            count++;
            total += p->property;
        }
    }
    assert(total == buddy_nr_free_pages());
    cprintf("basic check begin!");
    // 基本单页分配/释放检查
    buddy_basic_check();
    cprintf("basic check finished!");
    // 更复杂的分配/释放组合测试（大致复刻 default_check 的流程）
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    // assert(p0 != NULL);
    // assert(!PageProperty(p0));

    // // 保存并清空所有 free lists
    // list_entry_t free_array_store[BUDDY_NR_FREE];
    // unsigned int nr_free_store[BUDDY_NR_FREE];
    // for (int i = 0; i < BUDDY_NR_FREE; i++) {
    //     free_array_store[i] = free_array[i];
    //     nr_free_store[i] = nr_free_array[i];
    //     list_init(&free_array[i]);
    //     nr_free_array[i] = 0;
    // }
    // assert(alloc_page() == NULL);

    // // for (int i = 0; i < BUDDY_NR_FREE; i++) {
    // //     nr_free_store[i] = nr_free_array[i];
    // // }

    // // 释放中间部分并测试无法分配大块
    // free_pages(p0 + 2, 3);
    // assert(alloc_pages(4) == NULL);
    // assert(PageProperty(p0 + 2));
    // cprintf("p0[2].property =%d",p0[2].property);
    // //assert(p0[2].property == 3);
    // //assert((p1 = alloc_pages(3)) != NULL);
    // //assert(alloc_page() == NULL);
    // //assert(p0 + 2 == p1);

    // p2 = p0 + 1;
    // free_page(p0);
    // //free_pages(p1, 3);
    // assert(PageProperty(p0) && p0->property == 1);
    // //assert(PageProperty(p1) && p1->property == 3);

    // assert((p0 = alloc_page()) == p2 - 1);
    // free_page(p0);
    // assert((p0 = alloc_pages(2)) == p2 + 1);

    // free_pages(p0, 2);
    // free_page(p2);

    // //assert((p0 = alloc_pages(5)) != NULL);
    // //assert(alloc_page() == NULL);

    // // 恢复原来的 free lists 与计数
    // for (int i = 0; i < BUDDY_NR_FREE; i++) {
    //     free_array[i] = free_array_store[i];
    //     nr_free_array[i] = nr_free_store[i];
    // }

    free_pages(p0, 5);

    // 最后核对先前计数是否被完全回收
    
    int remaining_total = total;
    for (int i = 0; i < BUDDY_NR_FREE; i++) {
        list_entry_t *le = &free_array[i];
        while ((le = list_next(le)) != &free_array[i]) {
            struct Page *p = le2page(le, page_link);
           
            remaining_total -= p->property;
        }
    }
    
    cprintf("remaining_total = %d\n",remaining_total );
    
    assert(remaining_total == 0);
}
//综合检查，参考 default_pmm 的 default_check 结构
// static void
// buddy_check(void) {
//     int count = 0, total = 0;
//     // 统计所有 free list 中的 property 总和
//     cprintf("分配前");
//    cprintf("当前状态");
//    for (int i = 0; i < BUDDY_NR_FREE; i++) {
//        list_entry_t *le = &free_array[i];
//        while ((le = list_next(le)) != &free_array[i]) {
//            cprintf("i =%d   ",i );
//            
//            struct Page *p = le2page(le, page_link);
//            cprintf("p->property =%d  \n ",p->property );
//            assert(PageProperty(p));
//            count++;
//            cprintf(" p->property =%d   ",p->property );
//            total += p->property;
//        }
//   }
//     assert(total == buddy_nr_free_pages());
//     struct Page *p0 = alloc_pages(5);
//     cprintf("分配后");
//     for (int i = 0; i < BUDDY_NR_FREE; i++) {
//         list_entry_t *le = &free_array[i];
//         while ((le = list_next(le)) != &free_array[i]) {
//             cprintf("i =%d   ",i );
            
//             struct Page *p = le2page(le, page_link);
//             cprintf("p->property =%d  \n ",p->property );
//             assert(PageProperty(p));
//         }
//     }
//     free_pages(p0, 5);
//     cprintf("释放后");
//     for (int i = 0; i < BUDDY_NR_FREE; i++) {
//         list_entry_t *le = &free_array[i];
//         while ((le = list_next(le)) != &free_array[i]) {
//             cprintf("i =%d   ",i );
            
//             struct Page *p = le2page(le, page_link);
//             cprintf("p->property =%d  \n ",p->property );
//             assert(PageProperty(p));
            
//         }
//     }
//     // 最后核对先前计数是否被完全回收
//     int remaining = count;
//     int remaining_total = total;
//     for (int i = 0; i < BUDDY_NR_FREE; i++) {
//         list_entry_t *le = &free_array[i];
//         while ((le = list_next(le)) != &free_array[i]) {
//             struct Page *p = le2page(le, page_link);
//             remaining--;
//             remaining_total -= p->property;
//         }
//     }
//     assert(remaining_total == 0);
// }

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check, 
};
