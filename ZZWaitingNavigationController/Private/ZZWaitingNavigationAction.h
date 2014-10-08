//
//  ZZWaitingNavigationAction.h
//  TestPushDuringTransition
//
//  Created by Ivan Zezyulya on 07.10.14.
//  Copyright (c) 2014 Ivan Zezyulya. All rights reserved.
//

typedef NS_ENUM(NSInteger, NavigationActionType) {
    NavigationActionTypePush,
    NavigationActionTypePop,
    NavigationActionTypePopToController,
    NavigationActionTypePopToRoot,
    NavigationActionTypeSetControllers,
    NavigationActionTypePresent,
    NavigationActionTypeDismiss
};

@interface ZZWaitingNavigationAction : NSObject
@property (nonatomic) NavigationActionType actionType;
@property (nonatomic) BOOL animated;
@property (nonatomic) UIViewController *controller;
@property (nonatomic) NSArray *controllers; // for actionType = NavigationActionTypeSetControllers
@property (nonatomic, copy) dispatch_block_t completion; // for actionType = NavigationActionTypePresent or NavigationActionTypeDismiss
@end
