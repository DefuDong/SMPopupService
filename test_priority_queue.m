#import <Foundation/Foundation.h>
#import "SMPopupService/SMPopupService-Swift.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"开始测试修复后的优先级队列...");
        
        // 创建优先级队列，小优先级在前
        SMPriorityQueue *queue = [[SMPriorityQueue alloc] initWithCompareBlock:^BOOL(NSNumber *obj1, NSNumber *obj2) {
            return [obj1 intValue] <= [obj2 intValue];
        }];
        
        // 测试数据
        NSArray *testData = @[@5, @2, @8, @1, @9, @3, @7, @4, @6];
        
        NSLog(@"原始数据: %@", testData);
        
        // 将所有数据入队
        for (NSNumber *num in testData) {
            [queue push:num];
            NSLog(@"入队: %@, 当前队列长度: %ld", num, (long)[queue length]);
        }
        
        NSLog(@"\n开始出队测试:");
        
        // 依次出队，应该按照优先级从小到大的顺序
        NSMutableArray *result = [NSMutableArray array];
        while (![queue isEmpty]) {
            NSNumber *top = [queue top];
            [queue pop];
            [result addObject:top];
            NSLog(@"出队: %@, 剩余长度: %ld", top, (long)[queue length]);
        }
        
        NSLog(@"\n最终结果: %@", result);
        
        // 验证结果是否正确（应该是升序排列）
        BOOL isCorrect = YES;
        for (int i = 1; i < result.count; i++) {
            if ([result[i-1] intValue] > [result[i] intValue]) {
                isCorrect = NO;
                break;
            }
        }
        
        if (isCorrect) {
            NSLog(@"✅ 测试通过！优先级队列工作正常，数据按升序排列");
        } else {
            NSLog(@"❌ 测试失败！数据排列不正确");
        }
        
        // 测试多个实例
        NSLog(@"\n测试多个实例...");
        SMPriorityQueue *queue1 = [[SMPriorityQueue alloc] initWithCompareBlock:^BOOL(NSNumber *obj1, NSNumber *obj2) {
            return [obj1 intValue] <= [obj2 intValue];
        }];
        SMPriorityQueue *queue2 = [[SMPriorityQueue alloc] initWithCompareBlock:^BOOL(NSNumber *obj1, NSNumber *obj2) {
            return [obj1 intValue] <= [obj2 intValue];
        }];
        
        [queue1 push:@10];
        [queue2 push:@20];
        
        NSLog(@"队列1顶部: %@", [queue1 top]);
        NSLog(@"队列2顶部: %@", [queue2 top]);
        
        if ([[queue1 top] intValue] == 10 && [[queue2 top] intValue] == 20) {
            NSLog(@"✅ 多实例测试通过！每个实例独立工作");
        } else {
            NSLog(@"❌ 多实例测试失败！");
        }
    }
    return 0;
}
