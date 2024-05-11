//
//  TestViewController.m
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

#import "TestViewController.h"
#import "SMPopupService-Swift.h"
#import "SMPopupService_Example-Swift.h"

@interface TestViewController ()

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    SMPopupConfig *config = [[SMPopupConfig alloc] initWithSceneStyle:SMPopupSceneSheet];
    config.identifier = @"";
    config.priority = 1;
    config.level = SMPopupLevelDefault;
    config.isClickCoverDismiss = YES;
    config.containerView = nil;
    config.showAnimationStyle = SMPopupShowAnimationStyleBubble;
    config.rectCorners = UIRectCornerTopLeft;
    config.backgroundColor = UIColor.blackColor;
    
    TopBarPopView *pop = [[TopBarPopView alloc] init];
    [[SMPopupService standard] showWithConfig:config view:pop];
    
    [[SMPopupService standard] pause];
    [[SMPopupService standard] continue];
    
//    SMPopupService dismis
    
//    SMPopupService upda
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
