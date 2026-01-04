# ucore中UNIX PIPE机制和软硬连接机制设计方案

## 扩展练习 Challenge1：基于"UNIX的PIPE机制"的设计方案

### 1. 需求分析

PIPE是UNIX系统中重要的进程间通信机制，用于实现父子进程间或相关进程间的数据传递。管道提供字节流服务，具有以下特性：
- 半双工通信（单向数据流）
- 数据按照写入顺序读取
- 自动同步机制
- 有固定的缓冲区大小

### 2. 数据结构设计

#### 2.1 管道数据结构

```c
// 新增文件: kern/fs/pipe.h
#ifndef __KERN_FS_PIPE_H__
#define __KERN_FS_PIPE_H__

#include <defs.h>
#include <atomic.h>
#include <wait.h>
#include <sync.h>

// 管道缓冲区大小
#define PIPE_BUF_SIZE  4096
#define PIPE_MAX_SIZE  (PIPE_BUF_SIZE * 4)

// 管道状态
enum pipe_state {
    PIPE_EMPTY = 0,      // 管道为空
    PIPE_READY,          // 管道有数据但未满
    PIPE_FULL,           // 管道已满
    PIPE_CLOSED          // 管道已关闭
};

// 管道缓冲区结构
struct pipe_buffer {
    char data[PIPE_BUF_SIZE];    // 管道数据缓冲区
    atomic_t read_pos;           // 读位置
    atomic_t write_pos;          // 写位置
    atomic_t available;          // 可用字节数
    uint32_t flags;              // 管道标志
};

// 管道结构体
struct pipe_inode {
    struct inode *inode;         // 关联的inode
    struct pipe_buffer buffer;   // 管道缓冲区
    wait_queue_t read_queue;     // 读等待队列
    wait_queue_t write_queue;    // 写等待队列
    semaphore_t mutex;           // 互斥锁
    atomic_t ref_count;          // 引用计数
    enum pipe_state state;       // 管道状态
    bool readable;               // 是否可读
    bool writable;               // 是否可写
    struct list_entry pipe_link; // 管道链表节点
};

// 管道文件描述符
struct pipe_file {
    struct file *file;           // 关联的文件结构
    struct pipe_inode *pipe;     // 关联的管道inode
    bool is_reader;              // 是否为读端
    bool is_writer;              // 是否为写端
};

#endif /* !__KERN_FS_PIPE_H__ */
```

#### 2.2 扩展现有inode结构

```c
// 在 kern/fs/vfs/inode.h 中添加
enum inode_type {
    inode_type_device_info = 0x1234,
    inode_type_sfs_inode_info,
    inode_type_pipe_info,        // 新增管道类型
};

// 扩展inode联合体
union {
    struct device __device_info;
    struct sfs_inode __sfs_inode_info;
    struct pipe_inode __pipe_inode_info;  // 新增管道信息
} in_info;
```

#### 2.3 扩展文件操作结构

```c
// 在 kern/fs/file.h 中添加
struct file {
    enum {
        FD_NONE, FD_INIT, FD_OPENED, FD_CLOSED,
    } status;
    bool readable;
    bool writable;
    int fd;
    off_t pos;
    struct inode *node;
    int open_count;
    
    // 新增管道相关字段
    bool is_pipe;
    struct pipe_file *pipe_file;
};
```

### 3. 接口设计

#### 3.1 管道创建接口

```c
// 创建匿名管道
int sysfile_pipe(int *fd_store);

// 创建命名管道
int sysfile_mkfifo(const char *name, uint32_t open_flags);

// 底层管道创建函数
int pipe_create(struct pipe_inode **pipe_read, struct pipe_inode **pipe_write);

// 初始化管道inode
int pipe_inode_init(struct pipe_inode *pipe, bool readable, bool writable);
```

#### 3.2 管道操作接口

