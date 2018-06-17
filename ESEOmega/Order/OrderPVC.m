//
//  OrderPVC.m
//  ESEOmega
//
//  Created by Thomas NAUDET on 01/08/2015.
//  Copyright © 2015 Thomas NAUDET

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see http://www.gnu.org/licenses/
//

#import "OrderPVC.h"
#import "BDE_ESEO-Swift.h"

@implementation OrderPVC

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    messageQuitterVu = NO;
    self.delegate = self;
    self.dataSource = self;
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Carte"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];
    
    UIViewController *vc1 = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderMenu"];
    UIViewController *vc2 = [self.storyboard instantiateViewControllerWithIdentifier:@"OrderPanier"];
    viewControllers = @[vc1, vc2];
    
    [self setViewControllers:@[vc1]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO completion:nil];
    
    seg = [[UISegmentedControl alloc] initWithItems:@[@"Carte",
                                                      [NSString stringWithFormat:@"Panier (%d)", (int)[[[Data sharedData] cafetPanier] count]]]];
    seg.frame = CGRectMake(0, 0, 300, (iPAD || (!iPAD && [UIScreen mainScreen].bounds.size.height >= 736)) ? 29 : 21);
    seg.selectedSegmentIndex = 0;
    [seg addTarget:self action:@selector(tabSelected) forControlEvents:UIControlEventValueChanged];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:seg];
    toolbar = [UIToolbar new];
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    toolbar.delegate = self;
    [toolbar setItems:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                        barItem,
                        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];
    [self.view addSubview:toolbar];
    [self rotateToolbar];
    
    [[Data sharedData] setCafetDebut:[[NSDate date] timeIntervalSinceReferenceDate]];
    [NSTimer scheduledTimerWithTimeInterval:MAX_ORDER_TIME target:self selector:@selector(timeout) userInfo:nil repeats:NO];
    NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
    [ctr addObserver:self selector:@selector(rotateToolbar) name:UIDeviceOrientationDidChangeNotification object:nil];
    [ctr addObserver:self selector:@selector(updSegTitle) name:@"updPanier" object:nil];
    [ctr addObserver:self selector:@selector(fermerForcer) name:@"cmdValide" object:nil];
    [ctr addObserver:self selector:@selector(fermerForcerLydia:) name:@"cmdValideLydia" object:nil];
    [ctr addObserver:self selector:@selector(timeout) name:@"retourAppCafetFin" object:nil];
    
    /* Handoff */
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.eseomega.ESEOmega.order"];
    activity.title = @"Commander à la cafet";
    activity.webpageURL = [NSURL URLWithString:URL_ACT_ORDR];
    activity.eligibleForSearch = YES;
    activity.eligibleForHandoff = YES;
    activity.eligibleForPublicIndexing = YES;
    self.userActivity = activity;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.userActivity becomeCurrent];
}

- (void) timeout
{
    if (messageQuitterVu)
        return;
    messageQuitterVu = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Votre panier a expiré"
                                                                   message:@"Pour des raisons de sécurité, il n'est possible de passer commande que pendant 10 minutes sans valider.\nMerci de bien vouloir recommencer. 😇"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        [self fermerForcer];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) fermer:(id)sender
{
    if ([[[Data sharedData] cafetPanier] count])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Vous avez des éléments dans votre panier"
                                                                       message:@"Si vous annulez, vous perdrez votre commande en cours."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Supprimer ma commande"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
            [self fermerForcer];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Continuer à commander"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
        [self fermerForcer];
}

- (void) fermerForcer
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[Data sharedData] cafetPanierVider];
        [[Data sharedData] setCafetToken:@""];
        [[Data sharedData] setCafetDebut:0];
        
        if (@available(iOS 10.3, *)) {
            [SKStoreReviewController requestReview];
        }
    }];
}

- (void) fermerForcerLydia:(NSNotification *)n
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[Data sharedData] cafetPanierVider];
        [[Data sharedData] setCafetToken:@""];
        [[Data sharedData] setCafetDebut:0];
        
        [Lydia startRequestObjCBridgeWithOrder:[n.userInfo[@"idcmd"] intValue]
                                          type:n.userInfo[@"catOrder"]];
    }];
}

- (void) tabSelected
{
    NSUInteger index = seg.selectedSegmentIndex;
    [self setViewControllers:@[viewControllers[index]]
                   direction:(index) ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse
                    animated:YES completion:nil];
    if (index == 1 && [[[Data sharedData] cafetPanier] count] && ![[Data sharedData] cafetCmdEnCours])
        [self.navigationItem setLeftBarButtonItem:[viewControllers[1] editButtonItem] animated:YES];
    else
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

- (void) updSegTitle
{
    [seg setTitle:[NSString stringWithFormat:@"Panier (%d)", (int)[[[Data sharedData] cafetPanier] count]] forSegmentAtIndex:1];
    if (seg.selectedSegmentIndex == 1 && [[[Data sharedData] cafetPanier] count]/* && ![[Data sharedData] cafetCmdEnCours]*/)
        [self.navigationItem setLeftBarButtonItem:[viewControllers[1] editButtonItem] animated:YES];
    else
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
}

- (void) rotateToolbar
{
    CGFloat dec = self.navigationController.navigationBar.frame.size.height + ((iPAD) ? 0 : [UIApplication sharedApplication].statusBarFrame.size.height);
    toolbar.frame = CGRectMake(0, dec, self.view.frame.size.width, 44);
}

- (UIViewController *) viewControllerAtIndex:(NSInteger)i
{
    if (i < 0 || i >= [viewControllers count])
        return nil;
    return viewControllers[i];
}

# pragma mark - Page View Data Source

- (UIViewController *) pageViewController:(UIPageViewController *)pageViewController
       viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger index = [viewControllers indexOfObject:viewController];
    --index;
    return [self viewControllerAtIndex:(index)];
}

- (UIViewController *) pageViewController:(UIPageViewController *)pageViewController
        viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger index = [viewControllers indexOfObject:viewController];
    ++index;
    return [self viewControllerAtIndex:(index)];
}

- (void) pageViewController:(UIPageViewController *)pageViewController
         didFinishAnimating:(BOOL)finished
    previousViewControllers:(NSArray *)previousViewControllers
        transitionCompleted:(BOOL)completed
{
    if (finished && completed)
    {
        seg.selectedSegmentIndex = [viewControllers indexOfObject:self.viewControllers[0]];
        if (seg.selectedSegmentIndex == 1 && [[[Data sharedData] cafetPanier] count] && ![[Data sharedData] cafetCmdEnCours])
            [self.navigationItem setLeftBarButtonItem:[viewControllers[1] editButtonItem] animated:YES];
        else
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    }
}

#pragma mark - Tool Bar Delegate

- (UIBarPosition) positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}

@end
