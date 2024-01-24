//
//  SMPriorityQueue.h
//  PopupTest
//
//  Created by 董德富 on 2023/9/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^SMQueueCompare)(id obj1, id obj2);


@interface SMPriorityQueue : NSObject

// 必须用这个函数初始化对象
- (instancetype)initWithCompareBlock:(SMQueueCompare)cmp NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (void)push:(id)elem;                      // 入队
- (void)pop;                                // 出队
- (void)pushWithArray:(NSArray *)array;     // 所有数组元素入队
- (id)top;                                  // 返回队头元素，没有返回 nil
- (BOOL)isEmpty;                            // 判空
- (void)clear;                              // 清空队列
- (NSArray *)allObjects;
- (NSInteger)length;


@end

NS_ASSUME_NONNULL_END