```c
// 管道读操作
ssize_t pipe_read(struct pipe_inode *pipe, char *buf, size_t count);

// 管道写操作
ssize_t pipe_write(struct pipe_inode *pipe, const char *buf, size_t count);

// 管道关闭
void pipe_close(struct pipe_inode *pipe, bool is_reader, bool is_writer);

// 检查管道状态
int pipe_stat(struct pipe_inode *pipe, struct stat *stat);
```

#### 3.3 同步互斥接口

```c
// 管道锁操作
void pipe_lock(struct pipe_inode *pipe);
void pipe_unlock(struct pipe_inode *pipe);

// 等待/唤醒操作
void pipe_wait_read(struct pipe_inode *pipe);
void pipe_wait_write(struct pipe_inode *pipe);
void pipe_wakeup_read(struct pipe_inode *pipe);
void pipe_wakeup_write(struct pipe_inode *pipe);
```

### 4. 同步互斥机制设计

#### 4.1 互斥机制
- 使用信号量(mutex)保护管道缓冲区的临界区
- 原子操作更新读写位置计数器

#### 4.2 同步机制
- **读者同步**: 当管道为空时，读者进入读等待队列
- **写者同步**: 当管道已满时，写者进入写等待队列
- **条件变量**: 使用等待队列实现读者-写者同步

#### 4.3 死锁避免
- 锁的获取顺序：管道锁 → 缓冲区操作 → 等待队列操作
- 超时机制：避免长时间等待
- 优雅关闭：进程退出时自动清理管道资源

---

## 扩展练习 Challenge2：基于"UNIX的软连接和硬连接机制"的设计方案

### 1. 需求分析

软链接（Symbolic Link）和硬链接（Hard Link）是UNIX文件系统中重要的文件共享机制：
- **软链接**: 类似快捷方式，包含目标文件路径，可跨文件系统
- **硬链接**: 直接引用inode，多个文件名指向同一inode，不可跨文件系统

### 2. 数据结构设计

#### 2.1 扩展SFS磁盘inode

```c
// 在 kern/fs/sfs/sfs.h 中扩展
#define SFS_TYPE_INVAL      0       // Should not appear on disk
#define SFS_TYPE_FILE       1
#define SFS_TYPE_DIR        2
#define SFS_TYPE_LINK       3       // 新增：链接文件类型
#define SFS_TYPE_SLINK      4       // 新增：软链接类型

// 扩展磁盘inode结构
struct sfs_disk_inode {
    uint32_t size;                  // size of the file (in bytes)
    uint16_t type;                  // one of SFS_TYPE_* above
    uint16_t nlinks;                // # of hard links to this inode
    uint32_t blocks;                // # of blocks
    uint32_t direct[SFS_NDIRECT];   // direct blocks
    uint32_t indirect;              // indirect blocks
    uint32_t db_indirect;           // doubly indirect blocks
    
    // 新增软链接相关字段
    uint32_t link_target_len;       // 软链接目标路径长度
    char link_target[256];          // 软链接目标路径（内联存储）
};
```

#### 2.2 链接管理结构

```c
// 新增文件: kern/fs/link.h
#ifndef __KERN_FS_LINK_H__
#define __KERN_FS_LINK_H__

#include <defs.h>
#include <atomic.h>

// 硬链接管理结构
struct hard_link {
    struct sfs_inode *inode;        // 指向的inode
    atomic_t ref_count;             // 硬链接引用计数
    struct list_entry link_entry;   // 链表节点
    char name[256];                 // 链接名称
};

// 软链接结构
struct sym_link {
    struct inode *target_inode;     // 目标inode（可选，解析时使用）
    char target_path[1024];         // 目标路径
    atomic_t follow_count;          // 跟随计数（用于检测循环）
    uint32_t target_fs_id;          // 目标文件系统ID（用于跨文件系统检查）
};

// 扩展inode结构
union {
    struct device __device_info;
    struct sfs_inode __sfs_inode_info;
    struct sym_link __sym_link_info;      // 新增软链接信息
} in_info;

// 链接操作表
struct link_inode_ops {
    // 通用inode操作
    int (*vop_open)(struct inode *node, uint32_t open_flags);
    int (*vop_close)(struct inode *node);
    int (*vop_read)(struct inode *node, struct iobuf *iob);
    int (*vop_write)(struct inode *node, struct iobuf *iob);
    
    // 链接特有操作
    int (*vop_readlink)(struct inode *node, char *path, size_t len);
    int (*vop_follow_link)(struct inode *node, struct inode **target_node);
    int (*vop_unlink)(struct inode *node, const char *name);
    int (*vop_link)(struct inode *node, const char *name, struct inode *target);
};

#endif /* !__KERN_FS_LINK_H__ */
```

