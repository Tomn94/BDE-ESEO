//
//  GameVC.m
//  ESEOmega
//
//  Created by Tomn on 05/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

#import "GameVC.h"

@implementation GameVC

- (instancetype) init
{
    if (self = [super init]) {
        gameView = [SKView new];
        gameView.showsFPS = NO;
        gameView.showsNodeCount = NO;
        gameView.ignoresSiblingOrder = YES;
        [self setView:gameView];
    }
    return self;
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    SKView *skView = (SKView *)self.view;
    if (!skView.scene) {
        SKScene *scene = [GameScene sceneWithSize:[UIScreen mainScreen].bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        [gameView presentScene:scene];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fermer) name:@"gameover" object:nil];
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) fermer
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations
//- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
