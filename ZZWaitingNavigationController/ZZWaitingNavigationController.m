//
//  NavigationController.m
//

#import "ZZWaitingNavigationController.h"
#import "ZZWaitingNavigationAction.h"
#import "GCDTimer.h"

#define ZZ_WAITING_NAVIGATION_CONTROLLER_DEBUG_LOGGING 1

#ifdef ZZ_WAITING_NAVIGATION_CONTROLLER_DEBUG_LOGGING
#   define ZZWaitDbgLog(...) NSLog(__VA_ARGS__)
#else
#   define ZZWaitDbgLog(...)
#endif

static CGFloat const kDefaultTimout = 0.35;
static CGFloat const kPresentOrDismissTimout = 0.55;

@interface ZZWaitingNavigationController () <UINavigationControllerDelegate>
@end

@implementation ZZWaitingNavigationController {
    GCDTimer *transitionResetTimer;
    NSMutableArray *pendingNavigationActions;
    BOOL transitionInProgress;
    NSMutableArray *virtualViewControllers;
    ZZWaitingNavigationAction *currentAction;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self commonInitNavigationController];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)coder
{
    if ((self = [super initWithCoder:coder])) {
        [self commonInitNavigationController];
    }
    return self;
}

- (void) commonInitNavigationController
{
    pendingNavigationActions = [NSMutableArray new];
    virtualViewControllers = [NSMutableArray new];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.delegate = self;
}

- (void) setTimerWithTimeOut:(NSTimeInterval)timeout
{
    transitionResetTimer = [GCDTimer scheduledTimerWithTimeInterval:timeout repeats:NO block:^{
        ZZWaitDbgLog(@"*** Timer did expire ***");
        transitionResetTimer = nil;
        if (!transitionInProgress) {
            [self performNextPendingNavigationActionIfNeeded];
        }
    }];
}

- (void) unsetTimer
{
    [transitionResetTimer invalidate];
    transitionResetTimer = nil;
}

- (void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    ZZWaitDbgLog(@"--- willShowViewController \"%@\" (%p)", viewController.title, viewController);

    transitionInProgress = YES;

    [self unsetTimer];
    if (currentAction.actionType == NavigationActionTypePresent || currentAction.actionType == NavigationActionTypeDismiss) {
        [self setTimerWithTimeOut:kPresentOrDismissTimout];
    } else {
        [self setTimerWithTimeOut:kDefaultTimout];
    }
}

- (void) navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    ZZWaitDbgLog(@"--- didShowViewController \"%@\" (%p)", viewController.title, viewController);

    transitionInProgress = NO;

    [self performNextPendingNavigationActionIfNeeded];
}

- (id) performAction:(ZZWaitingNavigationAction *)action
{
    id result = nil;

    currentAction = action;

    ZZWaitDbgLog(@" ");
    ZZWaitDbgLog(@"!!! performing %@", action);
    
    NSMutableArray *realControllersDescriptions = [NSMutableArray new];
    for (UIViewController *controller in [super viewControllers]) {
        [realControllersDescriptions addObject:[NSString stringWithFormat:@"\"%@\" %p", controller.title, controller]];
    }
    
    NSMutableArray *virtualControllersDescriptions = [NSMutableArray new];
    for (UIViewController *controller in self.viewControllers) {
        [virtualControllersDescriptions addObject:[NSString stringWithFormat:@"\"%@\" %p", controller.title, controller]];
    }

    ZZWaitDbgLog(@"current real controllers: [%@]", [realControllersDescriptions componentsJoinedByString:@", "]);
    ZZWaitDbgLog(@"current virtual controllers: [%@]", [virtualControllersDescriptions componentsJoinedByString:@", "]);
    ZZWaitDbgLog(@" ");

    if (action.actionType == NavigationActionTypePush)
    {
        [super pushViewController:action.controller animated:action.animated];
    }
    else if (action.actionType == NavigationActionTypePop)
    {
        result = [super popViewControllerAnimated:action.animated];
    }
    else if (action.actionType == NavigationActionTypePopToRoot)
    {
        result = [super popToRootViewControllerAnimated:action.animated];
    }
    else if (action.actionType == NavigationActionTypePopToController)
    {
        [super popToViewController:action.controller animated:action.animated];
    }
    else if (action.actionType == NavigationActionTypeSetControllers)
    {
        NSMutableArray *ptrs = [NSMutableArray new];
        for (UIViewController *controller in action.controllers) {
            [ptrs addObject:[NSString stringWithFormat:@"\"%@\" %p", controller.title, controller]];
        }

        [super setViewControllers:action.controllers animated:action.animated];
    }
    else if (action.actionType == NavigationActionTypePresent)
    {
        [super presentViewController:action.controller animated:action.animated completion:action.completion];
    }
    else if (action.actionType == NavigationActionTypeDismiss)
    {
        [super dismissViewControllerAnimated:action.animated completion:action.completion];
    }
    else {
        NSAssert(NO, nil);
    }

    if (action.animated) {
        if (action.actionType == NavigationActionTypePresent || action.actionType == NavigationActionTypeDismiss) {
            [self setTimerWithTimeOut:kPresentOrDismissTimout];
        } else {
            [self setTimerWithTimeOut:kDefaultTimout];
        }
    }

    return result;
}

