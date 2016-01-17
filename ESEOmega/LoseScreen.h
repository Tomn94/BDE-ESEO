//
//  LoseScreen.h
//  ESEOmega
//
//  Created by Tomn on 06/08/2015.
//  Copyright © 2015 Tomn. All rights reserved.
//

@import SpriteKit;
#import "GameScene.h"
#import "Data.h"

#define MAX_SCORES 10

@interface LoseScreen : SKScene

@property (nonatomic) NSUInteger score;
@property (strong, nonatomic) NSArray *scoresHUD;

- (void) sendScore:(NSUInteger)nvScore;

@end
