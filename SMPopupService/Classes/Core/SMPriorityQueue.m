//
//  SMPriorityQueue.m
//  PopupTest
//
//  Created by 董德富 on 2023/9/4.
//
//  优先级队列实现 - 基于二叉堆（可配置大小根堆）
//
//  算法说明：
//  1. 数据结构：使用数组实现的完全二叉树（二叉堆）
//  2. 堆性质：通过比较函数动态决定大小根堆性质
//  3. 时间复杂度：
//     - 插入操作：O(log n) - 上浮调整
//     - 删除操作：O(log n) - 下沉调整
//     - 查看顶部：O(1)
//  4. 空间复杂度：O(n)
//
//  堆的数组表示：
//  - 对于索引为i的节点：
//    - 父节点索引：(i-1)/2
//    - 左子节点索引：2*i+1
//    - 右子节点索引：2*i+2
//  - 根节点始终在索引0处
//
//  核心算法：
//  1. 上浮（Heapify Up）：插入元素后，从新元素开始向上调整，维护堆性质
//  2. 下沉（Heapify Down）：删除根元素后，将最后一个元素移到根部，然后向下调整
//

#import "SMPriorityQueue.h"

#define INITSIZE 10    // 堆的初始容量
#define INCSIZE  10    // 扩容时的增量大小

typedef void * element_t; // 元素类型，存储Objective-C对象的指针

/**
 * 优先级队列的核心数据结构
 * 使用数组实现完全二叉树（二叉堆）
 * 
 * 设计说明：
 * - 使用动态数组存储元素，支持自动扩容
 * - 通过索引关系实现完全二叉树的逻辑结构
 * - 支持任意数量的元素，内存使用效率高
 * 
 * 内存管理：
 * - base: 指向堆数组的指针，使用malloc/realloc分配
 * - capcity: 当前分配的内存容量，用于判断是否需要扩容
 * - size: 当前存储的元素数量，用于判断堆是否为空
 */
typedef struct {
//    bool (*comp)(element_t par, element_t chi); // 比较函数（已废弃，使用block）
    element_t *base;                            // 堆数组的基地址，存储所有元素
    int capcity;                                // 堆的当前容量（可存储的最大元素数）
    int size;                                   // 堆中当前存储的元素个数
} PriorityQueue;


@interface SMPriorityQueue ()
@property (strong, nonatomic) SMQueueCompare comp;  // 比较函数block，用于定义元素间的优先级关系
@property (assign, nonatomic) PriorityQueue *heap;  // 堆数据结构的指针，每个实例拥有独立的堆
@end

@implementation SMPriorityQueue

/**
 * 初始化优先级队列
 * 
 * @param cmp 比较函数block，用于定义元素间的优先级关系
 *            cmp(obj1, obj2) 返回 true 表示 obj1优先级 >= obj2优先级
 *            cmp(obj1, obj2) 返回 false 表示 obj1优先级 < obj2优先级
 * @return 初始化后的优先级队列实例
 */
- (instancetype)initWithCompareBlock:(SMQueueCompare)cmp {
    if (self = [super init]) {
        self.comp = cmp;                    // 保存比较函数
        self.heap = initHeapQueue();        // 初始化堆数据结构
    }
    return self;
}

/**
 * 析构函数，释放堆内存
 * 在ARC环境下，Objective-C对象会自动释放，只需要释放C内存
 */
- (void)dealloc {
    if (self.heap) {
        free(self.heap->base);  // 释放堆数组内存
        free(self.heap);        // 释放堆结构内存
        self.heap = NULL;       // 防止野指针
    }
    // 在ARC环境下不需要调用[super dealloc]
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"
#pragma clang diagnostic pop
}

/**
 * 获取队列中元素的数量
 * 时间复杂度：O(1)
 * 
 * @return 队列中元素的数量
 */
- (NSInteger)length {
    if (self.heap) {
        return self.heap->size;
    }
    return 0;
}

/**
 * 检查队列是否为空
 * 时间复杂度：O(1)
 * 
 * @return YES表示队列为空，NO表示队列不为空
 */
- (BOOL)isEmpty {
    return self.heap->size == 0 ? true : false;
}

/**
 * 获取队列顶部元素（最高优先级的元素）
 * 时间复杂度：O(1)
 * 
 * @return 队列顶部元素，如果队列为空则返回nil
 */