- (void) doPerformNextPendingNavigationAction
{
    ZZWaitingNavigationAction *action = pendingNavigationActions[0];
    [pendingNavigationActions removeObjectAtIndex:0];
    [self performAction:action];
    [self printStack];
}

- (void) printStack
{
    ZZWaitDbgLog(@"=== stack:");
    for (ZZWaitingNavigationAction *action in pendingNavigationActions) {
        ZZWaitDbgLog(@"        %@", action);
    }
}

- (id) stackAction:(ZZWaitingNavigationAction *)action
{
    [pendingNavigationActions addObject:action];

    ZZWaitDbgLog(@">>> saving %@", action);
    [self printStack];

    if (action.actionType == NavigationActionTypePopToRoot)
    {
        return @[];
    }
    else if (action.actionType == NavigationActionTypePopToController)
    {
        return @[];
    }
    else {
        return nil;
    }
}

- (id) performOrStackAction:(ZZWaitingNavigationAction *)action
{
    if (action.actionType == NavigationActionTypePop)
    {
        if ([virtualViewControllers count] == 0) {
            NSAssert(NO, nil);
        } else {
            [virtualViewControllers removeLastObject];
        }
    }
    else if (action.actionType == NavigationActionTypePopToRoot)
    {
        if ([virtualViewControllers count] == 0) {
            NSAssert(NO, nil);
        } else {
            [virtualViewControllers removeObjectsInRange:NSMakeRange(1, [virtualViewControllers count] - 1)];
        }
    }
    else if (action.actionType == NavigationActionTypePopToController)
    {
        NSUInteger index = [virtualViewControllers indexOfObject:action.controller];
        if (index == NSNotFound) {
            NSAssert(NO, nil);
        } else {
            [virtualViewControllers removeObjectsInRange:NSMakeRange(index + 1, [virtualViewControllers count] - (index + 1))];
        }
    }
    else if (action.actionType == NavigationActionTypePush)
    {
        [virtualViewControllers addObject:action.controller];
    }
    else if (action.actionType == NavigationActionTypeSetControllers)
    {
        [virtualViewControllers removeAllObjects];
        [virtualViewControllers addObjectsFromArray:action.controllers];
    }
    
    if ([virtualViewControllers count] == 0) {
        NSAssert(NO, nil);
    }
    
    if (transitionInProgress || transitionResetTimer || [pendingNavigationActions count]) {
        return [self stackAction:action];
    } else {
        return [self performAction:action];
    }
}

- (void) performNextPendingNavigationActionIfNeeded
{
    if (!transitionInProgress && !transitionResetTimer)
    {
        currentAction = nil;
        if ([pendingNavigationActions count]) {
            [self doPerformNextPendingNavigationAction];
        }
    }
}

- (void) pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (viewController == nil) {
        NSParameterAssert(viewController);
        return;
    }

    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypePush;
    action.controller = viewController;
    action.animated = animated;

    [self performOrStackAction:action];
}

- (UIViewController *) popViewControllerAnimated:(BOOL)animated
{
    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypePop;
    action.animated = animated;
    
    return [self performOrStackAction:action];
}

- (NSArray *) popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypePopToController;
    action.controller = viewController;
    action.animated = animated;

    return [self performOrStackAction:action];
}

- (NSArray *) popToRootViewControllerAnimated:(BOOL)animated
{
    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypePopToRoot;
    action.animated = animated;
    
    return [self performOrStackAction:action];
}

- (void) setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypeSetControllers;
    action.controllers = viewControllers;
    action.animated = animated;

    [self performOrStackAction:action];
}

- (void) presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypePresent;
    action.controller = viewControllerToPresent;
    action.animated = animated;
    action.completion = completion;

    [self performOrStackAction:action];
}

- (void) dismissViewControllerAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    ZZWaitingNavigationAction *action = [ZZWaitingNavigationAction new];
    action.actionType = NavigationActionTypeDismiss;
    action.animated = animated;
    action.completion = completion;

    [self performOrStackAction:action];
}

- (NSArray *) viewControllers
{
    return virtualViewControllers;
}

@end
