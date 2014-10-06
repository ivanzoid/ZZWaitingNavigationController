//
//  ZZWaitingNavigationAction.m
//  TestPushDuringTransition
//
//  Created by Ivan Zezyulya on 07.10.14.
//  Copyright (c) 2014 Ivan Zezyulya. All rights reserved.
//

#import "ZZWaitingNavigationAction.h"

@implementation ZZWaitingNavigationAction

- (NSString *) description
{
    if (self.actionType == NavigationActionTypePop)
    {
        return @"popViewController";
    }
    else if (self.actionType == NavigationActionTypePopToRoot)
    {
        return @"popToRootViewController";
    }
    else if (self.actionType == NavigationActionTypePopToController)
    {
        return [NSString stringWithFormat:@"popToViewController \"%@\" %p", self.controller.title, self.controller];
    }
    else if (self.actionType == NavigationActionTypePush)
    {
        return [NSString stringWithFormat:@"pushViewController \"%@\" %p", self.controller.title, self.controller];
    }
    else if (self.actionType == NavigationActionTypeSetControllers)
    {
        NSMutableArray *descriptions = [NSMutableArray new];
        for (UIViewController *controller in self.controllers) {
            [descriptions addObject:[NSString stringWithFormat:@"\"%@\" %p", controller.title, controller]];
        }
        
        return [NSString stringWithFormat:@"setViewControllers %@", [descriptions componentsJoinedByString:@", "]];
    }
    else {
        return @"";
    }
}

@end
