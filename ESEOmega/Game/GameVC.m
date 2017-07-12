//
//  GameVC.m
//  ESEOmega
//
//  Created by Thomas Naudet on 05/08/2015.
//  Copyright © 2015 Thomas Naudet

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
        
        NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"bellum" ofType:@"mp3"]];
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        audioPlayer.numberOfLoops = -1;
        [audioPlayer prepareToPlay];
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
    [audioPlayer play];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [audioPlayer stop];
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

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

@end
