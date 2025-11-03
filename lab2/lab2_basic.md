# 实验二：物理内存管理

## 练习1：理解first-fit 连续物理内存分配算法（思考题）

### 函数分析：
- #### default_init
  初始化物理内存管理器，完成空闲链表和空闲页计数的初始化。
- #### default_init_memmap
  将一段连续的物理页（从 base 开始，共 n 页）初始化为空闲块，并加入空闲链表管理。其中空闲链表按物理地址升序排列，方便之后first-fit算法查找第一个页数足够的空闲块，也方便释放时合并相邻块。具体流程大致如下：
  1. 初始化n个连续物理页的状态
  2. 标记base作为空闲块头部页，空闲页总数加n
  3. 将空闲块按物理地址升序插入空闲链表
- #### default_alloc_pages
  根据 First-Fit 算法分配 n 个连续的物理页。具体流程大致如下：
  1. 检查空闲页是否充足，不足则返回 NULL
  2. 遍历空闲链表，找到第一个页数>=n的空闲块，立即停止遍历
  3. 若找到合适的空闲块，将当前块从空闲链表中删除。若空闲块的页数大于请求页数，拆分剩余部分并重新加入空闲链表
- #### default_free_pages
  将一段连续的物理页（从 base 开始，共 n 页）释放，将其重新加入空闲链表，并合并相邻的空闲块。具体流程大致如下：
  1. 初始化释放的n个页的状态
  2. 标记base作为空闲块头部页，空闲页总数加n
  3. 将释放的空闲块按物理地址升序插入空闲链表（同default_init_memmap）
  4. 若相邻块与当前块地址连续，合并前后空闲块，更新头部页和块内页数
### 物理内存分配的过程：
1. 初始化：
  - 内核调用 pmm_init()，通过 init_pmm_manager() 将 pmm_manager 指向 default_pmm_manager；
  - 调用 default_init() 初始化空闲链表和空闲页计数；
  - 调用 page_init() 探测物理内存范围，再调用 default_init_memmap(base, n) 将可分配的连续物理页标记为空闲块，加入空闲链表。
2. 分配内存：
  - 内核调用 alloc_pages(n)，内存管理器指向调用 default_alloc_pages(n)；
  - 检查空闲页总数是否≥n，遍历空闲链表，找到第一个页数≥n的块；
  - 从链表中删除该块，若块有剩余则拆分并重新加入空闲链表；
  - 空闲页数减n，返回分配的块头部页。
3. 释放内存：
  - 内核调用 free_pages(base, n)，内存管理器指向调用 default_free_pages(base, n)；
  - 初始化释放的页，标记为空闲块并按地址升序插入链表；
  - 合并前后相邻的空闲块，空闲页数加n，更新头部页。
#### 问题：你的first fit算法是否有进一步的改进空间？
思路一：按块大小分组管理
将空闲块按大小划分为多个区间（例如，小块：1~4 页、中块：5~16 页、大块：17 页以上），每个区间维护一个独立的空闲链表。分配时优先在对应大小的链表中查找，若失败则切换到更大一级的空闲链表进行查找，这样可避免遍历整个链表。  

思路二：Next-Fit 算法
Next-Fit算是对first-fit的优化算法，即每次记录上次分配的位置，下次从该位置开始查找。这样可避免链表头部全是分配留下的小空闲块，影响后续的分配效率。

## 练习2：实现 Best-Fit 连续物理内存分配算法（需要编程）

### 代码实现
- #### best_fit_init_memmap
```
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(PageReserved(p));
        /*LAB2 EXERCISE 2: YOUR CODE*/ 
        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            /*LAB2 EXERCISE 2: YOUR CODE*/ 
            // 编写代码
            // 1、当base < page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            }
            // 2、当list_next(le) == &free_list时，若已经到达链表结尾，将base插入到链表尾部
            else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
}
```
  与default_pmm.c中实现基本一致，将一段连续的物理页（从 base 开始，共 n 页）初始化为空闲块，并按物理地址升序插入空闲链表。
- #### best_fit_alloc_pages
```
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0);
    if (n > nr_free) {
        return NULL;
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    size_t min_size = nr_free + 1;
    /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 下面的代码是first-fit的部分代码，请修改下面的代码改为best-fit
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量

    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n && p->property < min_size) {
            page = p;
            min_size = p->property;
        }
    }

    if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }

    return page;
}
```
  实现 Best-Fit 算法分配逻辑：遍历所有空闲块，找到最小且页数≥分配需求 n 的块，拆分（若块有剩余）后返回分配的块头部页。方法是引入min_size用于记录遍历时当前符合条件的最小空闲块的页数，每次遍历到更小的符合条件的最小空闲块，就将page设为该块的头部页并将min_size更新，遍历结束后page中存储的即是最小且页数≥分配需求 n 的块的头部页。处理分配剩余部分与first-fit相同。
- #### best_fit_free_pages
```
static void
best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    /*LAB2 EXERCISE 2: YOUR CODE*/ 
    // 编写代码
    // 具体来说就是设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
    base->property = n;
    SetPageProperty(base);
    nr_free += n;
    if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        /*LAB2 EXERCISE 2: YOUR CODE*/ 
        // 编写代码
        // 1、判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
        if (p + p->property == base) {
            // 2、首先更新前一个空闲页块的大小，加上当前页块的大小
            p->property += base->property;
            // 3、清除当前页块的属性标记，表示不再是空闲页块
            ClearPageProperty(base);
            // 4、从链表中删除当前页块
            list_del(&(base->page_link));
            // 5、将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块
            base = p;
        }
    }
    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
}
```
  与default_pmm.c中实现基本一致，将一段连续的物理页（从 base 开始，共 n 页）释放为空闲块，并按物理地址升序插入空闲链表，并合并相邻空闲块。
#### 问题：你的 Best-Fit 算法是否有进一步的改进空间？
 当前 best_fit_alloc_pages 为找到 “最小满足块”，需全线性遍历整个空闲链表。若系统长期运行后产生大量空闲块，分配效率会显著下降。  
 方法是尝试修改 best_fit_init_memmap 和 best_fit_free_pages 的链表插入逻辑，让每个空闲链表按块大小升序存储空闲块。分配时无需全遍历 —— 只需像first_fit算法一样从链表头部开始，找到第一个页数≥n的块即为最小满足块，直接退出遍历。
 
## 扩展练习Challenge：buddy system（伙伴系统）分配算法（需要编程）
 
详见lab2/kern/mm/buddy_system.markdown

## 扩展练习Challenge：任意大小的内存单元slub分配算法（需要编程）



## 扩展练习Challenge：硬件的可用物理内存范围的获取方法（思考题）


