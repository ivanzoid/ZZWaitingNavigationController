//
//  AppDelegate.m
//  TestPushDuringTransition
//
//  Created by Ivan Zezyulya on 03.10.14.
//  Copyright (c) 2014 Ivan Zezyulya. All rights reserved.
//

#import "AppDelegate.h"
#import "ZZWaitingNavigationController.h"
#import "GCDTimer.h"

@implementation AppDelegate {
    ZZWaitingNavigationController *navigationController;
    NSInteger depth;
}

- (UIViewController *) randomController
{
    UIViewController *controller = [UIViewController new];
    NSInteger red = rand() % 256;
    NSInteger green = rand() % 256;
    NSInteger blue = rand() % 256;
    controller.view.backgroundColor = [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:1];
    controller.title = [NSString stringWithFormat:@"%d-%d-%d", red, green, blue];
    return controller;
}

- (void) makeAction
{
    UIViewController *controller = [self randomController];

    NSInteger action = rand() % 5;

    if (action == 0) {
        depth++;
        NSLog(@" ");
        NSLog(@"pushing | depth -> %d", depth);
        NSLog(@" ");
        [navigationController pushViewController:controller animated:YES];
    } else if (action == 1) {
        if (depth > 1) {
            depth--;
            NSLog(@" ");
            NSLog(@"popping | depth -> %d", depth);
            NSLog(@" ");
            [navigationController popViewControllerAnimated:YES];
        }
    } else if (action == 2) {
        depth = 1;
        NSLog(@" ");
        NSLog(@"popping to root | depth -> %d", depth);
        NSLog(@" ");
        [navigationController popToRootViewControllerAnimated:YES];
    } else if (action == 3) {
        if (depth > 0) {
            NSInteger index = arc4random_uniform([navigationController.viewControllers count]);
            depth = index + 1;
            NSLog(@" ");
            NSLog(@"popping to index %d | depth -> %d", index, depth);
            NSLog(@" ");
            UIViewController *indexController = navigationController.viewControllers[index];
            [navigationController popToViewController:indexController animated:YES];
        }
    } else if (action == 4) {
        depth = 4;
        NSLog(@" ");
        NSLog(@"setViewControllers | depth -> %d", depth);
        NSLog(@" ");
        UIViewController *controller2 = [self randomController];
        UIViewController *controller3 = [self randomController];
        [navigationController setViewControllers:@[controller, controller2, controller3] animated:YES];
    }
}

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    srand(15);

    navigationController = [ZZWaitingNavigationController new];
    
    UIViewController *rootController = [UIViewController new];
    rootController.view.backgroundColor = [UIColor grayColor];
    rootController.title = @"Root";

    navigationController.viewControllers = @[rootController];

    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];

    depth = 1;

    __block NSInteger count = 0;
    __block GCDTimer *timer = [GCDTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^
    {
        NSLog(@"(action %d)", count);

        [self makeAction];

        count++;
        if (count == 50) {
            [timer invalidate];
        }
    }];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