#### 2.3 文件系统层链接管理

```c
// 新增文件: kern/fs/vfs/link.c
struct link_manager {
    struct hard_link *link_cache;       // 硬链接缓存
    atomic_t total_links;               // 总链接数
    wait_queue_t link_wait_queue;       // 链接操作等待队列
    semaphore_t link_mutex;             // 链接管理互斥锁
};

// 全局链接管理器
extern struct link_manager g_link_manager;
```

### 3. 接口设计

#### 3.1 硬链接接口

```c
// 创建硬链接
int sysfile_link(const char *oldpath, const char *newpath);

// 删除硬链接
int sysfile_unlink(const char *path);

// 查询链接信息
int sysfile_readlink(const char *path, char *buf, size_t bufsize);

// 检查是否为链接
bool is_symlink(struct inode *node);
bool is_hardlink(struct inode *node);

// 跟随链接
struct inode *follow_link(struct inode *link_node, bool *circular);
```

#### 3.2 软链接接口

```c
// 创建软链接
int sysfile_symlink(const char *target, const char *linkpath);

// 解析软链接
int symlink_resolve(struct inode *symlink_node, struct inode **target_node);

// 检查软链接有效性
bool symlink_is_valid(struct inode *symlink_node);

// 软链接统计信息
int symlink_stat(struct inode *node, struct stat *stat);
```

#### 3.3 链接管理接口

```c
// 链接管理器初始化
int link_manager_init(void);

// 清理链接
void link_cleanup(struct inode *node);

// 检查循环链接
bool detect_link_circular(struct inode *start_node);

// 跨文件系统链接检查
bool check_cross_filesystem(struct inode *node1, struct inode *node2);
```

### 4. 同步互斥机制设计

#### 4.1 硬链接同步机制
- **引用计数**: 使用原子操作管理inode的硬链接计数
- **互斥保护**: 使用信号量保护链接创建/删除的临界区
- **延迟删除**: 当引用计数为0时，延迟删除inode以处理并发访问

#### 4.2 软链接同步机制
- **跟随计数**: 使用原子操作防止无限递归跟随
- **路径解析锁**: 在解析软链接路径时使用读写锁
- **目标文件保护**: 确保目标文件在链接存在期间不会被删除

#### 4.3 死锁和循环检测
- **循环检测算法**: 使用深度优先搜索检测链接循环
- **超时机制**: 链接跟随操作设置超时避免死锁
- **优雅降级**: 检测到循环时返回错误而非无限循环

#### 4.4 竞争条件处理
- **原子操作**: 硬链接计数更新使用原子操作
- **锁的层次**: 全局锁 → 文件系统锁 → inode锁的获取顺序
- **条件等待**: 使用等待队列处理需要等待的操作

### 5. 实现考虑

#### 5.1 内存管理
- 使用内存池管理链接结构体
- 实现LRU缓存管理常用链接
- 及时释放不用的链接结构

#### 5.2 性能优化
- 软链接目标路径缓存
- 硬链接引用计数批量更新
- 链接遍历路径优化

#### 5.3 安全性
- 路径规范化防止目录遍历攻击
- 权限检查确保用户有权限创建链接
- 符号链接跟随时的安全检查

