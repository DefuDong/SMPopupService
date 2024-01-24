//
//  SMPriorityQueue.m
//  PopupTest
//
//  Created by 董德富 on 2023/9/4.
//

#import "SMPriorityQueue.h"

#define INITSIZE 10    // 初始大小
#define INCSIZE  10    // 增量大小

typedef void * element_t; // 元素类型

typedef struct {
//    bool (*comp)(element_t par, element_t chi); // 比较函数
    element_t *base;                            // 元素存储地址
    int capcity;                                // 容量
    int size;                                   // 存储元素个数
} PriorityQueue;


@interface SMPriorityQueue ()
@property (strong, nonatomic) SMQueueCompare comp;
@end

@implementation SMPriorityQueue

PriorityQueue *heap;

- (instancetype)initWithCompareBlock:(SMQueueCompare)cmp {
    if (self = [super init]) {
        self.comp = cmp;
        initHeapQueue();
    }
    return self;
}

- (void)dealloc {
    destoryHeapQueue();
}

- (NSInteger)length {
    if (heap) {
        return heap->size;
    }
    return 0;
}

- (BOOL)isEmpty {
    return heap->size == 0 ? true : false;
}

- (id)top {
    element_t rev = NULL;
    if (heap != NULL && heap ->size > 0) {
        rev = heap->base[0];
    }
    return (__bridge id)rev;
}

- (void)push:(id)elem {
    element_t val = (__bridge_retained void *)elem;
    
    // 满了，扩容
    if (heap->size >= heap->capcity) {
        void **tmp = (void **)realloc(heap->base, (heap->capcity + INCSIZE) * sizeof(void *));
        if (tmp) {
            heap->base = tmp;
            heap->capcity += INCSIZE;
        } else {
            return ;
        }
    }
    
    int new_node = 0; // 新元素所在节点位置
    int par_node = 0; // 新元素父节点所在位置

    new_node = heap->size;
    par_node = (new_node - 1) / 2; // 计算父节点所在位置，整除为向下取整
    heap->base[new_node] = val;
    // 父节点存在，且父节点与子节点的值不满足要求时，交换它们的值
    while (new_node != 0 &&
           self.comp((__bridge id)heap->base[par_node], (__bridge id)heap->base[new_node]) == false) {
        swap(&heap->base[par_node], &heap->base[new_node]);
        // 计算新一轮的节点位置
        new_node = par_node;
        par_node = (new_node - 1) / 2;
    }
    heap->size++;
}

- (void)pop {
    bool l_cond = false;
    bool r_cond = false;
    int pos = 0;
    int l_pos = 0;
    int r_pos = 0;

    // 判断是否有元素能够删除
    if (heap != NULL && heap->size > 0) {
        swap(&heap->base[pos], &heap->base[heap->size - 1]);
        heap->size--; // 删除元素

        while (pos < heap->size - 1) {
            l_pos = pos * 2 + 1;
            r_pos = pos * 2 + 2;

            // 子节点存在时判断数值是否满足要求
            l_cond = (l_pos < heap->size) ? self.comp((__bridge id)heap->base[pos], (__bridge id)heap->base[l_pos]) : true;
            r_cond = (r_pos < heap->size) ? self.comp((__bridge id)heap->base[pos], (__bridge id)heap->base[r_pos]) : true;

            if (l_cond == true && r_cond == true) {
                break; // 两个子节点均满足条件，退出循环
            } else if (l_cond == false && r_cond == true) {
                swap(&heap->base[pos], &heap->base[l_pos]); // 只有左子节点不满足条件，与其交换数值
                pos = l_pos;
            } else if (l_cond == true && r_cond == false) {
                swap(&heap->base[pos], &heap->base[r_pos]); // 只有右子节点不满足条件，与其交换数值
                pos = r_pos;
            } else {
                // 两个子节点均不满足条件，挑选一个交换后数值仍满足要求的节点进行交换
                if (self.comp((__bridge id)heap->base[l_pos], (__bridge id)heap->base[r_pos]) == true) {
                    swap(&heap->base[pos], &heap->base[l_pos]);
                    pos = l_pos;
                } else {
                    swap(&heap->base[pos], &heap->base[r_pos]);
                    pos = r_pos;
                }
            }
        }
    }
}

- (void)clear {
    for (int i = 0; i < heap->size; i++) {
        CFRelease(heap->base[i]);
    }
    void **tmp = (void **)realloc(heap->base, INITSIZE * sizeof(void *));
    if (tmp) {
        heap->base = tmp;
        heap->capcity = INITSIZE;
        heap->size = 0;
    } else {
        heap->size = 0;
    }
}

- (void)pushWithArray:(NSArray *)array {
    if (array) {
        for (id obj in array) {
            [self push:obj];
        }
    }
}

- (NSArray *)allObjects {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    while (![self isEmpty]) {
        NSNumber *b = [self top];
        [self pop];
        [array addObject:b];
    }
    return array;
}

//void initHeapQueue(bool (*comp)(element_t par, element_t chi)) {
void initHeapQueue(void) {
    PriorityQueue *pq = NULL;
    pq = (PriorityQueue *)malloc(sizeof(PriorityQueue)); // 申请和0初始化内存空间
    if (pq != NULL) {
        // 申请内存空间用于存储元素
        pq->base = (element_t *)malloc(INITSIZE * sizeof(element_t));
        if (pq->base != NULL) {
            pq->capcity = INCSIZE;
//            pq->comp = comp;
            pq->size = 0;
        } else {
            // 申请失败，释放之前申请的内存
            free(pq);
            pq = NULL;
        }
    }
    heap = pq;
}

void destoryHeapQueue(void) {
    if (heap) {
        for (int i = 0; i < heap->size; i++) {
            CFRelease(heap->base[i]);
        }
        free(heap);
    }
}

static void swap(element_t *a, element_t *b) {
    element_t temp = *a;
    *a = *b;
    *b = temp;
}

@end