- (id)top {
    element_t rev = NULL;
    if (self.heap != NULL && self.heap->size > 0) {
        rev = self.heap->base[0];  // 堆顶元素始终在索引0处
    }
    return (__bridge id)rev;
}

/**
 * 向优先级队列中插入新元素
 * 时间复杂度：O(log n)
 * 
 * 算法步骤：
 * 1. 检查容量，必要时扩容
 * 2. 将新元素添加到堆的末尾
 * 3. 执行上浮操作（Heapify Up）维护堆性质
 * 
 * @param elem 要插入的元素
 */
- (void)push:(id)elem {
    element_t val = (__bridge void *)elem;
    
    // 步骤1：检查容量，如果堆已满则扩容
    if (self.heap->size >= self.heap->capcity) {
        void **tmp = (void **)realloc(self.heap->base, (self.heap->capcity + INCSIZE) * sizeof(void *));
        if (tmp) {
            self.heap->base = tmp;
            self.heap->capcity += INCSIZE;
        } else {
            return ; // 扩容失败，直接返回
        }
    }
    
    // 步骤2：将新元素添加到堆的末尾
    int new_node = self.heap->size;  // 新元素在数组中的位置（堆的末尾）
    int par_node = (new_node - 1) / 2; // 计算父节点位置：(i-1)/2
    self.heap->base[new_node] = val;
    
    // 步骤3：上浮操作（Heapify Up）- 从新元素开始向上调整
    // 目标：维护堆性质（根据比较函数决定大小根堆）
    // 
    // 比较函数语义：
    // comp(parent, child) 返回 true  -> parent优先级 >= child优先级，满足堆性质
    // comp(parent, child) 返回 false -> parent优先级 < child优先级，需要交换
    while (new_node != 0 &&
           self.comp((__bridge id)self.heap->base[par_node], (__bridge id)self.heap->base[new_node]) == false) {
        
        // 父节点 > 子节点，违反堆性质，需要交换
        swap(&self.heap->base[par_node], &self.heap->base[new_node]);
        
        // 继续向上检查：新元素上移到父节点位置
        new_node = par_node;
        par_node = (new_node - 1) / 2; // 计算新的父节点位置
    }
    
    // 更新堆的大小
    self.heap->size++;
}

/**
 * 从优先级队列中删除最高优先级的元素（堆顶元素）
 * 时间复杂度：O(log n)
 * 
 * 算法步骤：
 * 1. 检查堆是否为空
 * 2. 将堆顶元素与最后一个元素交换
 * 3. 删除最后一个元素（原来的堆顶）
 * 4. 执行下沉操作（Heapify Down）维护堆性质
 */
- (void)pop {
    bool l_cond = false;  // 当前节点与左子节点的堆性质检查结果
    bool r_cond = false;  // 当前节点与右子节点的堆性质检查结果
    int pos = 0;          // 当前处理的节点位置
    int l_pos = 0;        // 左子节点位置
    int r_pos = 0;        // 右子节点位置

    // 步骤1：检查堆是否为空
    if (self.heap != NULL && self.heap->size > 0) {
        
        // 步骤2：将堆顶元素与最后一个元素交换
        // 这样做的目的是为了删除堆顶元素，同时保持完全二叉树的结构
        swap(&self.heap->base[pos], &self.heap->base[self.heap->size - 1]);
        self.heap->size--; // 步骤3：删除最后一个元素（原来的堆顶）

        // 步骤4：下沉操作（Heapify Down）- 从新的堆顶开始向下调整
        // 目标：维护堆性质（根据比较函数决定大小根堆）
        while (pos < self.heap->size - 1) {
            // 计算左右子节点的位置
            l_pos = pos * 2 + 1;  // 左子节点：2*i+1
            r_pos = pos * 2 + 2;  // 右子节点：2*i+2

            // 检查当前节点与子节点的堆性质
            // 比较函数语义：
            // comp(parent, child) 返回 true  -> parent优先级 >= child优先级，满足堆性质
            // comp(parent, child) 返回 false -> parent优先级 < child优先级，需要交换
            // 当子节点不存在时，条件设为 false，表示不需要交换
            l_cond = (l_pos < self.heap->size) ? 
                     self.comp((__bridge id)self.heap->base[pos], (__bridge id)self.heap->base[l_pos]) : false;
            r_cond = (r_pos < self.heap->size) ? 
                     self.comp((__bridge id)self.heap->base[pos], (__bridge id)self.heap->base[r_pos]) : false;

            // 根据堆性质检查结果决定下一步操作
            if (l_cond == true && r_cond == true) {
                // 情况1：当前节点与两个子节点都满足堆性质
                // 堆调整完成，退出循环
                break;
                
            } else if (l_cond == false && r_cond == true) {
                // 情况2：当前节点与左子节点不满足堆性质，与左子节点交换
                swap(&self.heap->base[pos], &self.heap->base[l_pos]);
                pos = l_pos; // 继续检查左子树
                
            } else if (l_cond == true && r_cond == false) {
                // 情况3：当前节点与右子节点不满足堆性质，与右子节点交换
                swap(&self.heap->base[pos], &self.heap->base[r_pos]);
                pos = r_pos; // 继续检查右子树
                
            } else if (l_cond == false && r_cond == false) {
                // 情况4：当前节点与两个子节点都不满足堆性质
                // 选择较小的子节点进行交换，确保交换后仍满足堆性质
                if (self.comp((__bridge id)self.heap->base[l_pos], (__bridge id)self.heap->base[r_pos]) == true) {
                    // 左子节点较小，与左子节点交换
                    swap(&self.heap->base[pos], &self.heap->base[l_pos]);
                    pos = l_pos;
                } else {
                    // 右子节点较小，与右子节点交换
                    swap(&self.heap->base[pos], &self.heap->base[r_pos]);
                    pos = r_pos;
                }
            }
        }
    }
}

/**
 * 清空队列，重置为初始状态
 * 时间复杂度：O(1)
 * 
 * 注意：此方法会清空所有元素，但不会释放堆内存，只是重置大小
 */
- (void)clear {
    // 在ARC环境下，不需要手动释放对象引用
    // 只需要重置堆的大小和容量
    void **tmp = (void **)realloc(self.heap->base, INITSIZE * sizeof(void *));
    if (tmp) {
        self.heap->base = tmp;      // 更新堆数组指针
        self.heap->capcity = INITSIZE;  // 重置容量为初始大小
        self.heap->size = 0;        // 重置元素数量为0
    } else {
        self.heap->size = 0;        // 即使realloc失败，也要重置大小
    }
}

/**
 * 批量插入元素
 * 时间复杂度：O(n log n)，其中n为数组元素数量
 * 
 * @param array 要插入的元素数组
 */
- (void)pushWithArray:(NSArray *)array {
    if (array) {
        for (id obj in array) {
            [self push:obj];  // 逐个插入，每次插入都会维护堆性质
        }
    }
}

/**
 * 获取队列中所有元素（按优先级排序）
 * 时间复杂度：O(n log n)
 * 
 * 注意：此方法会清空原队列，返回的元素按优先级从高到低排列
 * 
 * @return 按优先级排序的元素数组
 */
- (NSArray *)allObjects {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    // 直接遍历队列而不修改原队列，避免破坏堆结构
    if (self.heap != NULL) {
        for (int i = 0; i < self.heap->size; i++) {
            id obj = (__bridge id)self.heap->base[i];
            [array addObject:obj];
        }
    }
    return array;
}

/**
 * 初始化堆数据结构
 * 分配堆结构体和堆数组的内存空间
 * 
 * @return 初始化成功的堆指针，失败时返回NULL
 */
PriorityQueue *initHeapQueue(void) {
    PriorityQueue *pq = NULL;
    
    // 步骤1：分配堆结构体内存
    pq = (PriorityQueue *)malloc(sizeof(PriorityQueue));
    if (pq != NULL) {
        // 步骤2：分配堆数组内存
        pq->base = (element_t *)malloc(INITSIZE * sizeof(element_t));
        if (pq->base != NULL) {
            // 步骤3：初始化堆属性
            pq->capcity = INITSIZE;  // 设置初始容量
            pq->size = 0;            // 初始元素数量为0
        } else {
            // 堆数组分配失败，释放堆结构体内存
            free(pq);
            pq = NULL;
        }
    }
    return pq;
}


/**
 * 交换两个元素的值
 * 用于堆调整过程中的元素交换
 * 
 * @param a 第一个元素的指针
 * @param b 第二个元素的指针
 */
static void swap(element_t *a, element_t *b) {
    element_t temp = *a;  // 保存第一个元素的值
    *a = *b;              // 将第二个元素的值赋给第一个元素
    *b = temp;            // 将保存的值赋给第二个元素
}

@end
